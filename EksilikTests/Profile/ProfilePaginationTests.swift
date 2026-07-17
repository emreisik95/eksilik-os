import XCTest
@testable import EksilikApp

final class ProfilePaginationTests: XCTestCase {
    func testOrderedUniqueEntriesKeepFirstValue() {
        func entry(_ id: String, content: String) -> UserProfile.ProfileEntry {
            UserProfile.ProfileEntry(
                id: id, topicTitle: "başlık", topicLink: "baslik--1",
                contentHTML: content, author: "yazar", authorId: "1", date: "",
                favoriteCount: 0, isFavorited: false, voteState: .none,
                isPinned: false, imageURLs: []
            )
        }

        let merged = UserProfile.ProfileEntry.orderedUnique([
            entry("1", content: "ilk"),
            entry("2", content: "ikinci"),
            entry("1", content: "tekrar"),
        ])

        XCTAssertEqual(merged.map(\.id), ["1", "2"])
        XCTAssertEqual(merged.first?.contentHTML, "ilk")
    }
}
