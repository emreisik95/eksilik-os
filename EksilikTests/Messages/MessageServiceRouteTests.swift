import XCTest
@testable import EksilikApp

/// A send the server fails on: whether another route is tried depends on
/// what the conversation shows afterwards.
final class MessageServiceRouteTests: XCTestCase {
    private typealias Page = MessagePageFixture
    func testServerFailureTriesTheOtherRouteOnceTheConversationLacksTheMessage() async throws {
        let transport = MessageTransportSpy(pages: ["/mesaj/9": Self.replyPage], failures: ["/mesaj/yolla": 500])
        var pauses = 0
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: { pauses += 1 })

        try await service.sendMessage(recipient: "altere ses", subject: "", body: "yeni", threadID: "9", csrfToken: nil)

        XCTAssertEqual(transport.posts.map(\.path), ["/mesaj/yolla", "/mesaj/sendajax"])
        XCTAssertEqual(transport.posts.map(\.isAjax), [false, true])
        XCTAssertEqual(transport.posts.last?.body, ["To": "altere ses", "Message": "yeni"])
        XCTAssertEqual(transport.posts.last?.token, "t")
        XCTAssertEqual(transport.fetched, ["/mesaj/9", "/mesaj/9", "/mesaj/9"])
        XCTAssertEqual(pauses, 1)
    }

    func testServerFailureAfterTheMessageWasStoredIsNotSentAgain() async throws {
        let stored = Page.loggedInNav + Page.thread([("eski", "incoming"), ("yeni", "outgoing")])
        let transport = MessageTransportSpy(
            pages: [:],
            sequences: ["/mesaj/9": [Self.replyPage, stored]],
            failures: ["/mesaj/yolla": 500]
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        try await service.sendMessage(recipient: "a", subject: "", body: "yeni", threadID: "9", csrfToken: nil)

        XCTAssertEqual(transport.posts.map(\.path), ["/mesaj/yolla"])
    }

    func testServerFailureOnEveryRouteKeepsTheDraftAndSaysSo() async {
        let transport = MessageTransportSpy(
            pages: ["/mesaj/9": Self.replyPage],
            failures: ["/mesaj/yolla": 500, "/mesaj/sendajax": 500]
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "yeni", threadID: "9", csrfToken: nil)
            XCTFail("a send the server failed on must not look sent")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .serverFailed(statusCode: 500))
            XCTAssertTrue(error.localizedDescription.contains("taslağın duruyor"))
        }
        XCTAssertEqual(transport.posts.map(\.path), ["/mesaj/yolla", "/mesaj/sendajax"])
    }

    func testServerFailureWithAnUnreadableConversationIsNotSentAgain() async {
        let transport = MessageTransportSpy(
            pages: [:],
            sequences: ["/mesaj/9": [Page.loggedInNav + Page.replyFormWithThread]],
            failures: ["/mesaj/yolla": 500],
            exhaustedSequencesFail: true
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        do {
            try await service.sendMessage(recipient: "a", subject: "", body: "b", threadID: "9", csrfToken: nil)
            XCTFail("a send that may have been stored must not be repeated or look sent")
        } catch {
            XCTAssertEqual(error as? MessageSendError, .unverified)
        }
        XCTAssertEqual(transport.posts.count, 1)
    }

    func testNewMessageServerFailureTriesTheOtherRouteWhenNoConversationExistsYet() async throws {
        let inbox = Page.loggedInNav + """
        <ul id="threads">
          <li><article><a href="/mesaj/baska"><h2><span class="username">başka</span></h2></a></article></li>
        </ul>
        """
        let transport = MessageTransportSpy(
            pages: ["/mesaj": inbox + Page.newMessageForm],
            failures: ["/mesaj/sendajax": 500]
        )
        let service = MessageService(transport: transport, observePage: { _ in }, pauseBeforeRecheck: {})

        try await service.sendMessage(recipient: "altere ses", subject: "", body: "ilk", threadID: nil, csrfToken: nil)

        XCTAssertEqual(transport.posts.map(\.path), ["/mesaj/sendajax", "/mesaj/yolla"])
        XCTAssertEqual(transport.posts.map(\.isAjax), [true, false])
        XCTAssertEqual(transport.posts.last?.body, ["To": "altere ses", "Message": "ilk"])
        XCTAssertEqual(transport.fetched, ["/mesaj", "/mesaj", "/mesaj"])
    }

    /// A conversation holding one earlier message, with its reply form.
    private static let replyPage = Page.loggedInNav + Page.thread([("eski", "incoming")]) + Page.replyFormWithThread
}
