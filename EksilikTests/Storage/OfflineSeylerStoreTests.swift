import XCTest
@testable import EksilikApp

final class OfflineSeylerStoreTests: XCTestCase {
    private var rootURL: URL!
    private var store: OfflineSeylerStore!

    override func setUp() {
        super.setUp()
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("offline-seyler-tests-\(UUID().uuidString)", isDirectory: true)
        store = OfflineSeylerStore(rootURL: rootURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: rootURL)
        store = nil
        rootURL = nil
        super.tearDown()
    }

    func testArticleRoundTripsAndRepeatedSaveReplacesOneStableItem() async throws {
        let article = makeArticle(title: "ilk başlık")
        let first = try await store.saveArticle(article)
        let second = try await store.saveArticle(makeArticle(title: "güncel başlık"))
        let loaded = try await store.loadArticle(sourceURL: article.sourceURL)
        let listed = try await store.listArticles()

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(loaded.article.title, "güncel başlık")
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.article.blocks, article.blocks)
    }

    func testMediaLookupAndDeleteAreScopedToTheSavedArticle() async throws {
        let article = makeArticle(title: "çevrimdışı")
        let saved = try await store.saveArticle(article)
        let imageURL = try XCTUnwrap(article.heroImageURL)

        let localURL = try await store.saveMedia(
            Data("image".utf8),
            articleID: saved.id,
            sourceURL: imageURL
        )
        let resolvedURL = await store.localMediaURL(
            articleID: saved.id,
            sourceURL: imageURL
        )

        XCTAssertEqual(resolvedURL, localURL)

        try await store.deleteArticle(id: saved.id)
        let remaining = try await store.listArticles()
        let deletedMediaURL = await store.localMediaURL(
            articleID: saved.id,
            sourceURL: imageURL
        )
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertNil(deletedMediaURL)
    }

    private func makeArticle(title: String) -> SeylerArticle {
        SeylerArticle(
            sourceURL: URL(string: "https://eksiseyler.com/ornek-yazi")!,
            title: title,
            summary: "özet",
            category: "bilim",
            date: "14.08.2026",
            readCount: "42",
            shareCount: nil,
            heroImageURL: URL(string: "https://seyler.ekstat.com/hero.jpg"),
            authors: ["yazar"],
            blocks: [
                .paragraph("ilk paragraf"),
                .heading("ara başlık"),
                .list(["bir", "iki"]),
            ]
        )
    }
}
