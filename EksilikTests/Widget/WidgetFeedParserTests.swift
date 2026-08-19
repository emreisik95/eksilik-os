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

    func testTopicParserDecodesApostropheEntityVariants() {
        let html = """
        <ul class="topic-list">
          <li><a href="/bir--1">türkiye&apos;nin gündemi</a></li>
          <li><a href="/iki--2">izmir&#x27;de akşam</a></li>
          <li><a href="/uc--3">ankara&#8217;da sabah</a></li>
          <li><a href="/dort--4">ekşi&rsquo;de bugün</a></li>
        </ul>
        """

        let titles = WidgetFeedParser.parseTopics(html: html).map(\.title)

        XCTAssertEqual(titles, [
            "türkiye'nin gündemi",
            "izmir'de akşam",
            "ankara’da sabah",
            "ekşi’de bugün",
        ])
    }
}
