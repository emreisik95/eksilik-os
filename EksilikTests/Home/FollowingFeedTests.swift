import XCTest
@testable import EksilikApp

final class FollowingFeedTests: XCTestCase {
    func testFeedOffersWrittenAndFavoritedSectionsInThatOrder() {
        XCTAssertEqual(FollowingFeedSection.allCases, [.written, .favorited])
        XCTAssertEqual(FollowingFeedSection.allCases.map(\.title), ["yazdıkları", "favladıkları"])
    }

    func testWrittenSectionUsesPagedFollowingEndpoint() {
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 1).path,
            "/basliklar/takip?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 4).path,
            "/basliklar/takip?p=4"
        )
    }

    func testFavoritedSectionUsesPagedBuddyFavoritesEndpoint() {
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: 1).path,
            "/basliklar/badifav?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: 4).path,
            "/basliklar/badifav?p=4"
        )
    }

    func testFollowingEndpointsClampInvalidPages() {
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 0).path,
            "/basliklar/takip?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: -2).path,
            "/basliklar/badifav?p=1"
        )
    }
}
