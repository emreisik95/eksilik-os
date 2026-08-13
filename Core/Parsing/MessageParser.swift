import Foundation
import Kanna

struct MessageParser {
    static func parseThreadList(html: String) -> [MessageThread] {
        guard let doc = HTMLParser.parse(html) else { return [] }
        let legacyRows = Array(doc.css("ul[id^=threads] li"))
        if !legacyRows.isEmpty {
            return legacyRows.compactMap(parseThread)
        }

        let currentRows = Array(doc.css(".message-thread-list .thread"))
        return currentRows.compactMap(parseThread)
    }

    static func threadIdentifier(from href: String) -> String? {
        guard let components = URLComponents(string: href) else { return nil }

        if let scheme = components.scheme?.lowercased() {
            guard scheme == "https" || scheme == "http",
                  let host = components.host?.lowercased(),
                  host == "eksisozluk.com" || host == "www.eksisozluk.com" else {
                return nil
            }
        } else if let host = components.host?.lowercased(),
                  host != "eksisozluk.com" && host != "www.eksisozluk.com" {
            return nil
        }

        let pathParts = components.percentEncodedPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        guard pathParts.count == 2, pathParts[0].lowercased() == "mesaj" else {
            return nil
        }

        let identifier = (pathParts[1].removingPercentEncoding ?? pathParts[1])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return identifier.isEmpty ? nil : identifier
    }

    private static func parseThread(row: Kanna.XMLElement) -> MessageThread? {
        guard let linkElement = row.at_css("a[href*='/mesaj/']"),
              let href = linkElement["href"],
              let identifier = threadIdentifier(from: href) else {
            return nil
        }

        let count = normalizedText(
            row.at_css("h2 small")?.text
                ?? row.at_css(".message-count")?.text
                ?? row["data-message-count"]
        )
        var username = normalizedText(
            row.at_css(".username")?.text
                ?? row["data-username"]
                ?? row.at_css("h2")?.text
        )
        if !count.isEmpty, username.hasSuffix(count) {
            username = normalizedText(String(username.dropLast(count.count)))
        }
        guard !username.isEmpty else { return nil }

        let preview = normalizedText(
            row.at_css(".preview")?.text
                ?? linkElement.at_css("p")?.text
                ?? row.at_css("p")?.text
        )
        let date = normalizedText(row.at_css("time")?.text)
        let classNames = [row.className, row.at_css("article")?.className]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        let unreadAttribute = row["data-unread"]?.lowercased()
        let isUnread = classNames.split(separator: " ").contains("unread")
            || unreadAttribute == "true"
            || unreadAttribute == "1"

        return MessageThread(
            id: identifier,
            username: username,
            preview: preview,
            date: date,
            messageCount: count,
            link: identifier,
            isUnread: isUnread
        )
    }

    private static func normalizedText(_ value: String?) -> String {
        (value ?? "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
