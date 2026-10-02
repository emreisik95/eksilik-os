import Foundation

enum MessageSendError: LocalizedError, Equatable {
    case missingCSRFToken
    case rejected(reason: String?)

    var errorDescription: String? {
        switch self {
        case .missingCSRFToken:
            return "mesaj güvenlik doğrulaması alınamadı; oturumun süresi dolmuş olabilir, "
                + "çıkış yapıp tekrar giriş yapmayı deneyin"
        case .rejected(let reason):
            return reason ?? "mesaj gönderilemedi; sunucu isteği kabul etmedi"
        }
    }
}

protocol MessageSending {
    func sendMessage(
        recipient: String,
        subject: String,
        body: String,
        threadID: String?,
        csrfToken: String?
    ) async throws
}

protocol MessageTransport {
    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String
    func post(
        endpoint: EksiEndpoint,
        body: [String: String],
        csrfToken: String?
    ) async throws -> (Data, HTTPURLResponse)
}

extension HTTPClient: MessageTransport {}

struct MessageService: MessageSending {
    private let transport: MessageTransport
    private let observePage: (String) async -> Void

    init(
        transport: MessageTransport = HTTPClient.shared,
        observePage: @escaping (String) async -> Void = { await SessionManager.shared.updateFromHTML($0) }
    ) {
        self.transport = transport
        self.observePage = observePage
    }

    static func endpoint(for threadID: String?) -> EksiEndpoint {
        MessageSendPolicy.isReply(threadID: threadID) ? .replyMessage : .sendMessage
    }

    static func usableCSRFToken(_ token: String?) -> String? {
        MessageSendPolicy.usableToken(token)
    }

    func fetchMessages(page: Int? = nil) async throws -> (threads: [MessageThread], pagination: Pagination) {
        let html = try await transport.fetchHTML(for: .messages(page: page))
        await observePage(html)
        let threads = MessageParser.parseThreadList(html: html)
        let pagination = PaginationParser.parse(html: html)
        return (threads, pagination)
    }

    func fetchThread(id: String, participant: String) async throws -> [Message] {
        let html = try await transport.fetchHTML(for: .messageThread(id: id))
        let currentUsername = await SessionManager.shared.username
        await observePage(html)
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

        let fresh = try await freshForm(recipient: recipient, threadID: threadID)
        guard let token = MessageSendPolicy.token(
            form: fresh.form,
            pageToken: fresh.pageToken,
            cachedToken: csrfToken
        ) else {
            throw MessageSendError.missingCSRFToken
        }

        let (data, _) = try await transport.post(
            endpoint: Self.endpoint(for: threadID),
            body: MessageSendPolicy.requestBody(payload: payload, form: fresh.form),
            csrfToken: token
        )

        switch MessageSendPolicy.outcome(responseBody: data) {
        case .delivered:
            return
        case .signedOut:
            throw NetworkError.unauthorized
        case .rejected(let reason):
            throw MessageSendError.rejected(reason: reason)
        }
    }

    /// Loads the page that renders the matching message form so the send
    /// carries a token issued for the current session, not a cached one.
    private func freshForm(
        recipient: String,
        threadID: String?
    ) async throws -> (form: MessageForm?, pageToken: String?) {
        let isReply = MessageSendPolicy.isReply(threadID: threadID)
        var pageToken: String?

        for page in MessageSendPolicy.formPages(recipient: recipient, threadID: threadID) {
            let html: String
            do {
                html = try await transport.fetchHTML(for: page)
            } catch NetworkError.unauthorized {
                throw NetworkError.unauthorized
            } catch {
                continue
            }
            await observePage(html)

            let auth = AuthParser.parseAuthState(html: html)
            if !auth.isIndeterminate && !auth.isLoggedIn {
                throw NetworkError.unauthorized
            }
            if let form = MessageFormParser.sendForm(html: html, isReply: isReply) {
                return (form, form.token)
            }
            pageToken = pageToken ?? MessageSendPolicy.usableToken(auth.csrfToken)
        }
        return (nil, pageToken)
    }
}
