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
        } catch {
            XCTFail("empty recipient should be ignored before any request, got \(error)")
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
    private let response: String
    private(set) var fetched: [String] = []
    private(set) var posts: [Post] = []

    init(pages: [String: String], response: String = #"{"Success":true}"#) {
        self.pages = pages
        self.response = response
    }

    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String {
        fetched.append(endpoint.path)
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
