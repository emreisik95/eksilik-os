import XCTest
@testable import EksilikApp

final class TopicListParserTests: XCTestCase {

    func testParseEmptyHTML() {
        let topics = TopicListParser.parse(html: "")
        XCTAssertTrue(topics.isEmpty)
    }

    func testParseTopicList() {
        let html = """
        <ul class="topic-list partial mobile">
            <li>
                <a href="/test-baslik--12345">
                    test baslik
                    <small>42</small>
                </a>
            </li>
            <li>
                <a href="/diger-baslik--67890">
                    diger baslik
                    <small>7</small>
                </a>
            </li>
        </ul>
        """

        let topics = TopicListParser.parse(html: html)
        XCTAssertEqual(topics.count, 2)
        XCTAssertEqual(topics[0].title, "test baslik")
        XCTAssertEqual(topics[0].entryCount, "42")
        XCTAssertEqual(topics[0].link, "/test-baslik--12345")
        XCTAssertEqual(topics[1].title, "diger baslik")
    }

    func testBlockedTopicsFiltered() {
        let html = """
        <ul class="topic-list partial mobile">
            <li><a href="/good--1">good topic<small>5</small></a></li>
            <li><a href="/bad--2">bad topic<small>3</small></a></li>
        </ul>
        """

        let topics = TopicListParser.parse(html: html, blockedTopics: ["bad topic"])
        XCTAssertEqual(topics.count, 1)
        XCTAssertEqual(topics[0].title, "good topic")
    }
}
