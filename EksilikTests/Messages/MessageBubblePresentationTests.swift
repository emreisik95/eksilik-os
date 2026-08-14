import XCTest
@testable import EksilikApp

final class MessageBubblePresentationTests: XCTestCase {
    func testExplicitMessageDirectionControlsBubbleSide() {
        XCTAssertEqual(
            MessageBubblePresentation.side(
                direction: .incoming,
                sender: "altere ses",
                currentUsername: "sherlockun besinci sezonu"
            ),
            .leading
        )
        XCTAssertEqual(
            MessageBubblePresentation.side(
                direction: .outgoing,
                sender: "sherlockun besinci sezonu",
                currentUsername: "sherlockun besinci sezonu"
            ),
            .trailing
        )
    }

    func testLegacyUnknownDirectionUsesTheAuthenticatedSenderAsFallback() {
        XCTAssertEqual(
            MessageBubblePresentation.side(
                direction: .unknown,
                sender: " sherlockun besinci sezonu ",
                currentUsername: "sherlockun besinci sezonu"
            ),
            .trailing
        )
        XCTAssertEqual(
            MessageBubblePresentation.side(
                direction: .unknown,
                sender: "altere ses",
                currentUsername: "sherlockun besinci sezonu"
            ),
            .leading
        )
    }
}
