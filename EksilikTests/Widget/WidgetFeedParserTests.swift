import XCTest
@testable import EksilikApp

final class WidgetFeedParserTests: XCTestCase {
    func testTopicParserExtractsTitleCountAndLink() {
        let html = """
        <ul class="topic-list partial">
          <li><a href="/swiftui-ve-hayat--42">swiftui ve hayat <small>18</small></a></li>
          <li><a href="/ikinci-baslik--43">ikinci başlık</a></li>
        </ul>
        """

        let items = WidgetFeedParser.parseTopics(html: html)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0], WidgetFeedItem(title: "swiftui ve hayat", subtitle: nil, metadata: "18", link: "/swiftui-ve-hayat--42"))
        XCTAssertEqual(items[1].title, "ikinci başlık")
    }

    func testDebeParserCreatesDirectEntryLinks() {
        let html = """
        <ul>
          <li><a href="/entry/185088056?debe=true"><span class="caption">gecenin entrysi</span></a></li>
        </ul>
        """

        let items = WidgetFeedParser.parseDebe(html: html)

        XCTAssertEqual(items, [WidgetFeedItem(title: "gecenin entrysi", subtitle: "debe", metadata: nil, link: "/entry/185088056")])
    }

    func testParserRejectsMarkupWithoutFeedRows() {
        XCTAssertTrue(WidgetFeedParser.parseTopics(html: "<html><body>giriş yap</body></html>").isEmpty)
        XCTAssertTrue(WidgetFeedParser.parseDebe(html: "<html></html>").isEmpty)
    }
}
