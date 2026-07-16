import Foundation

private struct Harness {
    private(set) var failures: [String] = []
    private(set) var checks = 0

    mutating func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        checks += 1
        if !condition() {
            failures.append("\(file):\(line): \(message)")
        }
    }

    mutating func runBaselineParserChecks() {
        let pagination = PaginationParser.parse(
            html: #"<div class="pager" data-currentpage="3" data-pagecount="10"></div>"#
        )
        expect(pagination.currentPage == 3, "pagination should parse current page")
        expect(pagination.totalPages == 10, "pagination should parse total pages")
        expect(pagination.hasNextPage, "page 3 of 10 should have a next page")
        expect(pagination.hasPreviousPage, "page 3 of 10 should have a previous page")

        let topicHTML = """
        <ul class="topic-list partial mobile">
            <li><a href="/test-baslik--12345">test baslik<small>42</small></a></li>
            <li><a href="/diger-baslik--67890">diger baslik<small>7</small></a></li>
        </ul>
        """
        let topics = TopicListParser.parse(html: topicHTML)
        expect(topics.count == 2, "topic list should parse both topics")
        expect(topics.first?.title == "test baslik", "topic title should exclude entry count")
        expect(topics.first?.entryCount == "42", "topic entry count should be preserved")

        let authHTML = """
        <li class="buddy mobile-only"><a href="/biri/testuser">testuser</a></li>
        <li class="not-mobile"><a title="testuser">testuser</a></li>
        <li class="messages mobile-only"><a><svg class="green"></svg></a></li>
        """
        let auth = AuthParser.parseAuthState(html: authHTML)
        expect(auth.isLoggedIn, "buddy navigation should indicate a logged-in session")
        expect(auth.username == "testuser", "username should be parsed")
        expect(auth.hasUnreadMessages, "green message icon should indicate unread messages")

        let entryHTML = """
        <h1 id="title" data-title="test" data-slug="test" data-id="1"></h1>
        <ul id="entry-item-list">
            <li data-favorite-count="5" data-isfavorite="true" data-author="yazar1" data-author-id="100"></li>
        </ul>
        <div class="content"><p>entry content</p></div>
        <a class="entry-date permalink" href="/entry/999">01.01.2024</a>
        """
        let entryPage = EntryPageParser.parse(html: entryHTML, currentUsername: nil)
        expect(entryPage.entries.count == 1, "entry page should parse one entry")
        expect(entryPage.entries.first?.id == "999", "entry ID should come from permalink")
        expect(entryPage.entries.first?.author.nick == "yazar1", "entry author should be parsed")
    }

    mutating func runTopicRequestChecks() {
        let today = TopicRequest(link: "/ornek-baslik--42?day=2026-07-16")
        expect(
            today.settingPage(8).pathAndQuery == "ornek-baslik--42?day=2026-07-16&p=8",
            "changing page should preserve today's entry scope"
        )

        let nice = TopicRequest(link: "/ornek-baslik--42?a=nice&period=week&p=2")
        expect(
            nice.settingPage(9).pathAndQuery == "ornek-baslik--42?a=nice&period=week&p=9",
            "changing page should preserve the selected nice period"
        )

        let duplicatePage = TopicRequest(link: "/ornek?p=1&a=search&author=test&p=3")
            .settingPage(4)
            .pathAndQuery
        expect(
            duplicatePage.components(separatedBy: "p=").count - 1 == 1,
            "changing page should remove duplicate page query items"
        )
        expect(duplicatePage.contains("a=search"), "changing page should preserve the search mode")
        expect(duplicatePage.contains("author=test"), "changing page should preserve the author")

        let absolute = TopicRequest(link: "https://eksisozluk.com/ornek--42?a=find&keywords=swift")
        expect(
            absolute.pathAndQuery == "ornek--42?a=find&keywords=swift",
            "absolute links should normalize to a relative request"
        )

        let encoded = today.applying(filter: .author("a&b"))
        expect(
            encoded.pathAndQuery == "ornek-baslik--42?a=search&author=a%26b",
            "filter values should be percent encoded as one query value"
        )

        expect(
            EksiEndpoint.popularPage(page: 3).path == "/basliklar/gundem?p=3",
            "agenda pagination should request the selected page"
        )
    }
}

private var harness = Harness()
harness.runBaselineParserChecks()
harness.runTopicRequestChecks()

if harness.failures.isEmpty {
    print("PASS: \(harness.checks) core checks")
} else {
    for failure in harness.failures {
        fputs("FAIL: \(failure)\n", stderr)
    }
    exit(1)
}
