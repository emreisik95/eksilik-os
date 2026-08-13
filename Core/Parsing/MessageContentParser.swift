import Foundation
import Kanna

struct MessageContentParser {
    static func parse(
        html: String,
        currentUsername: String? = nil,
        participant: String? = nil
    ) -> [Message] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        return articleElements(in: doc).enumerated().map { index, article in
            parseArticle(
                article,
                index: index,
                currentUsername: currentUsername,
                participant: participant
            )
        }
    }

    private static func articleElements(in document: Kanna.HTMLDocument) -> [Kanna.XMLElement] {
        let current = Array(document.css("#message-thread article"))
        if !current.isEmpty { return current }

        let legacy = Array(document.css("ul[id^=message-thread] li article"))
        if !legacy.isEmpty { return legacy }
        return Array(document.css(".message-thread article"))
    }

    private static func parseArticle(
        _ article: Kanna.XMLElement,
        index: Int,
        currentUsername: String?,
        participant: String?
    ) -> Message {
        let paragraph = article.at_css("p")
        let content = paragraph?.toHTML
            ?? paragraph?.text
            ?? article.at_css(".message-content")?.text
            ?? ""
        let direction = messageDirection(for: article)
        let sender = messageSender(
            for: article,
            direction: direction,
            currentUsername: currentUsername,
            participant: participant
        )
        let serverID = article["data-message-id"]
            ?? article["data-id"]
            ?? article["id"]
            ?? article.at_css(".message-report-link")?["data-id"]

        return Message(
            id: normalized(serverID).nilIfEmpty ?? "message-\(index)",
            contentHTML: content,
            sender: sender,
            date: normalized(article.at_css("time")?.text),
            direction: direction
        )
    }

    private static func messageDirection(for article: Kanna.XMLElement) -> MessageDirection {
        let classNames = article.className?.lowercased().split(separator: " ") ?? []
        if classNames.contains("incoming") { return .incoming }
        if classNames.contains("outgoing") { return .outgoing }
        return .unknown
    }

    private static func messageSender(
        for article: Kanna.XMLElement,
        direction: MessageDirection,
        currentUsername: String?,
        participant: String?
    ) -> String {
        let explicit = normalized(
            article.at_css(".sender")?.text
                ?? article.at_css("h3 a")?.text
                ?? article.at_css("h3")?.text
        )
        if !explicit.isEmpty { return explicit }

        switch direction {
        case .incoming: return participant ?? ""
        case .outgoing: return currentUsername ?? ""
        case .unknown: return ""
        }
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
