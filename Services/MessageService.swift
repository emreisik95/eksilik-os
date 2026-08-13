import Foundation

protocol MessageSending {
    func sendMessage(
        recipient: String,
        subject: String,
        body: String,
        threadID: String?,
        csrfToken: String?
    ) async throws
}

struct MessageService: MessageSending {
    private let client = HTTPClient.shared

    func fetchMessages(page: Int? = nil) async throws -> (threads: [MessageThread], pagination: Pagination) {
        let html = try await client.fetchHTML(for: .messages(page: page))
        await SessionManager.shared.updateFromHTML(html)
        let threads = MessageParser.parseThreadList(html: html)
        let pagination = PaginationParser.parse(html: html)
        return (threads, pagination)
    }

    func fetchThread(id: String, participant: String) async throws -> [Message] {
        let html = try await client.fetchHTML(for: .messageThread(id: id))
        let currentUsername = await SessionManager.shared.username
        await SessionManager.shared.updateFromHTML(html)
        return MessageContentParser.parse(
            html: html,
            currentUsername: currentUsername,
            participant: participant
        )
    }

    func sendMessage(
        recipient: String,
        subject: String,
        body: String,
        threadID: String?,
        csrfToken: String?
    ) async throws {
        guard let payload = MessageComposePolicy.payload(
            recipient: recipient,
            subject: subject,
            body: body,
            threadID: threadID
        ) else { return }
        try await client.post(
            endpoint: .sendMessage,
            body: payload,
            csrfToken: csrfToken
        )
    }
}
