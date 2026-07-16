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
        expect(!auth.isIndeterminate, "recognized auth navigation should be determinate")
        expect(
            LoginFlowPolicy.completion(
                for: URL(string: "https://eksisozluk.com/giris")!,
                html: authHTML
            ) == .authenticated(username: "testuser"),
            "an authenticated login page should complete without a root redirect"
        )

        let indeterminateAuth = AuthParser.parseAuthState(html: "<main>entry content</main>")
        expect(indeterminateAuth.isIndeterminate, "pages without auth navigation should not force logout")
        expect(
            LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://eksisozluk.com/?returnUrl=%2F")!),
            "login return URLs with a root path should be recognized"
        )
        expect(
            !LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://eksisozluk.com/giris")!),
            "the login form itself should not be treated as a successful login"
        )
        let authCookie = HTTPCookie(properties: [
            .domain: ".eksisozluk.com",
            .path: "/",
            .name: ".AspNetCore.Cookies",
            .value: "session-token",
        ])!
        expect(LoginFlowPolicy.hasAuthCookie(in: [authCookie]), "login success should require an auth cookie")

        let entryHTML = """
        <h1 id="title" data-title="test" data-slug="test" data-id="1"></h1>
        <ul id="entry-item-list">
            <li data-favorite-count="5" data-isfavorite="true" data-author="yazar1" data-author-id="100"></li>
        </ul>
        <div class="content"><p>entry content</p></div>
        <a class="entry-date permalink" href="/entry/999">01.01.2024</a>
        <a id="track-topic-link" data-tracked="1"></a>
        """
        let entryPage = EntryPageParser.parse(html: entryHTML, currentUsername: nil)
        expect(entryPage.entries.count == 1, "entry page should parse one entry")
        expect(entryPage.entries.first?.id == "999", "entry ID should come from permalink")
        expect(entryPage.entries.first?.author.nick == "yazar1", "entry author should be parsed")
        expect(entryPage.isTracked, "topic tracking state should be parsed")
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
        expect(
            EksiEndpoint.trackTopic(id: "42").path == "/baslik/takip-et/42",
            "tracking a topic should target its topic ID"
        )
        expect(EksiEndpoint.trackTopic(id: "42").method == .post, "topic tracking should use POST")
        expect(
            EksiEndpoint.untrackTopic(id: "42").path == "/baslik/takip-etme/42",
            "untracking a topic should target its topic ID"
        )
        let canonicalPage = TopicRequest(link: "/eski-baslik--42?a=popular")
            .replacingTopic(slug: "yeni-baslik", id: "42")
            .settingPage(105)
        expect(
            canonicalPage.pathAndQuery == "yeni-baslik--42?a=popular&p=105",
            "canonical topic replacement should preserve the topic ID, filter, and requested page"
        )
    }

    mutating func runStableLoadingChecks() {
        let firstPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))
        let secondPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))
        expect(firstPass == secondPass, "skeleton widths should stay stable across renders")
        expect(
            firstPass.allSatisfy { (0.45...0.90).contains($0) },
            "topic skeleton widths should remain within the intended layout"
        )

        let existing = [
            Topic(id: "1", title: "bir", slug: "bir", entryCount: "1", link: "/bir"),
            Topic(id: "2", title: "iki", slug: "iki", entryCount: "2", link: "/iki"),
        ]
        let incoming = [
            Topic(id: "2", title: "iki", slug: "iki", entryCount: "2", link: "/iki"),
            Topic(id: "3", title: "uc", slug: "uc", entryCount: "3", link: "/uc"),
        ]
        let merged = TopicPageMerger.merge(existing: existing, incoming: incoming)
        expect(merged.map(\.id) == ["1", "2", "3"], "page append should keep order and remove duplicate topics")
    }

    mutating func runImageURLChecks() {
        expect(
            ImageURLNormalizer.normalize("//cdn.example.com/photo.jpg")?.absoluteString == "https://cdn.example.com/photo.jpg",
            "protocol-relative image URLs should use HTTPS"
        )
        expect(
            ImageURLNormalizer.normalize("https://cdn.example.com/a.jpg?x=1&amp;y=2")?.absoluteString == "https://cdn.example.com/a.jpg?x=1&y=2",
            "HTML entities should be decoded in image URLs"
        )
        expect(ImageURLNormalizer.isImageURL("https://cdn.example.com/a.webp?size=large"), "query strings should not hide image extensions")
        expect(ImageURLNormalizer.normalize("javascript:alert(1)") == nil, "non-network image URLs should be rejected")

        let html = """
        <a href="https://cdn.example.com/first.png">first</a>
        <img src="//cdn.example.com/second.jpg">
        <a href="https://cdn.example.com/first.png">duplicate</a>
        """
        expect(
            UserProfileParser.extractImageURLs(from: html) == [
                "https://cdn.example.com/first.png",
                "https://cdn.example.com/second.jpg",
            ],
            "extracted images should preserve source order while deduplicating"
        )
    }

    mutating func runOfflinePlanningChecks() async {
        expect(OfflineDownloadPlanner.pages(for: .fivePages, totalPages: 3) == [1, 2, 3], "five-page downloads should clamp to the topic")
        expect(OfflineDownloadPlanner.pages(for: .fivePages, totalPages: 12) == Array(1...5), "five-page downloads should plan five pages")
        expect(OfflineDownloadPlanner.pages(for: .tenPages, totalPages: 12) == Array(1...10), "ten-page downloads should plan ten pages")
        expect(OfflineDownloadPlanner.pages(for: .allPages, totalPages: 12) == Array(1...12), "all-page downloads should plan the full topic")

        let first = OfflineEntry(id: "1", contentHTML: "one", authorNick: "a", authorID: "a", authorAvatarURL: nil, date: "d", favoriteCount: 0, imageURLs: [])
        let replacement = OfflineEntry(id: "1", contentHTML: "new", authorNick: "a", authorID: "a", authorAvatarURL: nil, date: "d", favoriteCount: 0, imageURLs: [])
        let second = OfflineEntry(id: "2", contentHTML: "two", authorNick: "b", authorID: "b", authorAvatarURL: nil, date: "d", favoriteCount: 0, imageURLs: [])
        expect(OfflineEntry.orderedUnique([first, replacement, second]).map(\.id) == ["1", "2"], "offline entries should deduplicate without changing order")
        expect(OfflineMediaKey.filename(for: "https://cdn.example.com/a.jpg") == OfflineMediaKey.filename(for: "https://cdn.example.com/a.jpg"), "media filenames should be stable")
        expect(OfflineMediaKey.filename(for: "https://cdn.example.com/a.jpg") != OfflineMediaKey.filename(for: "https://cdn.example.com/b.jpg"), "different media URLs should have different filenames")

        let root = FileManager.default.temporaryDirectory.appendingPathComponent("EksilikHarness-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = OfflineTopicStore(rootURL: root)
        let request = TopicRequest(link: "/offline-test--42")
        let topic = OfflineTopic(title: "offline test", request: request, contentMode: .normal, pageLimit: .fivePages, totalPages: 2)
        let page = OfflineTopicPage(topicID: topic.id, pageNumber: 1, title: topic.title, entries: [first, second])

        do {
            try await store.saveTopic(topic)
            try await store.savePage(page)
            let loaded = try await store.loadTopic(id: topic.id)
            let loadedPage = try await store.loadPage(topicID: topic.id, pageNumber: 1)
            expect(loaded.completedPages == [1], "saving a page should persist manifest progress")
            expect(loadedPage.entries.map(\.id) == ["1", "2"], "offline pages should round-trip atomically")
            try await store.deleteTopic(id: topic.id)
            let remainingTopics = try await store.listTopics()
            expect(remainingTopics.isEmpty, "deleting an offline topic should remove it")

            try await store.saveTopic(topic)
            let manifest = root.appendingPathComponent(topic.id).appendingPathComponent("manifest.json")
            try Data("not-json".utf8).write(to: manifest, options: .atomic)
            let recoveredTopics = try await store.listTopics()
            let quarantinedFiles = try FileManager.default.contentsOfDirectory(atPath: manifest.deletingLastPathComponent().path)
            expect(recoveredTopics.isEmpty, "a corrupt manifest should not hide other offline topics")
            expect(quarantinedFiles.contains { $0.hasPrefix("manifest-corrupt-") }, "a corrupt manifest should be quarantined")
        } catch {
            expect(false, "offline storage round-trip failed: \(error)")
        }
    }

    mutating func runProfilePaginationChecks() {
        func entry(_ id: String, content: String) -> UserProfile.ProfileEntry {
            UserProfile.ProfileEntry(
                id: id,
                topicTitle: "başlık",
                topicLink: "baslik--1",
                contentHTML: content,
                author: "yazar",
                authorId: "1",
                date: "",
                favoriteCount: 0,
                isFavorited: false,
                voteState: .none,
                isPinned: false,
                imageURLs: []
            )
        }

        let merged = UserProfile.ProfileEntry.orderedUnique([
            entry("1", content: "ilk"),
            entry("2", content: "ikinci"),
            entry("1", content: "tekrar"),
        ])
        expect(merged.map(\.id) == ["1", "2"], "profile pagination should not append duplicate entries")
        expect(merged.first?.contentHTML == "ilk", "profile pagination should keep the first entry value")
    }
}

private var harness = Harness()
harness.runBaselineParserChecks()
harness.runTopicRequestChecks()
harness.runStableLoadingChecks()
harness.runImageURLChecks()
await harness.runOfflinePlanningChecks()
harness.runProfilePaginationChecks()

if harness.failures.isEmpty {
    print("PASS: \(harness.checks) core checks")
} else {
    for failure in harness.failures {
        fputs("FAIL: \(failure)\n", stderr)
    }
    exit(1)
}
