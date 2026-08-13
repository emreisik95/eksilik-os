import Foundation

enum MessageComposePolicy {
    static func payload(
        recipient: String,
        subject: String,
        body: String,
        threadID: String? = nil
    ) -> [String: String]? {
        let recipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recipient.isEmpty, !body.isEmpty else { return nil }

        let message: String
        if subject.isEmpty {
            message = body
        } else if subject.hasPrefix("#") {
            message = "(\(subject)) \(body)"
        } else {
            message = "\(subject)\n\n\(body)"
        }
        var payload = [
            "To": recipient,
            "Message": message,
        ]
        if let threadID = threadID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !threadID.isEmpty {
            payload["ThreadId"] = threadID
            payload["IsReply"] = "True"
        }
        return payload
    }

    static func canSend(recipient: String, body: String, isSending: Bool) -> Bool {
        !isSending && payload(recipient: recipient, subject: "", body: body) != nil
    }
}
