import XCTest
@testable import EksilikApp

final class MessageRequestTests: XCTestCase {
    func testMessageDocumentsOmitAjaxHeader() {
        XCTAssertTrue(EksiEndpoint.messages(page: nil).omitsAjaxHeader)
        XCTAssertTrue(EksiEndpoint.messages(page: 3).omitsAjaxHeader)
        XCTAssertTrue(EksiEndpoint.messageThread(id: "2541826").omitsAjaxHeader)
    }

    func testMessageSendRemainsAPostRequest() {
        XCTAssertEqual(EksiEndpoint.sendMessage.method, .post)
        XCTAssertFalse(EksiEndpoint.sendMessage.omitsAjaxHeader)
    }

    func testNewMessageUsesTheDedicatedAjaxEndpoint() {
        XCTAssertEqual(EksiEndpoint.sendMessage.path, "/mesaj/sendajax")
    }

    func testReplyUsesTheConversationEndpoint() {
        XCTAssertEqual(EksiEndpoint.replyMessage.method, .post)
        XCTAssertEqual(EksiEndpoint.replyMessage.path, "/mesaj/yolla")
    }

    func testMessageFormPostsAreSentAsDocumentRequests() throws {
        let body = ["To": "altere ses", "Message": "selam"]
        let reply = try EksiRouter.buildRequest(for: .replyMessage, body: body, csrfToken: "t")
        let form = try EksiRouter.buildRequest(
            for: .submitMessageForm(path: "/mesaj/gonder"),
            body: body,
            csrfToken: "t"
        )
        let ajax = try EksiRouter.buildRequest(for: .sendMessage, body: body, csrfToken: "t")

        XCTAssertNil(reply.value(forHTTPHeaderField: "X-Requested-With"))
        XCTAssertNil(form.value(forHTTPHeaderField: "X-Requested-With"))
        XCTAssertEqual(ajax.value(forHTTPHeaderField: "X-Requested-With"), "XMLHttpRequest")
        XCTAssertEqual(
            reply.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=utf-8"
        )
        XCTAssertEqual(
            String(data: try XCTUnwrap(reply.httpBody), encoding: .utf8),
            "Message=selam&To=altere%20ses&__RequestVerificationToken=t"
        )
    }

    func testMessageServiceSelectsEndpointFromConversationState() {
        XCTAssertEqual(MessageService.endpoint(for: nil).path, "/mesaj/sendajax")
        XCTAssertEqual(MessageService.endpoint(for: "  ").path, "/mesaj/sendajax")
        XCTAssertEqual(MessageService.endpoint(for: "2541826").path, "/mesaj/yolla")
    }

    func testMessageServiceRequiresANonEmptyCSRFToken() {
        XCTAssertNil(MessageService.usableCSRFToken(nil))
        XCTAssertNil(MessageService.usableCSRFToken("  \n"))
        XCTAssertEqual(MessageService.usableCSRFToken("  token-123  "), "token-123")
    }
}
