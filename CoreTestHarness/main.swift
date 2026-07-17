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
        expect(
            LoginFlowPolicy.completion(
                for: URL(string: "https://eksisozluk.com/giris")!,
                html: #"<nav><a class="profile" href="/biri/sherlockun-besinci-sezonu" title="sherlockun besinci sezonu">hesabım</a></nav>"#
            ) == .authenticated(username: "sherlockun besinci sezonu"),
            "an existing session should resolve its username without legacy buddy markup"
        )
        expect(
            LoginFlowPolicy.shouldRecoverUsername(
                for: .authenticated(username: nil),
                currentURL: URL(string: "https://eksisozluk.com/giris")!,
                hasAuthCookie: true,
                hasAttemptedRecovery: false
            ),
            "a cookie-backed login without a username should recover once from the root page"
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

    mutating func runMainTabChecks() {
        expect(
            MainTab.allCases == [.home, .search, .events, .profile, .settings],
            "the olay tab should remain in the primary tab bar"
        )
        expect(MainTab.events.title == "olay", "the events tab should keep its olay label")
        expect(
            !MainTab.allCases.map(\.rawValue).contains("offline"),
            "offline reading should not replace a primary tab"
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
        let tallScreenRows = SkeletonLayout.rowCount(
            viewportHeight: 874,
            reservedHeight: 184,
            estimatedRowHeight: 92,
            minimumRows: 5
        )
        expect(tallScreenRows >= 9, "skeletons should add enough rows to cover a tall phone")
        expect(
            Double(tallScreenRows) * 92 >= 874 - 184,
            "calculated skeleton rows should cover the remaining viewport"
        )
        expect(
            SkeletonLayout.rowCount(
                viewportHeight: 320,
                reservedHeight: 200,
                estimatedRowHeight: 100,
                minimumRows: 5
            ) == 5,
            "short viewports should keep the intended minimum placeholder count"
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

    mutating func runEntryLayoutStyleChecks() {
        expect(EntryLayoutStyle.allCases.count == 8, "settings should expose exactly eight entry layouts")
        expect(
            Set(EntryLayoutStyle.allCases.map(\.rawValue)).count == EntryLayoutStyle.allCases.count,
            "each entry layout should have a stable unique storage value"
        )
        expect(
            Set(EntryLayoutStyle.allCases.map(\.family)).count == EntryLayoutStyle.allCases.count,
            "each entry layout should select a genuinely different rendering family"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: nil) == .classic,
            "a missing entry layout preference should use the classic layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "future-layout") == .classic,
            "an unknown entry layout preference should safely use the classic layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: EntryLayoutStyle.xFeed.rawValue) == .xFeed,
            "a stored entry layout should round-trip"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "compact") == .xFeed,
            "the old compact preference should migrate to the X layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "card") == .linkedIn,
            "the old card preference should migrate to the LinkedIn layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "authorFirst") == .instagram,
            "the old author-first preference should migrate to the Instagram layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "metadataFirst") == .terminal,
            "the old metadata-first preference should migrate to the terminal layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "comfortable") == .reader,
            "the old comfortable preference should migrate to the reader layout"
        )
        expect(
            EntryLayoutStyle.resolve(storedValue: "focus") == .reader,
            "the old focus preference should migrate to the reader layout"
        )
        expect(
            !EntryLayoutStyle.minimal.presentation.showsAvatar,
            "the minimal layout should remove the author avatar"
        )
    }

    mutating func runHomeNavigationChecks() {
        expect(
            HomeNavigationStyle.allCases.count == 5,
            "settings should expose five genuinely different home navigation styles"
        )
        expect(
            Set(HomeNavigationStyle.allCases.map(\.rawValue)).count == HomeNavigationStyle.allCases.count,
            "home navigation styles should have unique stable storage values"
        )
        expect(
            HomeNavigationStyle.resolve(storedValue: nil, legacyPosition: nil) == .floatingDock,
            "fresh installs should use the floating dock"
        )
        expect(
            HomeNavigationStyle.resolve(storedValue: nil, legacyPosition: "bottom") == .classicBottom,
            "the legacy bottom preference should migrate to the classic bottom bar"
        )
        expect(
            HomeNavigationStyle.resolve(storedValue: nil, legacyPosition: "top") == .topRail,
            "the legacy top preference should migrate to the top rail"
        )
        expect(
            HomeNavigationStyle.resolve(storedValue: "future-navigation", legacyPosition: "bottom") == .floatingDock,
            "unknown new navigation values should use the safe modern default"
        )

        let defaultIDs = HomeTabCatalog.defaultOrder
        expect(defaultIDs.count == 9, "the home tab catalog should include every supported topic list")
        expect(Set(defaultIDs).count == defaultIDs.count, "home tab identifiers should be unique")

        let normalized = HomeTabCatalog.normalizedOrder(["today", "future", "today"])
        expect(normalized.first == "today", "a stored custom tab should keep its leading position")
        expect(!normalized.contains("future"), "unknown stored tabs should be removed")
        expect(Set(normalized) == Set(defaultIDs), "missing known tabs should be appended during migration")

        let moved = HomeTabCatalog.moving(
            defaultIDs,
            fromOffsets: IndexSet(integer: 0),
            toOffset: 3
        )
        expect(
            Array(moved.prefix(3)) == ["today", "debe", "popular"],
            "dragging the first tab after the third should preserve SwiftUI move semantics"
        )

        let loggedOutTabs = HomeTabCatalog.availableTabs(
            order: ["latest", "today", "popular"],
            visible: ["latest", "today", "popular"],
            isLoggedIn: false
        )
        expect(
            Array(loggedOutTabs.map(\.id).prefix(2)) == ["today", "popular"],
            "logged-out navigation should hide account-only tabs without losing the custom order"
        )
        expect(
            HomeTabCatalog.availableTabs(
                order: defaultIDs,
                visible: ["following"],
                isLoggedIn: false
            ).map(\.id) == ["popular"],
            "an unavailable visible selection should fall back to a usable public tab"
        )

        let swipeIDs = ["popular", "today", "debe"]
        expect(
            HomeNavigationPolicy.adjacentTabID(in: swipeIDs, selected: "popular", step: 1) == "today",
            "a left swipe should select the next visible tab"
        )
        expect(
            HomeNavigationPolicy.adjacentTabID(in: swipeIDs, selected: "today", step: -1) == "popular",
            "a right swipe should select the previous visible tab"
        )
        expect(
            HomeNavigationPolicy.adjacentTabID(in: swipeIDs, selected: "popular", step: -1) == "popular",
            "swiping before the first tab should stay at the boundary"
        )
        expect(
            HomeNavigationPolicy.step(horizontal: 42, vertical: 38) == nil,
            "short diagonal drags should not trigger a tab change"
        )
        expect(
            HomeNavigationPolicy.step(horizontal: -92, vertical: 18) == 1,
            "a decisive left drag should request the next tab"
        )
    }

    mutating func runSearchPresentationChecks() {
        expect(
            SearchPresentation.state(
                query: "",
                isSearching: false,
                titleCount: 0,
                nickCount: 0,
                error: nil
            ) == .discovery,
            "an empty search should show channel discovery"
        )
        expect(
            SearchPresentation.state(
                query: "a",
                isSearching: false,
                titleCount: 0,
                nickCount: 0,
                error: nil
            ) == .needsMoreCharacters,
            "a one-character search should explain the minimum query length"
        )
        expect(
            SearchPresentation.state(
                query: "arama",
                isSearching: true,
                titleCount: 0,
                nickCount: 0,
                error: nil
            ) == .loading,
            "an active request should show the full search skeleton"
        )
        expect(
            SearchPresentation.state(
                query: "arama",
                isSearching: false,
                titleCount: 1,
                nickCount: 1,
                error: nil
            ) == .results,
            "autocomplete matches should show results"
        )
        expect(
            SearchPresentation.state(
                query: "arama",
                isSearching: false,
                titleCount: 0,
                nickCount: 0,
                error: nil
            ) == .empty,
            "a completed request without matches should show an empty state"
        )
        expect(
            SearchPresentation.state(
                query: "arama",
                isSearching: false,
                titleCount: 0,
                nickCount: 0,
                error: "bağlantı yok"
            ) == .failure,
            "a failed request should expose a retry state"
        )
        expect(SearchPresentation.resolve(query: " #123 ") == .entry(id: "123"), "entry queries should route by ID")
        expect(
            SearchPresentation.resolve(query: "@sherlockun besinci sezonu") == .profile(username: "sherlockun besinci sezonu"),
            "author queries should preserve the displayed nickname"
        )
        expect(SearchPresentation.resolve(query: "#abc") == nil, "malformed entry queries should not route as topics")
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

        let gallery = ImageGalleryPresentation(
            imageURLs: [
                "//cdn.example.com/first.png",
                "https://cdn.example.com/second.jpg",
                "//cdn.example.com/first.png",
            ],
            initialIndex: 99
        )
        expect(
            gallery?.imageURLs == [
                "https://cdn.example.com/first.png",
                "https://cdn.example.com/second.jpg",
            ],
            "a gallery presentation should carry normalized images as one value"
        )
        expect(gallery?.initialIndex == 1, "a gallery presentation should clamp its initial selection")
        expect(
            ImageGalleryPresentation(imageURLs: ["", "javascript:alert(1)"], initialIndex: 0) == nil,
            "an empty normalized image set should not present a gallery"
        )

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

    mutating func runExternalLinkChecks() {
        let marked = ExternalLinkPolicy.addingTextMarkers(
            to: #"<a href="https://x.com/example/status/1">kaynak</a>"#
        )
        expect(
            marked.contains("kaynak \u{2197}\u{FE0E}"),
            "external links should use the text-presentation north-east arrow"
        )
        expect(
            !marked.contains("\u{FE0F}"),
            "external link markers should never request emoji presentation"
        )

        let nativeHosts = [
            "https://x.com/example/status/1",
            "https://www.instagram.com/p/example/",
            "https://youtu.be/example",
            "https://m.youtube.com/watch?v=example",
            "https://www.tiktok.com/@example/video/1",
            "https://www.linkedin.com/posts/example",
        ]
        expect(
            nativeHosts.allSatisfy { ExternalLinkPolicy.prefersNativeApp(URL(string: $0)!) },
            "social and media links should prefer their installed native applications"
        )
        expect(
            !ExternalLinkPolicy.prefersNativeApp(URL(string: "https://example.com/x.com")!),
            "unrelated websites should stay in the in-app browser"
        )
        expect(
            !ExternalLinkPolicy.prefersNativeApp(URL(string: "https://notx.com/example")!),
            "lookalike domains should not be treated as native social links"
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

        let readState = OfflineReadState()
            .settingRead(true, entryID: "1")
            .settingHidesReadEntries(true)
        expect(readState.isRead("1"), "offline read state should mark an entry as read")
        expect(!readState.isRead("2"), "offline read state should leave other entries unread")
        expect(
            readState.visibleEntries(from: [first, second]).map(\.id) == ["2"],
            "hiding read entries should preserve only unread entries in source order"
        )

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

            _ = try await store.setEntryRead(topicID: topic.id, entryID: "1", isRead: true)
            _ = try await store.setHidesReadEntries(topicID: topic.id, hides: true)
            let storedReadState = try await store.loadReadState(topicID: topic.id)
            expect(storedReadState.isRead("1"), "offline read markers should persist separately from pages")
            expect(storedReadState.hidesReadEntries, "the hide-read preference should persist per topic")

            _ = try await store.setEntryRead(topicID: topic.id, entryID: "1", isRead: false)
            let clearedReadState = try await store.loadReadState(topicID: topic.id)
            expect(!clearedReadState.isRead("1"), "an entry should be markable as unread again")

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

    mutating func runProfileConnectionChecks() {
        let profileHTML = """
        <h1 id="user-profile-title" data-nick="sherlockun besinci sezonu"></h1>
        <ul id="user-entry-stats">
          <li><a href="/takipci/sherlockun-besinci-sezonu"><span id="user-follower-count">35</span> takipçi</a></li>
          <li><a href="/takip/sherlockun-besinci-sezonu"><span id="user-following-count">8</span> takip</a></li>
        </ul>
        """
        let profile = UserProfileParser.parse(html: profileHTML)
        expect(
            profile.followerLink == "/takipci/sherlockun-besinci-sezonu",
            "profile parsing should retain the server follower link"
        )
        expect(
            profile.followingLink == "/takip/sherlockun-besinci-sezonu",
            "profile parsing should retain the server following link"
        )

        let connectionsHTML = """
        <ul id="follow-list">
          <li data-reverse-follow="true">
            <div class="follows-picture"><a href="/biri/altere-ses"><img src="//img.ekstat.com/profiles/altere.jpg" alt="altere ses"></a></div>
            <a id="follows-nick" href="/biri/altere-ses">altere ses</a>
            <a id="buddy-link" class="relation-link buddy-list-link remove-relation">takip ediliyor</a>
          </li>
          <li>
            <img src="//ekstat.com/img/default-profile-picture-dark.svg" alt="ottoviii">
            <a id="follows-nick" href="/biri/ottoviii">ottoviii</a>
          </li>
          <li><a id="follows-nick" href="/biri/altere-ses">altere ses</a></li>
        </ul>
        """
        let people = ProfileConnectionParser.parse(html: connectionsHTML)
        expect(people.map(\.username) == ["altere ses", "ottoviii"], "follow lists should preserve order and remove duplicates")
        expect(
            people.first?.avatarURL == "https://img.ekstat.com/profiles/altere.jpg",
            "follow list avatars should normalize protocol-relative URLs"
        )
        expect(people.first?.followsYou == true, "reverse-follow state should be retained")
        expect(people.first?.isFollowing == true, "current following state should be retained")
        expect(people.last?.avatarURL == nil, "site default SVG avatars should use the native placeholder")
        expect(
            EksiEndpoint.profileConnections(path: "/takipci/sherlockun-besinci-sezonu").path
                == "/takipci/sherlockun-besinci-sezonu",
            "profile connection requests should keep the server-provided relative path"
        )
    }
}

private var harness = Harness()
harness.runBaselineParserChecks()
harness.runTopicRequestChecks()
harness.runMainTabChecks()
harness.runStableLoadingChecks()
harness.runEntryLayoutStyleChecks()
harness.runHomeNavigationChecks()
harness.runSearchPresentationChecks()
harness.runImageURLChecks()
harness.runExternalLinkChecks()
await harness.runOfflinePlanningChecks()
harness.runProfilePaginationChecks()
harness.runProfileConnectionChecks()

if harness.failures.isEmpty {
    print("PASS: \(harness.checks) core checks")
} else {
    for failure in harness.failures {
        fputs("FAIL: \(failure)\n", stderr)
    }
    exit(1)
}
