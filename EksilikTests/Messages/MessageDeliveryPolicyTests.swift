import XCTest
@testable import EksilikApp

final class MessageDeliveryPolicyTests: XCTestCase {
    func testMatchesTextAsTheServerRendersIt() {
        XCTAssertTrue(MessageDeliveryPolicy.matches(sent: "selam,\n\nnasılsın?", text: "selam, nasılsın?"))
        XCTAssertTrue(MessageDeliveryPolicy.matches(sent: "İSTANBUL'da mıyız", text: "istanbul'da mıyız"))
        XCTAssertTrue(MessageDeliveryPolicy.matches(sent: "(#501) selam", text: "(#501) selam"))
        XCTAssertTrue(MessageDeliveryPolicy.matches(
            sent: "bak https://eksisozluk.com/entry/123 ne diyor",
            text: "bak eksisozluk.com/entry/123 ne diyor"
        ))
        XCTAssertTrue(MessageDeliveryPolicy.matches(sent: "🙂", text: "🙂"))
        XCTAssertFalse(MessageDeliveryPolicy.matches(sent: "🙂", text: "😐"))
        XCTAssertFalse(MessageDeliveryPolicy.matches(sent: "yarın görüşürüz", text: "bugün görüşemeyiz"))
        XCTAssertFalse(MessageDeliveryPolicy.matches(sent: "  ", text: "selam"))
    }

    func testOnlyMessagesThatAppearedAfterTheSendCount() {
        let before = [message("tamam", .outgoing), message("görüşürüz", .incoming)]

        XCTAssertFalse(MessageDeliveryPolicy.isDelivered(sent: "tamam", before: before, after: before))
        XCTAssertTrue(MessageDeliveryPolicy.isDelivered(
            sent: "tamam",
            before: before,
            after: before + [message("tamam", .outgoing)]
        ))
        XCTAssertTrue(MessageDeliveryPolicy.isDelivered(
            sent: "yeni mesaj",
            before: before,
            after: [message("yeni mesaj", .unknown)] + before
        ))
        XCTAssertFalse(MessageDeliveryPolicy.isDelivered(
            sent: "yeni mesaj",
            before: before,
            after: before + [message("yeni mesaj", .incoming)]
        ))
    }

    func testWithoutEarlierStateTheNewestMessagesAtEitherEndCount() {
        let older = (0..<12).map { message("eski \($0)", .outgoing) }

        XCTAssertTrue(MessageDeliveryPolicy.isDelivered(
            sent: "son mesaj",
            before: nil,
            after: older + [message("son mesaj", .outgoing)]
        ))
        XCTAssertTrue(MessageDeliveryPolicy.isDelivered(
            sent: "son mesaj",
            before: nil,
            after: [message("son mesaj", .outgoing)] + older
        ))
        XCTAssertFalse(MessageDeliveryPolicy.isDelivered(
            sent: "son mesaj",
            before: nil,
            after: Array(older[..<6]) + [message("son mesaj", .outgoing)] + Array(older[6...])
        ))
        XCTAssertFalse(MessageDeliveryPolicy.isDelivered(sent: "son mesaj", before: nil, after: []))
    }

    func testFindsTheRecipientsConversationBySpellingOrLink() {
        let threads = [
            thread(username: "başka biri", link: "baska-biri"),
            thread(username: "Altere Ses", link: "1234"),
            thread(username: "nick", link: "ssg-ii"),
        ]

        XCTAssertEqual(MessageDeliveryPolicy.thread(for: "altere ses", in: threads)?.link, "1234")
        XCTAssertEqual(MessageDeliveryPolicy.thread(for: " altere-ses ", in: threads)?.link, "1234")
        XCTAssertEqual(MessageDeliveryPolicy.thread(for: "ssg ii", in: threads)?.link, "ssg-ii")
        XCTAssertNil(MessageDeliveryPolicy.thread(for: "kimse", in: threads))
        XCTAssertNil(MessageDeliveryPolicy.thread(for: " ", in: threads))
    }

    private func message(_ text: String, _ direction: MessageDirection) -> Message {
        Message(id: UUID().uuidString, contentHTML: text, contentText: text, sender: "", date: "", direction: direction)
    }

    private func thread(username: String, link: String) -> MessageThread {
        MessageThread(id: link, username: username, preview: "", date: "", messageCount: "", link: link, isUnread: false)
    }
}
