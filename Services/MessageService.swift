import Foundation

enum MessageSendError: LocalizedError, Equatable {
    case emptyMessage
    case missingCSRFToken
    case rejected(reason: String?)
    case notDelivered
    case unverified

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "mesaj gönderilemedi; alıcı ve mesaj boş olamaz"
        case .missingCSRFToken:
            return "mesaj güvenlik doğrulaması alınamadı; oturumun süresi dolmuş olabilir, "
                + "çıkış yapıp tekrar giriş yapmayı deneyin"
        case .rejected(let reason):
            return reason ?? "mesaj gönderilemedi; sunucu isteği kabul etmedi"
        case .notDelivered:
            return "mesaj gönderilemedi; ekşi sözlük mesajı kabul etmedi. "
                + "taslağın duruyor, tekrar deneyebilirsin"
        case .unverified:
            return "mesajın ulaştığı doğrulanamadı; konuşmayı yenileyip kontrol et"
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
    private let pauseBeforeRecheck: () async -> Void

    init(
        transport: MessageTransport = HTTPClient.shared,
        observePage: @escaping (String) async -> Void = { await SessionManager.shared.updateFromHTML($0) },
        pauseBeforeRecheck: @escaping () async -> Void = { try? await Task.sleep(nanoseconds: 1_200_000_000) }
    ) {
        self.transport = transport
        self.observePage = observePage
        self.pauseBeforeRecheck = pauseBeforeRecheck
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
        ) else { throw MessageSendError.emptyMessage }

        let isReply = MessageSendPolicy.isReply(threadID: threadID)
        let fresh = try await freshForm(recipient: recipient, threadID: threadID)
        guard let token = MessageSendPolicy.token(
            form: fresh.form,
            pageToken: fresh.pageToken,
            cachedToken: csrfToken
        ) else {
            throw MessageSendError.missingCSRFToken
        }

        let (data, _) = try await transport.post(
            endpoint: MessageSendPolicy.submitEndpoint(form: fresh.form, isReply: isReply),
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
        case .unconfirmed:
            try await confirmDelivery(
                of: payload["Message"] ?? body,
                response: data,
                recipient: recipient,
                threadID: isReply ? threadID : nil,
                before: fresh.conversation
            )
        }
    }

    /// Reads the conversation back until it shows the sent message. A send
    /// is never reported as done on the strength of an empty or unrelated
    /// response alone.
    private func confirmDelivery(
        of sent: String,
        response: Data,
        recipient: String,
        threadID: String?,
        before: [Message]?
    ) async throws {
        if let html = String(data: response, encoding: .utf8) {
            let shown = MessageContentParser.parse(html: html)
            if MessageDeliveryPolicy.isDelivered(sent: sent, before: before, after: shown) { return }
        }

        var sawConversation = false
        for attempt in 0..<2 {
            if attempt > 0 { await pauseBeforeRecheck() }
            guard let after = try await readConversation(recipient: recipient, threadID: threadID),
                  !after.isEmpty else { continue }
            sawConversation = true
            if MessageDeliveryPolicy.isDelivered(sent: sent, before: before, after: after) { return }
        }
        throw sawConversation ? MessageSendError.notDelivered : MessageSendError.unverified
    }

    /// The conversation with the recipient as the server shows it now, or
    /// nil when it could not be read.
    private func readConversation(recipient: String, threadID: String?) async throws -> [Message]? {
        let threadPage: String
        if let threadID = threadID?.trimmingCharacters(in: .whitespacesAndNewlines), !threadID.isEmpty {
            threadPage = threadID
        } else {
            guard let inbox = try await readPage(.messages(page: nil)),
                  let thread = MessageDeliveryPolicy.thread(
                    for: recipient,
                    in: MessageParser.parseThreadList(html: inbox)
                  ) else { return nil }
            threadPage = thread.link
        }
        guard let html = try await readPage(.messageThread(id: threadPage)) else { return nil }
        return MessageContentParser.parse(html: html)
    }

    private func readPage(_ endpoint: EksiEndpoint) async throws -> String? {
        let html: String
        do {
            html = try await transport.fetchHTML(for: endpoint)
        } catch NetworkError.unauthorized {
            throw NetworkError.unauthorized
        } catch {
            return nil
        }
        await observePage(html)
        return html
    }

    /// Loads the page that renders the matching message form so the send
    /// carries a token issued for the current session, not a cached one. A
    /// reply's page is also the conversation as it was before the send.
    private func freshForm(
        recipient: String,
        threadID: String?
    ) async throws -> (form: MessageForm?, pageToken: String?, conversation: [Message]?) {
        let isReply = MessageSendPolicy.isReply(threadID: threadID)
        var pageToken: String?
        var conversation: [Message]?

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
            if isReply {
                conversation = MessageContentParser.parse(html: html)
            }
            if let form = MessageFormParser.sendForm(html: html, isReply: isReply) {
                return (form, form.token, conversation)
            }
            pageToken = pageToken ?? MessageSendPolicy.usableToken(auth.csrfToken)
        }
        return (nil, pageToken, conversation)
    }
}
