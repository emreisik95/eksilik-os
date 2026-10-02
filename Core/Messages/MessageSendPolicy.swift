import Foundation
import Kanna

enum MessageSendOutcome: Equatable {
    case delivered
    case rejected(reason: String?)
    case signedOut
    /// The response neither confirms nor rejects the send; only the
    /// conversation itself can say whether the message arrived.
    case unconfirmed
}

/// One route for handing a message to the server: where it is posted and
/// the fields that travel with it.
struct MessageSubmission: Equatable {
    let endpoint: EksiEndpoint
    let body: [String: String]
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

    /// Where a browser would submit the form: its own `/mesaj/...` action on
    /// this site, else the endpoint the app has always used for this kind of
    /// message.
    static func submitEndpoint(form: MessageForm?, isReply: Bool) -> EksiEndpoint {
        guard let path = sameSiteMessagePath(form?.action) else {
            return isReply ? .replyMessage : .sendMessage
        }
        switch path.lowercased() {
        case EksiEndpoint.replyMessage.path.lowercased(): return .replyMessage
        case EksiEndpoint.sendMessage.path.lowercased(): return .sendMessage
        default: return .submitMessageForm(path: path)
        }
    }

    /// Routes for this message, best first. The first mirrors the browser:
    /// the rendered form's own action and fields. The second is the other
    /// message endpoint, addressed by recipient alone, for when the server
    /// fails on the first route. It is only taken once the conversation shows
    /// the first attempt stored nothing.
    static func submissions(payload: [String: String], form: MessageForm?, isReply: Bool) -> [MessageSubmission] {
        let primary = MessageSubmission(
            endpoint: submitEndpoint(form: form, isReply: isReply),
            body: requestBody(payload: payload, form: form)
        )

        if primary.endpoint.path.caseInsensitiveCompare(EksiEndpoint.sendMessage.path) == .orderedSame {
            return [primary, MessageSubmission(endpoint: .replyMessage, body: requestBody(payload: payload, form: nil))]
        }

        var direct = payload
        direct.removeValue(forKey: "ThreadId")
        direct.removeValue(forKey: "IsReply")
        if let rendered = value(forKey: form?.recipientFieldName ?? "To", in: primary.body) {
            direct["To"] = rendered
        }
        return [primary, MessageSubmission(endpoint: .sendMessage, body: requestBody(payload: direct, form: nil))]
    }

    /// A missing route or a server failure says nothing was accepted on that
    /// route, so another route may be tried once the conversation confirms
    /// the message is absent. Rejections and session problems end the send.
    static func allowsAnotherRoute(afterStatus statusCode: Int) -> Bool {
        statusCode == 404 || statusCode == 405 || (500...599).contains(statusCode)
    }

    /// Mirrors a browser submit: the fields the server rendered travel with
    /// the composed text under the form's own field names. In a reply, the
    /// recipient and conversation id rendered by the server win over the ones
    /// derived from the thread link, and a link slug is never sent as an id.
    static func requestBody(payload: [String: String], form: MessageForm?) -> [String: String] {
        var body = form?.submittedFields.filter { !$0.key.hasPrefix(MessageFormParser.tokenFieldPrefix) } ?? [:]
        let isReply = payload["ThreadId"] != nil

        let messageKey = form?.messageFieldName ?? "Message"
        if let message = payload["Message"] {
            removeKeys(matching: messageKey, from: &body)
            body[messageKey] = message
        }

        let recipientKey = form?.recipientFieldName ?? "To"
        let renderedRecipient = value(forKey: recipientKey, in: body)
        if let recipient = payload["To"], !(isReply && renderedRecipient != nil) {
            removeKeys(matching: recipientKey, from: &body)
            body[recipientKey] = recipient
        }

        guard isReply else { return body }
        let threadID = usableToken(form?.threadID) ?? payload["ThreadId"].flatMap(numericThreadID)
        removeKeys(matching: "ThreadId", from: &body)
        guard let threadID else {
            removeKeys(matching: "IsReply", from: &body)
            return body
        }
        body["ThreadId"] = threadID
        if value(forKey: "IsReply", in: body) == nil {
            body["IsReply"] = payload["IsReply"] ?? "True"
        }
        return body
    }

    /// Only an explicit answer from the server settles a send here. Anything
    /// else (an empty body, a rendered page) has to be checked against the
    /// conversation before the app may say the message went out.
    static func outcome(responseBody: Data) -> MessageSendOutcome {
        if let object = try? JSONSerialization.jsonObject(with: responseBody) as? [String: Any] {
            let success = ["Success", "success", "IsSuccess", "isSuccess"]
                .lazy
                .compactMap { object[$0] as? Bool }
                .first
            switch success {
            case true?: return .delivered
            case false?: return .rejected(reason: jsonReason(object))
            case nil: return .unconfirmed
            }
        }

        guard let html = String(data: responseBody, encoding: .utf8) else { return .unconfirmed }
        let state = AuthParser.parseAuthState(html: html)
        if !state.isIndeterminate && !state.isLoggedIn { return .signedOut }
        if let reason = validationError(html: html) { return .rejected(reason: reason) }
        return .unconfirmed
    }

    /// The validation message a rejected form page renders, if any.
    static func validationError(html: String) -> String? {
        guard let doc = HTMLParser.parse(html) else { return nil }
        let selectors = [".validation-summary-errors li", ".validation-summary-errors", ".field-validation-error"]
        for selector in selectors {
            for node in doc.css(selector) {
                let text = (node.text ?? "")
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !text.isEmpty { return text }
            }
        }
        return nil
    }

    /// Pages without a form token say nothing about the session's token, so
    /// they must not erase the last one that was seen.
    static func retainedToken(current: String?, incoming: String?) -> String? {
        usableToken(incoming) ?? current
    }

    private static func jsonReason(_ object: [String: Any]) -> String? {
        ["Message", "message", "ErrorMessage", "errorMessage", "error"]
            .lazy
            .compactMap { object[$0] as? String }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func numericThreadID(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return value
    }

    private static func value(forKey key: String, in body: [String: String]) -> String? {
        body.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }

    private static func removeKeys(matching key: String, from body: inout [String: String]) {
        body.keys
            .filter { $0.caseInsensitiveCompare(key) == .orderedSame }
            .forEach { body.removeValue(forKey: $0) }
    }

    /// The form action as a request path, accepted only when it stays on this
    /// site and under `/mesaj/`.
    private static func sameSiteMessagePath(_ action: String?) -> String? {
        guard let action = action?.trimmingCharacters(in: .whitespacesAndNewlines),
              !action.isEmpty,
              let components = URLComponents(string: action) else { return nil }
        if let scheme = components.scheme?.lowercased(), scheme != "https", scheme != "http" { return nil }
        if let host = components.host?.lowercased(), host != "eksisozluk.com", host != "www.eksisozluk.com" {
            return nil
        }
        if components.scheme != nil, components.host == nil { return nil }
        let path = components.percentEncodedPath
        guard path.lowercased().hasPrefix("/mesaj/"), path.count > "/mesaj/".count else { return nil }
        if let query = components.percentEncodedQuery, !query.isEmpty {
            return path + "?" + query
        }
        return path
    }
}
