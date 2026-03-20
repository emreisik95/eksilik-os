import WidgetKit
import SwiftUI

struct TopicEntry: TimelineEntry {
    let date: Date
    let topics: [WidgetTopic]
    let source: WidgetSource
    let theme: WidgetTheme
    let username: String?

    static let placeholder = TopicEntry(
        date: Date(),
        topics: [
            WidgetTopic(title: "yükleniyor...", entryCount: "", link: ""),
            WidgetTopic(title: "yükleniyor...", entryCount: "", link: ""),
            WidgetTopic(title: "yükleniyor...", entryCount: "", link: ""),
        ],
        source: .gundem,
        theme: .dark,
        username: nil
    )
}

struct WidgetTopic: Identifiable {
    let id = UUID()
    let title: String
    let entryCount: String
    let link: String
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
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for intent: EksilikWidgetIntent) async -> TopicEntry {
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
            let nick = (intent.username ?? "").trimmingCharacters(in: .whitespaces)
            if nick.isEmpty {
                return TopicEntry(date: Date(), topics: [WidgetTopic(title: "kullanıcı adı giriniz", entryCount: "", link: "")], source: intent.source, theme: intent.theme, username: nick)
            }
            let encoded = nick.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? nick
            urlString = "https://eksisozluk.com/biri/\(encoded)"
        }

        guard let url = URL(string: urlString) else { return .placeholder }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return .placeholder }

            let topics: [WidgetTopic]
            if intent.source == .debe {
                topics = WidgetHTMLParser.parseDebeTopics(html: html)
            } else if intent.source == .user {
                topics = WidgetHTMLParser.parseUserEntries(html: html)
            } else {
                topics = WidgetHTMLParser.parseTopics(html: html)
            }
            return TopicEntry(date: Date(), topics: topics, source: intent.source, theme: intent.theme, username: intent.username)
        } catch {
            return .placeholder
        }
    }
}

enum WidgetHTMLParser {
    static func parseTopics(html: String) -> [WidgetTopic] {
        var topics: [WidgetTopic] = []
        let pattern = #"<a href="(/[^"]+)"[^>]*>\s*(.*?)\s*(?:<small>([^<]*)</small>)?\s*</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return [] }

        let nsHTML = html as NSString
        guard nsHTML.range(of: "topic-list").location != NSNotFound else { return [] }
        let listRange = nsHTML.range(of: "topic-list")
        let searchRange = NSRange(location: listRange.location, length: nsHTML.length - listRange.location)
        let matches = regex.matches(in: html, range: searchRange)

        for match in matches.prefix(15) {
            let link = nsHTML.substring(with: match.range(at: 1))
            let title = nsHTML.substring(with: match.range(at: 2))
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let count = match.range(at: 3).location != NSNotFound
                ? nsHTML.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            if !title.isEmpty && link.hasPrefix("/") {
                topics.append(WidgetTopic(title: title, entryCount: count, link: link))
            }
        }
        return topics
    }

    static func parseDebeTopics(html: String) -> [WidgetTopic] {
        var topics: [WidgetTopic] = []
        let pattern = #"<a href="(/entry/\d+\?debe=true)"[^>]*>\s*<span class="caption">([^<]+)</span>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        for match in matches.prefix(15) {
            let link = nsHTML.substring(with: match.range(at: 1))
            let title = nsHTML.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                topics.append(WidgetTopic(title: title, entryCount: "", link: link))
            }
        }
        return topics
    }

    static func parseUserEntries(html: String) -> [WidgetTopic] {
        // Parse from the profile page's quick-index topic list (gündem topics the user contributed to)
        // These are in the left sidebar: <a href="/slug--id?a=popular">title <small>count</small></a>
        var topics: [WidgetTopic] = []

        // Find quick-index section
        let nsHTML = html as NSString
        guard let indexRange = nsHTML.range(of: "quick-index").location != NSNotFound
                ? nsHTML.range(of: "quick-index") : nil else {
            // Fallback: try topic-list
            return parseTopics(html: html)
        }

        let pattern = #"<a href="(/[^"]+)"[^>]*>\s*(.*?)\s*(?:<small>([^<]*)</small>)?\s*</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return [] }

        let searchRange = NSRange(location: indexRange.location, length: nsHTML.length - indexRange.location)
        let matches = regex.matches(in: html, range: searchRange)

        for match in matches.prefix(10) {
            let link = nsHTML.substring(with: match.range(at: 1))
            let title = nsHTML.substring(with: match.range(at: 2))
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let count = match.range(at: 3).location != NSNotFound
                ? nsHTML.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            if !title.isEmpty && link.hasPrefix("/") {
                topics.append(WidgetTopic(title: title, entryCount: count, link: link))
            }
        }
        return topics
    }
}
