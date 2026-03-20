import XCTest
@testable import EksilikApp

final class EntryPageParserTests: XCTestCase {

    func testParseEmptyHTML() {
        let page = EntryPageParser.parse(html: "", currentUsername: nil)
        XCTAssertTrue(page.entries.isEmpty)
        XCTAssertEqual(page.title, "")
    }

    func testParseTopicTitle() {
        let html = """
        <h1 id="title" data-title="test baslik" data-slug="test-baslik" data-id="12345">
            test baslik
        </h1>
        """

        let page = EntryPageParser.parse(html: html, currentUsername: nil)
        XCTAssertEqual(page.title, "test baslik")
        XCTAssertEqual(page.slug, "test-baslik")
        XCTAssertEqual(page.topicId, "12345")
    }

    func testParseEntries() {
        let html = """
        <h1 id="title" data-title="test" data-slug="test" data-id="1"></h1>
        <ul id="entry-item-list">
            <li data-favorite-count="5" data-isfavorite="true" data-author="yazar1" data-author-id="100">
            </li>
        </ul>
        <div class="content"><p>entry content</p></div>
        <a class="entry-date permalink" href="/entry/999">01.01.2024</a>
        """

        let page = EntryPageParser.parse(html: html, currentUsername: nil)
        XCTAssertEqual(page.entries.count, 1)
        XCTAssertEqual(page.entries[0].favoriteCount, 5)
        XCTAssertTrue(page.entries[0].isFavorited)
        XCTAssertEqual(page.entries[0].author.nick, "yazar1")
        XCTAssertEqual(page.entries[0].id, "999")
    }
}
