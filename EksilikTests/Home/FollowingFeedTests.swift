import XCTest
@testable import EksilikApp

final class FollowingFeedTests: XCTestCase {
    func testFeedOffersWrittenAndFavoritedSectionsInThatOrder() {
        XCTAssertEqual(FollowingFeedSection.allCases, [.written, .favorited])
        XCTAssertEqual(FollowingFeedSection.allCases.map(\.title), ["yazdıkları", "favladıkları"])
    }

    func testWrittenSectionUsesEmptyActivityCopy() {
        XCTAssertEqual(FollowingFeedSection.written.emptyMessage, "yok bişii pek")
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

    func testFollowingMobileRequestsDoNotSendAjaxHeaderThatTriggersServerError() throws {
        let written = try EksiRouter.buildRequest(for: .followingPage(page: 1))
        let favorited = try EksiRouter.buildRequest(for: .followingFavorites(page: 1))

        XCTAssertNil(written.value(forHTTPHeaderField: "X-Requested-With"))
        XCTAssertNil(favorited.value(forHTTPHeaderField: "X-Requested-With"))
    }

    func testRegularRequestsKeepAjaxHeader() throws {
        let request = try EksiRouter.buildRequest(for: .popular)

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "X-Requested-With"),
            "XMLHttpRequest"
        )
    }

    func testActivityParserSeparatesCurrentFeedTitleAndAuthorDetail() {
        let html = """
        <ul class="topic-list partial">
            <li>
                <a href="/entry/46297732">
                    pokemon
                    <div class="detail">altere ses</div>
                </a>
            </li>
        </ul>
        """

        let topics = TopicListParser.parseActivityFeed(html: html, page: 1)

        XCTAssertEqual(topics.count, 1)
        XCTAssertEqual(topics[0].title, "pokemon")
        XCTAssertEqual(topics[0].entryCount, "altere ses")
        XCTAssertEqual(topics[0].link, "/entry/46297732")
    }

    func testActivityParserIgnoresNavigationAndFooterLinksWhenWrittenFeedIsEmpty() {
        let html = """
        <section id="content-body">
            <nav>
                <ul>
                    <li><a href="/basliklar/takipentrymobile">yazdıkları</a></li>
                    <li><a href="/basliklar/takipfavmobile">favladıkları</a></li>
                </ul>
            </nav>
            <p>yok bişii pek</p>
            <footer>
                <ul>
                    <li><a href="/iletisim">iletişim</a></li>
                    <li><a href="/seffaflik">şeffaflık raporları</a></li>
                </ul>
            </footer>
        </section>
        """

        let topics = TopicListParser.parseActivityFeed(html: html, page: 1)

        XCTAssertTrue(topics.isEmpty)
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
