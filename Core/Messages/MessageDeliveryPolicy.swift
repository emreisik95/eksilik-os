import Foundation

/// Decides from the conversation itself whether a sent message arrived, for
/// sends the server answers without an explicit result.
enum MessageDeliveryPolicy {
    private static let locale = Locale(identifier: "tr_TR")

    /// Whether `text`, as the server rendered it, carries the message that was
    /// sent. Rendering may drop line breaks, punctuation or turn links into
    /// labels, so the comparison runs on letters and digits, and falls back to
    /// most of the sent words being present.
    static func matches(sent: String, text: String) -> Bool {
        let sentKey = searchKey(sent)
        guard !sentKey.isEmpty else {
            let raw = sent.trimmingCharacters(in: .whitespacesAndNewlines)
            return !raw.isEmpty && text.contains(raw)
        }
        if searchKey(text).contains(sentKey) { return true }

        let sentWords = Set(words(sent).filter { $0.count >= 2 })
        guard !sentWords.isEmpty else { return false }
        let found = sentWords.intersection(words(text)).count
        return Double(found) >= Double(sentWords.count) * 0.8
    }

    /// Whether the conversation read after a send shows the sent message.
    /// With the conversation as it was before the send, only messages that
    /// appeared since then count; without it, the newest few at either end of
    /// the page do, since pages may list messages oldest or newest first.
    static func isDelivered(sent: String, before: [Message]?, after: [Message]) -> Bool {
        let candidates: [Message]
        if let before {
            var earlier = Dictionary(grouping: before, by: fingerprint).mapValues(\.count)
            candidates = after.filter { message in
                let key = fingerprint(message)
                guard let count = earlier[key], count > 0 else { return true }
                earlier[key] = count - 1
                return false
            }
        } else {
            candidates = Array(after.prefix(5)) + Array(after.suffix(5))
        }
        return candidates.contains { $0.direction != .incoming && matches(sent: sent, text: $0.contentText) }
    }

    /// The inbox conversation with `recipient`. Nicks may be listed with
    /// spaces where links use dashes, so both spellings are accepted.
    static func thread(for recipient: String, in threads: [MessageThread]) -> MessageThread? {
        let wanted = nickKey(recipient)
        guard !wanted.isEmpty else { return nil }
        return threads.first { nickKey($0.username) == wanted }
            ?? threads.first { nickKey($0.link) == wanted }
    }

    private static func fingerprint(_ message: Message) -> String {
        "\(message.direction)|\(searchKey(message.contentText))"
    }

    private static func searchKey(_ text: String) -> String {
        String(text.lowercased(with: locale).filter { $0.isLetter || $0.isNumber })
    }

    private static func words(_ text: String) -> Set<String> {
        Set(
            text.lowercased(with: locale)
                .split { !($0.isLetter || $0.isNumber) }
                .map(String.init)
        )
    }

    private static func nickKey(_ text: String) -> String {
        text.lowercased(with: locale)
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
