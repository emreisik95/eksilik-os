import XCTest
@testable import EksilikApp

final class WidgetSnapshotStoreTests: XCTestCase {
    func testFeedItemIdentityIsStableAcrossRefreshes() {
        let first = WidgetFeedItem(title: "gündem başlığı", subtitle: nil, metadata: "12", link: "/gundem-basligi--42")
        let refreshed = WidgetFeedItem(title: "gündem başlığı", subtitle: "yeni", metadata: "13", link: "/gundem-basligi--42")

        XCTAssertEqual(first.id, refreshed.id)
    }

    func testSnapshotsRoundTripIndependentlyBySource() throws {
        let suiteName = "WidgetSnapshotStoreTests.roundTrip"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = WidgetSnapshotStore(defaults: defaults)
        let date = Date(timeIntervalSince1970: 1_721_300_000)

        store.save(
            WidgetFeedSnapshot(
                source: .following,
                items: [WidgetFeedItem(title: "takip", subtitle: nil, metadata: nil, link: "/takip--1")],
                updatedAt: date
            )
        )
        store.save(
            WidgetFeedSnapshot(
                source: .debe,
                items: [WidgetFeedItem(title: "debe", subtitle: "yazar", metadata: nil, link: "/entry/99")],
                updatedAt: date
            )
        )

        XCTAssertEqual(store.load(source: .following)?.items.first?.title, "takip")
        XCTAssertEqual(store.load(source: .debe)?.items.first?.link, "/entry/99")
        XCTAssertNil(store.load(source: .today))
    }

    func testClearingOneSourceKeepsOtherSnapshots() throws {
        let suiteName = "WidgetSnapshotStoreTests.clear"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = WidgetSnapshotStore(defaults: defaults)

        for source in [WidgetFeedSource.popular, .following] {
            store.save(WidgetFeedSnapshot(source: source, items: [], updatedAt: Date()))
        }

        store.clear(source: .following)

        XCTAssertNotNil(store.load(source: .popular))
        XCTAssertNil(store.load(source: .following))
    }
}
