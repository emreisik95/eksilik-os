import XCTest
@testable import EksilikApp

final class MessageServiceSendTests: XCTestCase {
    private let loggedInNav = #"<li class="buddy mobile-only"><a href="/biri/ben" title="ben">ben</a></li>"#

    func testReplyFetchesFreshThreadTokenInsteadOfStaleCache() async throws {
        let transport = MessageTransportSpy(pages: [
            "/mesaj/altere-ses": loggedInNav + """
            <form id="message-send-form" action="/mesaj/yolla" method="post">
              <input type="hidden" name="__RequestVerificationToken" value="fresh" />
              <input type="hidden" name="ThreadId" value="2541826" />
            </form>
            """,
        ])
        var observed: [String] = []
        let service = MessageService(transport: transport) { observed.append($0) }

        try await service.sendMessage(
            recipient: "altere ses",
            subject: "",
            body: "merhaba",
            threadID: "altere-ses",
            csrfToken: "stale"
        )

        XCTAssertEqual(transport.fetched, ["/mesaj/altere-ses"])
        XCTAssertEqual(observed.count, 1)
        XCTAssertEqual(transport.posts.count, 1)
        XCTAssertEqual(transport.posts.first?.path, "/mesaj/yolla")
        XCTAssertEqual(transport.posts.first?.token, "fresh")
        XCTAssertEqual(transport.posts.first?.body["ThreadId"], "2541826")
        XCTAssertEqual(transport.posts.first?.body["Message"], "merhaba")
    }

    func testNewMessageFallsBackToProfileTokenWhenInboxHasNone() async throws {
        let transport = MessageTransportSpy(pages: [
            "/mesaj": loggedInNav + "<ul id=\"threads\"></ul>",
            "/biri/altere%20ses": loggedInNav + """
            <form id="entry-form"><input type="hidden" name="__RequestVerificationToken" value="profile" /></form>
            """,
        ])
        let service = MessageService(transport: transport) { _ in }

        try await service.sendMessage(
            recipient: "altere ses",
            subject: "#501",
            body: "selam",
            threadID: nil,
            csrfToken: nil
        )

        XCTAssertEqual(transport.fetched, ["/mesaj", "/biri/altere%20ses"])
        XCTAssertEqual(transport.posts.first?.path, "/mesaj/sendajax")
        XCTAssertEqual(transport.posts.first?.token, "profile")
        XCTAssertEqual(transport.posts.first?.body, ["To": "altere ses", "Message": "(#501) selam"])
    }

    func testUnreachableFormPagesFallBackToCachedToken() async throws {
        let transport = MessageTransportSpy(pages: [:])
        let service = MessageService(transport: transport) { _ in }

        try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: nil, csrfToken: "cached")

        XCTAssertEqual(transport.posts.first?.token, "cached")
    }

    func testMissingTokenEverywhereThrowsActionableError() async {
        let transport = MessageTransportSpy(pages: ["/mesaj": loggedInNav])
        let service = MessageService(transport: transport) { _ in }

        do {
            try await service.sendMessage(recipient: "", subject: "", body: "b", threadID: nil, csrfToken: nil)
            XCTFail("an empty recipient must not look like a sent message")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .emptyMessage)
        }
        XCTAssertTrue(transport.fetched.isEmpty)

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: nil, csrfToken: nil)
            XCTFail("send without token must fail")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .missingCSRFToken)
            XCTAssertTrue(error.localizedDescription.contains("giriş"))
        }
        XCTAssertTrue(transport.posts.isEmpty)
    }

    func testSignedOutFormPageStopsBeforePosting() async {
        let transport = MessageTransportSpy(pages: [
            "/mesaj/9": #"<a id="top-login-link" href="/giris">giriş</a>"#,
        ])
        let service = MessageService(transport: transport) { _ in }

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: "cached")
            XCTFail("signed out sessions must not post")
        } catch {
            XCTAssertTrue(Self.isUnauthorized(error), "unexpected error \(error)")
        }
        XCTAssertTrue(transport.posts.isEmpty)
    }

    func testServerRejectionSurfacesItsReason() async {
        let transport = MessageTransportSpy(
            pages: ["/mesaj/9": loggedInNav + Self.replyForm],
            response: #"{"Success":false,"Message":"mesaj kutusu dolu"}"#
        )
        let service = MessageService(transport: transport) { _ in }

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: nil)
            XCTFail("rejected sends must throw")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .rejected(reason: "mesaj kutusu dolu"))
            XCTAssertEqual(error.localizedDescription, "mesaj kutusu dolu")
        }
    }

    func testLoginPageResponseIsReportedAsSignedOut() async {
        let transport = MessageTransportSpy(
            pages: ["/mesaj/9": loggedInNav + Self.replyForm],
            response: #"<a id="top-login-link" href="/giris">giriş</a>"#
        )
        let service = MessageService(transport: transport) { _ in }

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: nil)
            XCTFail("login page responses must throw")
        } catch {
            XCTAssertTrue(Self.isUnauthorized(error), "unexpected error \(error)")
        }
    }

    func testUnconfirmedReplyIsReadBackFromTheConversation() async throws {
        let earlier: [(text: String, direction: String)] = [("tamam", "outgoing"), ("selam", "incoming")]
        let transport = MessageTransportSpy(
            pages: [:],
            sequences: [
                "/mesaj/altere-ses": [
                    loggedInNav + Self.thread(earlier) + Self.replyFormWithThread,
                    loggedInNav + Self.thread(earlier + [("merhaba", "outgoing")]),
                ],
            ],
            response: ""
        )
        var pauses = 0
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: { pauses += 1 })

        try await service.sendMessage(
            recipient: "altere ses",
            subject: "",
            body: "merhaba",
            threadID: "altere-ses",
            csrfToken: nil
        )

        XCTAssertEqual(transport.fetched, ["/mesaj/altere-ses", "/mesaj/altere-ses"])
        XCTAssertEqual(pauses, 0)
        XCTAssertEqual(transport.posts.first?.body["ThreadId"], "2541826")
    }

    func testResponsePageShowingTheMessageNeedsNoExtraRead() async throws {
        let transport = MessageTransportSpy(
            pages: ["/mesaj/9": loggedInNav + Self.thread([("eski", "incoming")]) + Self.replyFormWithThread],
            response: loggedInNav + Self.thread([("eski", "incoming"), ("yeni", "outgoing")])
        )
        let service = MessageService(transport: transport) { _ in }

        try await service.sendMessage(recipient: "a", subject: "", body: "yeni", threadID: "9", csrfToken: nil)

        XCTAssertEqual(transport.fetched, ["/mesaj/9"])
    }

    func testReplyMissingFromConversationIsReportedAsNotSent() async {
        let conversation = Self.thread([("merhaba", "outgoing"), ("selam", "incoming")])
        let page = loggedInNav + conversation + Self.replyFormWithThread
        let transport = MessageTransportSpy(pages: ["/mesaj/9": page], response: loggedInNav + "<div>ok</div>")
        var pauses = 0
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: { pauses += 1 })

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "merhaba", threadID: "9", csrfToken: nil)
            XCTFail("a reply the conversation does not show must not look sent")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .notDelivered)
            XCTAssertTrue(error.localizedDescription.contains("taslağın duruyor"))
        }
        XCTAssertEqual(transport.fetched, ["/mesaj/9", "/mesaj/9", "/mesaj/9"])
        XCTAssertEqual(pauses, 1)
    }

    func testUnreadableConversationIsReportedAsUnverified() async {
        let transport = MessageTransportSpy(
            pages: [:],
            sequences: ["/mesaj/9": [loggedInNav + Self.replyFormWithThread]],
            response: "",
            exhaustedSequencesFail: true
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: nil)
            XCTFail("an unreadable conversation must not look sent")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .unverified)
        }
    }

    func testUnconfirmedNewMessageIsFoundThroughTheInbox() async throws {
        let inbox = loggedInNav + """
        <ul id="threads">
          <li><article><a href="/mesaj/baska"><h2><span class="username">başka</span></h2></a></article></li>
          <li><article><a href="/mesaj/altere-ses"><h2><span class="username">altere ses</span></h2></a></article></li>
        </ul>
        """
        let transport = MessageTransportSpy(
            pages: [
                "/mesaj": inbox + Self.newMessageForm,
                "/mesaj/altere-ses": loggedInNav + Self.thread([("ilk mesaj", "outgoing")]),
            ],
            response: ""
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        try await service.sendMessage(
            recipient: "altere ses",
            subject: "",
            body: "ilk mesaj",
            threadID: nil,
            csrfToken: nil
        )

        XCTAssertEqual(transport.fetched, ["/mesaj", "/mesaj", "/mesaj/altere-ses"])
        XCTAssertEqual(transport.posts.first?.path, "/mesaj/sendajax")
        XCTAssertEqual(transport.posts.first?.body, ["To": "altere ses", "Message": "ilk mesaj"])
    }

    func testRenderedValidationErrorIsShownToTheUser() async {
        let transport = MessageTransportSpy(
            pages: ["/mesaj/9": loggedInNav + Self.replyFormWithThread],
            response: loggedInNav + #"<div class="validation-summary-errors"><ul><li>mesaj çok uzun</li></ul></div>"#
        )
        let service = MessageService(transport: transport) { _ in }

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: nil)
            XCTFail("validation errors must throw")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .rejected(reason: "mesaj çok uzun"))
        }
        XCTAssertEqual(transport.fetched, ["/mesaj/9"])
    }

    private static func thread(_ messages: [(text: String, direction: String)]) -> String {
        let articles = messages
            .map { #"<article class="\#($0.direction)"><p>\#($0.text)</p></article>"# }
            .joined()
        return #"<section id="message-thread">"# + articles + "</section>"
    }

    private static let replyFormWithThread = """
    <form id="message-send-form" action="/mesaj/yolla" method="post">
      <input type="hidden" name="__RequestVerificationToken" value="t" />
      <input type="hidden" name="ThreadId" value="2541826" />
      <textarea name="Message"></textarea>
    </form>
    """

    private static let newMessageForm = """
    <form id="message-send-form" action="/mesaj/sendajax" method="post">
      <input type="hidden" name="__RequestVerificationToken" value="t" />
      <input type="text" name="To" />
      <textarea name="Message"></textarea>
    </form>
    """

    private static func isUnauthorized(_ error: Error) -> Bool {
        guard case NetworkError.unauthorized = error else { return false }
        return true
    }

    private static let replyForm = """
    <form action="/mesaj/yolla"><input type="hidden" name="__RequestVerificationToken" value="t" /></form>
    """
}

private final class MessageTransportSpy: MessageTransport {
    struct Post {
        let path: String
        let body: [String: String]
        let token: String?
    }

    private let pages: [String: String]
    /// Pages that change between reads, served in order; the last one repeats
    /// unless `exhaustedSequencesFail` is set.
    private var sequences: [String: [String]]
    private let exhaustedSequencesFail: Bool
    private let response: String
    private(set) var fetched: [String] = []
    private(set) var posts: [Post] = []

    init(
        pages: [String: String],
        sequences: [String: [String]] = [:],
        response: String = #"{"Success":true}"#,
        exhaustedSequencesFail: Bool = false
    ) {
        self.pages = pages
        self.sequences = sequences
        self.exhaustedSequencesFail = exhaustedSequencesFail
        self.response = response
    }

    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String {
        fetched.append(endpoint.path)
        if let sequence = sequences[endpoint.path] {
            guard let html = sequence.first else { throw NetworkError.cloudflareBlocked }
            if sequence.count > 1 || exhaustedSequencesFail {
                sequences[endpoint.path] = Array(sequence.dropFirst())
            }
            return html
        }
        guard let html = pages[endpoint.path] else { throw NetworkError.cloudflareBlocked }
        return html
    }

    func post(
        endpoint: EksiEndpoint,
        body: [String: String],
        csrfToken: String?
    ) async throws -> (Data, HTTPURLResponse) {
        posts.append(Post(path: endpoint.path, body: body, token: csrfToken))
        let url = try XCTUnwrap(URL(string: "https://eksisozluk.com" + endpoint.path))
        let http = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (Data(response.utf8), http)
    }
}
