import XCTest
@testable import EksilikApp

@MainActor
final class MessageComposeViewModelTests: XCTestCase {
    func testSuccessfulSendForwardsNormalizedPayloadAndCSRF() async {
        let sender = MessageSenderSpy()
        let viewModel = MessageComposeViewModel(
            recipient: " altere ses ",
            subject: " #501 ",
            sender: sender
        )
        viewModel.messageText = " merhaba "

        await viewModel.send(csrfToken: "token-123")

        XCTAssertTrue(viewModel.didSend)
        XCTAssertEqual(viewModel.sendGeneration, 1)
        XCTAssertTrue(viewModel.messageText.isEmpty)
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(sender.calls.count, 1)
        XCTAssertEqual(sender.calls.first?.recipient, "altere ses")
        XCTAssertEqual(sender.calls.first?.subject, "#501")
        XCTAssertEqual(sender.calls.first?.body, "merhaba")
        XCTAssertNil(sender.calls.first?.threadID)
        XCTAssertEqual(sender.calls.first?.csrfToken, "token-123")
    }

    func testFailedSendKeepsDraftAndSurfacesError() async {
        let sender = MessageSenderSpy(error: MessageSenderSpy.Failure.rejected)
        let viewModel = MessageComposeViewModel(recipient: "altere ses", subject: "", sender: sender)
        viewModel.messageText = "silinmemesi gereken taslak"

        await viewModel.send(csrfToken: nil)

        XCTAssertFalse(viewModel.didSend)
        XCTAssertEqual(viewModel.sendGeneration, 0)
        XCTAssertFalse(viewModel.isSending)
        XCTAssertEqual(viewModel.messageText, "silinmemesi gereken taslak")
        XCTAssertNotNil(viewModel.error)
    }
}

private final class MessageSenderSpy: MessageSending {
    enum Failure: Error { case rejected }

    struct Call {
        let recipient: String
        let subject: String
        let body: String
        let threadID: String?
        let csrfToken: String?
    }

    var calls: [Call] = []
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func sendMessage(
        recipient: String,
        subject: String,
        body: String,
        threadID: String?,
        csrfToken: String?
    ) async throws {
        if let error { throw error }
        calls.append(Call(
            recipient: recipient,
            subject: subject,
            body: body,
            threadID: threadID,
            csrfToken: csrfToken
        ))
    }
}
