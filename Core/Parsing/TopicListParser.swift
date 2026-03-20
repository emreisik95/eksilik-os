import Foundation
import Kanna

struct TopicListParser {
    static func parse(html: String, isBlocked: ((String) -> Bool)? = nil) -> [Topic] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        var topics: [Topic] = []

        // Try multiple selector patterns
        let selectors = [
            "ul[class^=topic-list partial mobile] li a",
            "ul[class^=topic-list partial] li a",
            "ul[class*=topic-list] li a",
            "section[id=content-body] ul li a",
        ]

        for selector in selectors {
            let elements = Array(doc.css(selector))
            if elements.isEmpty { continue }

            for element in elements {
                guard let text = element.text, let link = element["href"] else { continue }

                let entryCount = element.at_css("small")?.text ?? ""

                // Remove the small element content from the title
                var title = text
                if !entryCount.isEmpty {
                    title = title.replacingOccurrences(of: entryCount, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }

                // Skip blocked topics
                if let isBlocked = isBlocked, isBlocked(title) { continue }

                let slug = link.components(separatedBy: "--").first?
                    .replacingOccurrences(of: "/", with: "") ?? ""
                let id = link.components(separatedBy: "--").last ?? link

                topics.append(Topic(
                    id: id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    slug: slug,
                    entryCount: entryCount.trimmingCharacters(in: .whitespacesAndNewlines),
                    link: link
                ))
            }
            if !topics.isEmpty { break }
        }

        return topics
    }

    /// Legacy overload for backward compatibility (e.g. tests passing [String]).
    static func parse(html: String, blockedTopics: [String]) -> [Topic] {
        parse(html: html, isBlocked: { title in
            blockedTopics.contains(where: { title.contains($0) })
        })
    }
}
