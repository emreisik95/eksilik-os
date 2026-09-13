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
        XCTAssertFalse(EksiEndpoint.replyMessage.omitsAjaxHeader)
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
