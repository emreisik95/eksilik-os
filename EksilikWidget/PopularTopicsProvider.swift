import Foundation
import SwiftUI
import WidgetKit

struct TopicEntry: TimelineEntry {
    let date: Date
    let topics: [WidgetFeedItem]
    let source: WidgetSource
    let theme: WidgetTheme
    let username: String?

    static let placeholder = TopicEntry(
        date: Date(),
        topics: [
            WidgetFeedItem(title: "yükleniyor...", subtitle: nil, metadata: nil, link: ""),
            WidgetFeedItem(title: "yükleniyor...", subtitle: nil, metadata: nil, link: ""),
            WidgetFeedItem(title: "yükleniyor...", subtitle: nil, metadata: nil, link: ""),
        ],
        source: .gundem,
        theme: .dark,
        username: nil
    )
}

struct TopicsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TopicEntry {
        .placeholder
    }

    func snapshot(for intent: EksilikWidgetIntent, in context: Context) async -> TopicEntry {
        if context.isPreview { return .placeholder }
        return await fetchEntry(for: intent)
    }

    func timeline(for intent: EksilikWidgetIntent, in context: Context) async -> Timeline<TopicEntry> {
        let entry = await fetchEntry(for: intent)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(30 * 60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for intent: EksilikWidgetIntent) async -> TopicEntry {
        if intent.source == .following {
            let topics = WidgetSnapshotStore.shared.load(source: .following)?.items
                ?? [messageItem("takip akışı için uygulamayı bir kez aç")]
            return makeEntry(intent: intent, topics: topics)
        }

        guard let url = sourceURL(for: intent) else {
            return makeEntry(intent: intent, topics: [messageItem("kullanıcı adı giriniz")])
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                return cachedEntry(for: intent)
            }

            let topics: [WidgetFeedItem]
            switch intent.source {
            case .debe:
                topics = WidgetFeedParser.parseDebe(html: html)
            case .user:
                topics = WidgetHTMLParser.parseUserEntries(html: html)
            default:
                topics = WidgetFeedParser.parseTopics(html: html)
            }

            guard !topics.isEmpty else { return cachedEntry(for: intent) }
            savePublicSnapshot(topics, for: intent.source)
            return makeEntry(intent: intent, topics: topics)
        } catch {
            return cachedEntry(for: intent)
        }
    }

    private func sourceURL(for intent: EksilikWidgetIntent) -> URL? {
        let urlString: String
        switch intent.source {
        case .gundem:
            urlString = "https://eksisozluk.com/basliklar/gundem"
        case .bugun:
            urlString = "https://eksisozluk.com/basliklar/bugun/1"
        case .debe:
            urlString = "https://eksisozluk.com/debe"
        case .caylaklar:
            urlString = "https://eksisozluk.com/basliklar/caylaklar/bugun"
        case .user:
            let nick = (intent.username ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nick.isEmpty else { return nil }
            let encoded = nick.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? nick
            urlString = "https://eksisozluk.com/biri/\(encoded)"
        case .following:
            return nil
        }
        return URL(string: urlString)
    }

    private func cachedEntry(for intent: EksilikWidgetIntent) -> TopicEntry {
        guard let source = feedSource(for: intent.source),
              let snapshot = WidgetSnapshotStore.shared.load(source: source),
              !snapshot.items.isEmpty else {
            return makeEntry(intent: intent, topics: [messageItem("akış şu an yüklenemedi")])
        }
        return makeEntry(intent: intent, topics: snapshot.items)
    }

    private func savePublicSnapshot(_ topics: [WidgetFeedItem], for source: WidgetSource) {
        guard let source = feedSource(for: source) else { return }
        WidgetSnapshotStore.shared.save(
            WidgetFeedSnapshot(source: source, items: Array(topics.prefix(15)), updatedAt: Date())
        )
    }

    private func feedSource(for source: WidgetSource) -> WidgetFeedSource? {
        switch source {
        case .gundem: return .popular
        case .bugun: return .today
        case .following: return .following
        case .debe: return .debe
        case .user, .caylaklar: return nil
        }
    }

    private func makeEntry(intent: EksilikWidgetIntent, topics: [WidgetFeedItem]) -> TopicEntry {
        TopicEntry(
            date: Date(),
            topics: topics,
            source: intent.source,
            theme: intent.theme,
            username: intent.username
        )
    }

    private func messageItem(_ title: String) -> WidgetFeedItem {
        WidgetFeedItem(title: title, subtitle: nil, metadata: nil, link: "")
    }
}

private enum WidgetHTMLParser {
    static func parseUserEntries(html: String) -> [WidgetFeedItem] {
        guard let quickIndex = html.range(of: "quick-index", options: .caseInsensitive) else {
            return WidgetFeedParser.parseTopics(html: html)
        }
        let section = String(html[quickIndex.lowerBound...])
        return Array(WidgetFeedParser.parseTopics(html: "topic-list \(section)").prefix(10))
    }
}
