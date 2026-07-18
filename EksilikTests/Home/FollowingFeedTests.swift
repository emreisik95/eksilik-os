import XCTest
@testable import EksilikApp

final class FollowingFeedTests: XCTestCase {
    func testFeedOffersWrittenAndFavoritedSectionsInThatOrder() {
        XCTAssertEqual(FollowingFeedSection.allCases, [.written, .favorited])
        XCTAssertEqual(FollowingFeedSection.allCases.map(\.title), ["yazdıkları", "favladıkları"])
    }

    func testWrittenSectionUsesPagedMobileFollowingEndpoint() {
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 1).path,
            "/basliklar/takipentrymobile?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 4).path,
            "/basliklar/takipentrymobile?p=4"
        )
    }

    func testFavoritedSectionUsesPagedMobileFollowingFavoritesEndpoint() {
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: 1).path,
            "/basliklar/takipfavmobile?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: 4).path,
            "/basliklar/takipfavmobile?p=4"
        )
    }

    func testFollowingEndpointsClampInvalidPages() {
        XCTAssertEqual(
            FollowingFeedSection.written.endpoint(page: 0).path,
            "/basliklar/takipentrymobile?p=1"
        )
        XCTAssertEqual(
            FollowingFeedSection.favorited.endpoint(page: -2).path,
            "/basliklar/takipfavmobile?p=1"
        )
    }

    func testActivityParserPreservesRepeatedTopicsAsSeparateRows() {
        let html = """
        <ul class="topic-list partial">
            <li><a href="/fatih-kadir-akin--42">fatih kadir akın<small>altere ses</small></a></li>
            <li><a href="/fatih-kadir-akin--42">fatih kadir akın<small>res publica non dominetur</small></a></li>
        </ul>
        """

        let topics = TopicListParser.parseActivityFeed(html: html, page: 1)

        XCTAssertEqual(topics.count, 2)
        XCTAssertEqual(topics.map(\.link), ["/fatih-kadir-akin--42", "/fatih-kadir-akin--42"])
        XCTAssertEqual(Set(topics.map(\.id)).count, 2)
        XCTAssertEqual(topics.map(\.entryCount), ["altere ses", "res publica non dominetur"])
    }
}
