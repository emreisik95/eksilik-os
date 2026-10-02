import Foundation
import Kanna

/// A message form rendered by the server, reduced to what a browser would
/// submit on its own: the hidden fields (including the antiforgery token).
struct MessageForm: Equatable {
    let id: String?
    let action: String?
    let hiddenFields: [String: String]

    var token: String? {
        hiddenFields.first { $0.key.hasPrefix(MessageFormParser.tokenFieldPrefix) }?.value
    }

    var threadID: String? {
        hiddenFields.first { $0.key.caseInsensitiveCompare("ThreadId") == .orderedSame }?.value
    }

    var isReplyForm: Bool {
        threadID != nil || action?.lowercased().contains("/mesaj/yolla") == true
    }

    var isNewMessageForm: Bool {
        guard !isReplyForm else { return false }
        return id?.lowercased().hasPrefix("message-send-form") == true
            || action?.lowercased().contains("/mesaj/sendajax") == true
    }
}

enum MessageFormParser {
    static let tokenFieldPrefix = "__RequestVerificationToken"

    static func forms(html: String) -> [MessageForm] {
        guard let doc = HTMLParser.parse(html) else { return [] }

        return doc.css("form").compactMap { form in
            let id = form["id"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let action = form["action"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isMessageForm = id?.lowercased().hasPrefix("message") == true
                || action?.lowercased().contains("/mesaj") == true
            guard isMessageForm else { return nil }

            var hiddenFields: [String: String] = [:]
            for input in form.css("input") {
                guard input["type"]?.lowercased() == "hidden",
                      let name = input["name"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !name.isEmpty,
                      let value = input["value"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !value.isEmpty else { continue }
                hiddenFields[name] = value
            }
            return MessageForm(id: id, action: action, hiddenFields: hiddenFields)
        }
    }

    /// The form that sends this kind of message. Other message forms (delete,
    /// archive, search) are ignored so their fields never leak into a send.
    static func sendForm(html: String, isReply: Bool) -> MessageForm? {
        forms(html: html).first { form in
            form.token != nil && (isReply ? form.isReplyForm : form.isNewMessageForm)
        }
    }
}
