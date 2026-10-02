import Foundation

enum MessageSendError: LocalizedError, Equatable {
    case emptyMessage
    case missingCSRFToken
    case rejected(reason: String?)
    case notDelivered
    case unverified
    case serverFailed(statusCode: Int)

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
        case .serverFailed(let statusCode):
            return "mesaj gönderilemedi; ekşi sözlük isteği işleyemedi (\(statusCode)). "
                + "taslağın duruyor, biraz sonra tekrar deneyebilirsin"
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

        let pending = PendingSend(
            text: payload["Message"] ?? body,
            recipient: recipient,
            threadID: isReply ? threadID : nil,
            conversationBefore: fresh.conversation,
            token: token
        )
        var failedStatus: Int?
        for submission in MessageSendPolicy.submissions(payload: payload, form: fresh.form, isReply: isReply) {
            switch try await submit(submission, for: pending) {
            case .delivered: return
            case .failed(let statusCode): failedStatus = statusCode
            }
        }
        throw MessageSendError.serverFailed(statusCode: failedStatus ?? 500)
    }

    private struct PendingSend {
        let text: String
        let recipient: String
        /// The conversation being replied to; nil for a new message.
        let threadID: String?
        let conversationBefore: [Message]?
        let token: String
    }

    private enum RouteResult {
        case delivered
        /// The server failed on this route and the conversation shows the
        /// message did not arrive, so another route is safe to try.
        case failed(statusCode: Int)
    }

    private func submit(_ submission: MessageSubmission, for pending: PendingSend) async throws -> RouteResult {
        let data: Data
        do {
            data = try await transport.post(
                endpoint: submission.endpoint,
                body: submission.body,
                csrfToken: pending.token
            ).0
        } catch NetworkError.requestFailed(let statusCode)
                    where MessageSendPolicy.allowsAnotherRoute(afterStatus: statusCode) {
            print("✉️ \(submission.endpoint.path) failed with \(statusCode)")
            // The server can fail after storing the message, so another route
            // is only safe once the conversation shows it is absent.
            switch try await deliveryState(of: pending) {
            case .delivered: return .delivered
            case .missing: return .failed(statusCode: statusCode)
            case .unknown: throw MessageSendError.unverified
            }
        }

        switch MessageSendPolicy.outcome(responseBody: data) {
        case .delivered:
            return .delivered
        case .signedOut:
            throw NetworkError.unauthorized
        case .rejected(let reason):
            throw MessageSendError.rejected(reason: reason)
        case .unconfirmed:
            try await confirmDelivery(of: pending, response: data)
            return .delivered
        }
    }

    /// Reads the conversation back until it shows the sent message. A send
    /// is never reported as done on the strength of an empty or unrelated
    /// response alone.
    private func confirmDelivery(of pending: PendingSend, response: Data) async throws {
        if let html = String(data: response, encoding: .utf8) {
            let shown = MessageContentParser.parse(html: html)
            if MessageDeliveryPolicy.isDelivered(
                sent: pending.text,
                before: pending.conversationBefore,
                after: shown
            ) { return }
        }

        switch try await deliveryState(of: pending) {
        case .delivered: return
        case .missing: throw MessageSendError.notDelivered
        case .unknown: throw MessageSendError.unverified
        }
    }

    private enum DeliveryState {
        case delivered
        /// The conversation was read and the message is not in it.
        case missing
        /// The conversation could not be read.
        case unknown
    }

    private func deliveryState(of pending: PendingSend) async throws -> DeliveryState {
        var state = DeliveryState.unknown
        for attempt in 0..<2 {
            if attempt > 0 { await pauseBeforeRecheck() }
            switch try await readConversation(recipient: pending.recipient, threadID: pending.threadID) {
            case .unreadable:
                continue
            case .notStarted:
                state = .missing
            case .messages(let after):
                if MessageDeliveryPolicy.isDelivered(
                    sent: pending.text,
                    before: pending.conversationBefore,
                    after: after
                ) { return .delivered }
                state = .missing
            }
        }
        return state
    }

    private enum ConversationRead {
        case messages([Message])
        /// The inbox lists conversations, none of them with the recipient.
        case notStarted
        case unreadable
    }

    /// The conversation with the recipient as the server shows it now.
    private func readConversation(recipient: String, threadID: String?) async throws -> ConversationRead {
        let threadPage: String
        if let threadID = threadID?.trimmingCharacters(in: .whitespacesAndNewlines), !threadID.isEmpty {
            threadPage = threadID
        } else {
            guard let inbox = try await readPage(.messages(page: nil)) else { return .unreadable }
            let threads = MessageParser.parseThreadList(html: inbox)
            guard !threads.isEmpty else { return .unreadable }
            guard let thread = MessageDeliveryPolicy.thread(for: recipient, in: threads) else { return .notStarted }
            threadPage = thread.link
        }
        guard let html = try await readPage(.messageThread(id: threadPage)) else { return .unreadable }
        let messages = MessageContentParser.parse(html: html)
        return messages.isEmpty ? .unreadable : .messages(messages)
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

    private struct FormPage {
        let form: MessageForm?
        let pageToken: String?
        /// The conversation as it was before the send, when the page shows it.
        let conversation: [Message]?
    }

    /// Loads the page that renders the matching message form so the send
    /// carries a token issued for the current session, not a cached one. A
    /// reply's page is also the conversation as it was before the send.
    private func freshForm(recipient: String, threadID: String?) async throws -> FormPage {
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
                return FormPage(form: form, pageToken: form.token, conversation: conversation)
            }
            pageToken = pageToken ?? MessageSendPolicy.usableToken(auth.csrfToken)
        }
        return FormPage(form: nil, pageToken: pageToken, conversation: conversation)
    }
}
