import XCTest
@testable import EksilikApp

final class OfflineTopicStoreTests: XCTestCase {
    func testAtomicRoundTripProgressAndDeletion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = OfflineTopicStore(rootURL: root)
        let topic = OfflineTopic(
            title: "offline test",
            request: TopicRequest(link: "/offline-test--42"),
            contentMode: .normal,
            pageLimit: .fivePages,
            totalPages: 2
        )
        let entry = OfflineEntry(id: "1", contentHTML: "one", authorNick: "a", authorID: "a", authorAvatarURL: nil, date: "d", favoriteCount: 0, imageURLs: [])

        try await store.saveTopic(topic)
        try await store.savePage(OfflineTopicPage(topicID: topic.id, pageNumber: 1, title: topic.title, entries: [entry]))

        let loadedTopic = try await store.loadTopic(id: topic.id)
        let loadedPage = try await store.loadPage(topicID: topic.id, pageNumber: 1)
        XCTAssertEqual(loadedTopic.completedPages, [1])
        XCTAssertEqual(loadedPage.entries.map(\.id), ["1"])

        try await store.deleteTopic(id: topic.id)
        let remainingTopics = try await store.listTopics()
        XCTAssertTrue(remainingTopics.isEmpty)
    }

    func testOrderedEntryDeduplicationKeepsFirstValue() {
        let first = OfflineEntry(id: "1", contentHTML: "first", authorNick: "a", authorID: "a", authorAvatarURL: nil, date: "", favoriteCount: 0, imageURLs: [])
        let replacement = OfflineEntry(id: "1", contentHTML: "replacement", authorNick: "a", authorID: "a", authorAvatarURL: nil, date: "", favoriteCount: 0, imageURLs: [])

        XCTAssertEqual(OfflineEntry.orderedUnique([first, replacement]).map(\.contentHTML), ["first"])
    }

    func testCorruptManifestIsQuarantined() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = OfflineTopicStore(rootURL: root)
        let topic = OfflineTopic(
            title: "offline test",
            request: TopicRequest(link: "/offline-test--42"),
            contentMode: .normal,
            pageLimit: .fivePages,
            totalPages: 1
        )
        try await store.saveTopic(topic)
        let directory = root.appendingPathComponent(topic.id, isDirectory: true)
        try Data("not-json".utf8).write(to: directory.appendingPathComponent("manifest.json"), options: .atomic)

        let topics = try await store.listTopics()
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(topics.isEmpty)
        XCTAssertTrue(files.contains { $0.hasPrefix("manifest-corrupt-") })
    }
}
