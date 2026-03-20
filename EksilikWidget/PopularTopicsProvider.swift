import WidgetKit
import SwiftUI

struct TopicEntry: TimelineEntry {
    let date: Date
    let topics: [WidgetTopic]

    static let placeholder = TopicEntry(
        date: Date(),
        topics: [
            WidgetTopic(title: "Loading...", entryCount: "", link: ""),
            WidgetTopic(title: "Loading...", entryCount: "", link: ""),
            WidgetTopic(title: "Loading...", entryCount: "", link: ""),
        ]
    )
}

struct WidgetTopic: Identifiable {
    let id = UUID()
    let title: String
    let entryCount: String
    let link: String
}

struct PopularTopicsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TopicEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TopicEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        fetchTopics { entry in
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopicEntry>) -> Void) {
        fetchTopics { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchTopics(completion: @escaping (TopicEntry) -> Void) {
        guard let url = URL(string: "https://eksisozluk.com/basliklar/m/populer") else {
            completion(.placeholder)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data, let html = String(data: data, encoding: .utf8) else {
                completion(.placeholder)
                return
            }

            let topics = WidgetHTMLParser.parseTopics(html: html)
            let entry = TopicEntry(date: Date(), topics: topics)
            completion(entry)
        }.resume()
    }
}

enum WidgetHTMLParser {
    static func parseTopics(html: String) -> [WidgetTopic] {
        // Lightweight regex-based parsing for widget (no Kanna dependency in widget)
        var topics: [WidgetTopic] = []

        // Match <a href="/slug--id">title<small>count</small></a> pattern
        let pattern = #"<a href="(/[^"]+)"[^>]*>\s*(.*?)\s*(?:<small>([^<]*)</small>)?\s*</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let nsHTML = html as NSString
        // Find the topic-list section first
        guard let listRange = nsHTML.range(of: "topic-list").location != NSNotFound
                ? nsHTML.range(of: "topic-list") : nil else {
            return []
        }

        let searchRange = NSRange(location: listRange.location, length: nsHTML.length - listRange.location)
        let matches = regex.matches(in: html, range: searchRange)

        for match in matches.prefix(15) {
            let link = nsHTML.substring(with: match.range(at: 1))
            var title = nsHTML.substring(with: match.range(at: 2))
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
