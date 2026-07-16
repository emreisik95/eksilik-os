import XCTest
@testable import EksilikApp

final class UserPreferencesTests: XCTestCase {
    func testEntryLayoutStylePersistsAcrossPreferenceInstances() throws {
        let suiteName = "UserPreferencesTests.entryLayoutStyle"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = UserPreferences(defaults: defaults)
        XCTAssertEqual(preferences.entryLayoutStyle, .classic)

        preferences.entryLayoutStyle = .card

        XCTAssertEqual(defaults.string(forKey: "entryLayoutStyle"), EntryLayoutStyle.card.rawValue)
        XCTAssertEqual(UserPreferences(defaults: defaults).entryLayoutStyle, .card)
    }

    func testUnknownEntryLayoutStyleFallsBackToClassic() throws {
        let suiteName = "UserPreferencesTests.unknownEntryLayoutStyle"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("future-layout", forKey: "entryLayoutStyle")

        XCTAssertEqual(UserPreferences(defaults: defaults).entryLayoutStyle, .classic)
    }
}
