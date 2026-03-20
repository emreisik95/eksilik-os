import Foundation
import Kanna

struct MessageContentParser {
    static func parse(html: String) -> [Message] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        var messages: [Message] = []

        for (index, article) in doc.css("ul[id^=message-thread] li article").enumerated() {
            let content = article.at_css("p")?.toHTML ?? article.at_css("p")?.text ?? ""
            let sender = article.at_css("h3 a")?.text ?? article.at_css("h3")?.text ?? ""
            let date = article.at_css("footer time")?.text ?? ""

            messages.append(Message(
                id: "\(index)",
                contentHTML: content,
                sender: sender.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }

        return messages
    }
}
