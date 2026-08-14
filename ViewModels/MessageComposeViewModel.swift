import Foundation

@MainActor
final class MessageComposeViewModel: ObservableObject {
    @Published var recipient: String
    @Published var messageText = ""
    @Published private(set) var isSending = false
    @Published private(set) var didSend = false
    @Published private(set) var sendGeneration = 0
    @Published var error: String?

    let subject: String
    let threadID: String?
    let isRecipientLocked: Bool
    private let sender: MessageSending

    init(
        recipient: String,
        subject: String,
        threadID: String? = nil,
        sender: MessageSending = MessageService()
    ) {
        let recipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        self.recipient = recipient
        self.subject = subject
        self.threadID = threadID
        self.isRecipientLocked = !recipient.isEmpty
        self.sender = sender
    }

    var canSend: Bool {
        MessageComposePolicy.canSend(
            recipient: recipient,
            body: messageText,
            isSending: isSending
        )
    }

    func send(csrfToken: String?) async {
        guard !isSending,
              let payload = MessageComposePolicy.payload(
                recipient: recipient,
                subject: subject,
                body: messageText,
                threadID: threadID
              ) else {
            return
        }

        isSending = true
        didSend = false
        error = nil
        defer { isSending = false }

        do {
            try await sender.sendMessage(
                recipient: payload["To"] ?? "",
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                body: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                threadID: threadID,
                csrfToken: csrfToken
            )
            messageText = ""
            didSend = true
            sendGeneration &+= 1
        } catch {
            self.error = error.localizedDescription
        }
    }
}
