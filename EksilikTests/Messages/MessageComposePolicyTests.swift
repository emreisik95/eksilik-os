import XCTest
@testable import EksilikApp

final class MessageComposePolicyTests: XCTestCase {
    func testPayloadTrimsAddressesAndRejectsMissingRequiredFields() {
        XCTAssertEqual(
            MessageComposePolicy.payload(
                recipient: "  altere ses  ",
                subject: "  #123  ",
                body: "  merhaba  "
            ),
            ["To": "altere ses", "Message": "(#123) merhaba"]
        )
        XCTAssertNil(MessageComposePolicy.payload(recipient: "", subject: "", body: "merhaba"))
        XCTAssertNil(MessageComposePolicy.payload(recipient: "altere ses", subject: "", body: " \n "))
    }

    func testSendAvailabilityPreventsDuplicateSubmission() {
        XCTAssertTrue(MessageComposePolicy.canSend(recipient: "altere ses", body: "merhaba", isSending: false))
        XCTAssertFalse(MessageComposePolicy.canSend(recipient: "altere ses", body: "merhaba", isSending: true))
        XCTAssertFalse(MessageComposePolicy.canSend(recipient: "", body: "merhaba", isSending: false))
    }

    func testReplyPayloadPreservesTheServerThreadContract() {
        XCTAssertEqual(
            MessageComposePolicy.payload(
                recipient: "ayatasagun",
                subject: "",
                body: "yanıt",
                threadID: "2541826"
            ),
            [
                "To": "ayatasagun",
                "Message": "yanıt",
                "ThreadId": "2541826",
                "IsReply": "True",
            ]
        )
    }
}
