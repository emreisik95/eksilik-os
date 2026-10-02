import Foundation

enum MessageSendOutcome: Equatable {
    case delivered
    case rejected(reason: String?)
    case signedOut
}

enum MessageSendPolicy {
    static func isReply(threadID: String?) -> Bool {
        threadID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// Pages that render a message form for this send, in the order a fresh
    /// antiforgery token should be looked up. Tokens cached from older pages
    /// go stale, so every send starts from one of these documents.
    static func formPages(recipient: String, threadID: String?) -> [EksiEndpoint] {
        if isReply(threadID: threadID), let threadID {
            return [.messageThread(id: threadID.trimmingCharacters(in: .whitespacesAndNewlines))]
        }

        var pages: [EksiEndpoint] = [.messages(page: nil)]
        let recipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recipient.isEmpty {
            let encoded = recipient.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? recipient
            pages.append(.profile(username: encoded))
        }
        return pages
    }

    static func usableToken(_ token: String?) -> String? {
        guard let token = token?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else { return nil }
        return token
    }

    /// Form token first, then any token on the same page, then the token the
    /// session last saw.
    static func token(form: MessageForm?, pageToken: String?, cachedToken: String?) -> String? {
        usableToken(form?.token) ?? usableToken(pageToken) ?? usableToken(cachedToken)
    }

    /// Mirrors a browser submit: the server's hidden fields travel with the
    /// composed fields. The conversation id rendered by the server wins over
    /// the one derived from the thread link.
    static func requestBody(payload: [String: String], form: MessageForm?) -> [String: String] {
        var body = form?.hiddenFields.filter { !$0.key.hasPrefix(MessageFormParser.tokenFieldPrefix) } ?? [:]
        body.merge(payload) { _, composed in composed }

        if payload["ThreadId"] != nil, let serverThreadID = form?.threadID {
            body.keys
                .filter { $0.caseInsensitiveCompare("ThreadId") == .orderedSame }
                .forEach { body.removeValue(forKey: $0) }
            body["ThreadId"] = serverThreadID
        }
        return body
    }

    static func outcome(responseBody: Data) -> MessageSendOutcome {
        if let object = try? JSONSerialization.jsonObject(with: responseBody) as? [String: Any] {
            let success = (object["Success"] ?? object["success"]) as? Bool
            guard success == false else { return .delivered }
            let reason = ["Message", "message", "ErrorMessage", "error"]
                .lazy
                .compactMap { object[$0] as? String }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            return .rejected(reason: reason)
        }

        guard let html = String(data: responseBody, encoding: .utf8) else { return .delivered }
        let state = AuthParser.parseAuthState(html: html)
        return !state.isIndeterminate && !state.isLoggedIn ? .signedOut : .delivered
    }

    /// Pages without a form token say nothing about the session's token, so
    /// they must not erase the last one that was seen.
    static func retainedToken(current: String?, incoming: String?) -> String? {
        usableToken(incoming) ?? current
    }
}
