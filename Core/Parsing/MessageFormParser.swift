import Foundation
import Kanna

/// A message form rendered by the server, reduced to what a browser would
/// submit on its own: every named control with a value (including the
/// antiforgery token), plus the names of the composer and recipient fields
/// the app fills in.
struct MessageForm: Equatable {
    let id: String?
    let action: String?
    let hiddenFields: [String: String]
    var visibleFields: [String: String] = [:]
    var messageFieldName: String?
    var recipientFieldName: String?

    var token: String? {
        hiddenFields.first { $0.key.hasPrefix(MessageFormParser.tokenFieldPrefix) }?.value
    }

    var threadID: String? {
        hiddenFields.first { $0.key.caseInsensitiveCompare("ThreadId") == .orderedSame }?.value
    }

    /// Every field a browser submit would carry before the user types.
    var submittedFields: [String: String] {
        hiddenFields.merging(visibleFields) { hidden, _ in hidden }
    }

    var hasComposer: Bool { messageFieldName != nil }

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

    private static let unsubmittedInputTypes: Set<String> = ["submit", "button", "image", "reset", "file"]
    private static let recipientFieldNames: Set<String> = ["to", "recipient", "recipientnick", "touser", "nick"]

    static func forms(html: String) -> [MessageForm] {
        guard let doc = HTMLParser.parse(html) else { return [] }

        return doc.css("form").compactMap { form in
            let id = form["id"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let action = form["action"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isMessageForm = id?.lowercased().hasPrefix("message") == true
                || action?.lowercased().contains("/mesaj") == true
            guard isMessageForm else { return nil }

            var controls = inputControls(in: form)
            for (name, value) in selectedOptions(in: form) {
                controls.visible[name] = value
            }
            return MessageForm(
                id: id,
                action: action,
                hiddenFields: controls.hidden,
                visibleFields: controls.visible,
                messageFieldName: form.css("textarea").lazy.compactMap(fieldName).first,
                recipientFieldName: controls.recipientFieldName
            )
        }
    }

    /// The form that sends this kind of message. Other message forms (delete,
    /// archive, search) are ignored so their fields never leak into a send.
    /// When the markup carries no recognisable send marker, a tokenised form
    /// with a message composer is the one a person would type into.
    static func sendForm(html: String, isReply: Bool) -> MessageForm? {
        let candidates = forms(html: html).filter { $0.token != nil }
        return candidates.first { isReply ? $0.isReplyForm : $0.isNewMessageForm }
            ?? candidates.first { $0.hasComposer && (isReply || !$0.isReplyForm) }
    }

    private struct Controls {
        var hidden: [String: String] = [:]
        var visible: [String: String] = [:]
        var recipientFieldName: String?
    }

    /// Inputs a browser would submit, split into hidden and visible ones,
    /// plus the recipient field's name even while it is still empty.
    private static func inputControls(in form: Kanna.XMLElement) -> Controls {
        var controls = Controls()
        for input in form.css("input") {
            guard let name = fieldName(input) else { continue }
            let type = input["type"]?.lowercased() ?? "text"
            guard !unsubmittedInputTypes.contains(type) else { continue }
            if controls.recipientFieldName == nil, recipientFieldNames.contains(name.lowercased()) {
                controls.recipientFieldName = name
            }
            if (type == "checkbox" || type == "radio") && input["checked"] == nil { continue }
            guard let value = input["value"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { continue }
            if type == "hidden" {
                controls.hidden[name] = value
            } else {
                controls.visible[name] = value
            }
        }
        return controls
    }

    private static func selectedOptions(in form: Kanna.XMLElement) -> [String: String] {
        var values: [String: String] = [:]
        for select in form.css("select") {
            guard let name = fieldName(select),
                  let value = (select.at_css("option[selected]") ?? select.at_css("option"))?["value"]?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { continue }
            values[name] = value
        }
        return values
    }

    private static func fieldName(_ element: Kanna.XMLElement) -> String? {
        guard let name = element["name"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return nil }
        return name
    }
}
