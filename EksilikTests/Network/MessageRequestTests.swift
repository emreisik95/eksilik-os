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
}
