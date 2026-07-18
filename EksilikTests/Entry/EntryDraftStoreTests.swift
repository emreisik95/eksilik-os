import XCTest
@testable import EksilikApp

final class EntryDraftStoreTests: XCTestCase {
    func testDraftsRoundTripIndependentlyForEachTopic() throws {
        let suiteName = "EntryDraftStoreTests.roundTrip"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntryDraftStore(defaults: defaults)

        store.save("ilk taslak", for: "/ilk--1")
        store.save("ikinci taslak", for: "/ikinci--2")

        XCTAssertEqual(store.load(for: "/ilk--1"), "ilk taslak")
        XCTAssertEqual(store.load(for: "/ikinci--2"), "ikinci taslak")
    }

    func testBlankDraftRemovesPreviouslySavedContent() throws {
        let suiteName = "EntryDraftStoreTests.blank"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntryDraftStore(defaults: defaults)

        store.save("taslak", for: "/baslik--1")
        store.save("  \n", for: "/baslik--1")

        XCTAssertNil(store.load(for: "/baslik--1"))
    }

    func testClearOnlyRemovesRequestedTopic() throws {
        let suiteName = "EntryDraftStoreTests.clear"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntryDraftStore(defaults: defaults)

        store.save("bir", for: "/bir--1")
        store.save("iki", for: "/iki--2")
        store.clear(for: "/bir--1")

        XCTAssertNil(store.load(for: "/bir--1"))
        XCTAssertEqual(store.load(for: "/iki--2"), "iki")
    }

    func testClearAllRemovesDraftsWithoutTouchingOtherPreferences() throws {
        let suiteName = "EntryDraftStoreTests.clearAll"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EntryDraftStore(defaults: defaults)

        store.save("bir", for: "/bir--1")
        store.save("iki", for: "/iki--2")
        defaults.set("koru", forKey: "unrelated.preference")

        store.clearAll()

        XCTAssertNil(store.load(for: "/bir--1"))
        XCTAssertNil(store.load(for: "/iki--2"))
        XCTAssertEqual(defaults.string(forKey: "unrelated.preference"), "koru")
    }
}
