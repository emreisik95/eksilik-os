import Foundation
import Kanna

struct MessageParser {
    static func parseThreadList(html: String) -> [MessageThread] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        var threads: [MessageThread] = []

        let previews = doc.css("ul[id^=threads] article a p").map { $0.text ?? "" }
        let dates = doc.css("ul[id^=threads] article footer time").map { $0.text ?? "" }
        let counts = doc.css("ul[id^=threads] article a h2 small").map { $0.text ?? "" }

        var usernames: [String] = []
        for el in doc.css("ul[id^=threads] article a h2") {
            if var small = el.at_css("small") { small.content = "" }
            usernames.append(el.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }

        var links: [String] = []
        for el in doc.css("ul[id^=threads] li article a") {
            if let href = el["href"] {
                links.append(href)
            }
        }

        let listItems = Array(doc.css("ul[id^=threads] li"))

        let count = min(usernames.count, previews.count, dates.count)
        for i in 0..<count {
            let isUnread: Bool
            if i < listItems.count {
                isUnread = listItems[i].at_css("article")?.parent?.className?.contains("unread") ?? false
            } else {
                isUnread = false
            }

            threads.append(MessageThread(
                id: i < links.count ? links[i] : "\(i)",
                username: usernames[i],
                preview: previews[i],
                date: dates[i],
                messageCount: i < counts.count ? counts[i] : "",
                link: i < links.count ? links[i] : "",
                isUnread: isUnread
            ))
        }

        return threads
    }
}
