import Foundation
import Kanna

struct DebeParser {
    static func parseList(html: String) -> [DebeEntry] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        var entries: [DebeEntry] = []

        for a in doc.css("ul.topic-list li a[href*='debe']") {
            let title = a.at_css("span.caption")?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? a.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let href = a["href"] ?? ""
            // Extract entry ID from /entry/12345?debe=true
            let id = href.replacingOccurrences(of: "/entry/", with: "")
                .components(separatedBy: "?").first ?? ""

            guard !id.isEmpty, !title.isEmpty else { continue }
            entries.append(DebeEntry(id: id, topicTitle: title, entryLink: href))
        }
        return entries
    }

    /// Parse a single entry page to get the content
    static func parseSingleEntry(html: String) -> (content: String, author: String, date: String)? {
        guard let doc = HTMLParser.parse(html) else { return nil }

        let content = doc.at_css("div[class^=content]")?.toHTML ?? ""
        let author = doc.at_css("ul[id^=entry-item-list] li")?["data-author"] ?? ""
        let date = doc.at_css("a[class^=entry-date permalink]")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !content.isEmpty else { return nil }
        return (content, author, date)
    }
}
