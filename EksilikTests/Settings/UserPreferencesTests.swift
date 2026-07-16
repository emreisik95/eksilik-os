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

        preferences.entryLayoutStyle = .linkedIn

        XCTAssertEqual(defaults.string(forKey: "entryLayoutStyle"), EntryLayoutStyle.linkedIn.rawValue)
        XCTAssertEqual(UserPreferences(defaults: defaults).entryLayoutStyle, .linkedIn)
    }

    func testUnknownEntryLayoutStyleFallsBackToClassic() throws {
        let suiteName = "UserPreferencesTests.unknownEntryLayoutStyle"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("future-layout", forKey: "entryLayoutStyle")

        XCTAssertEqual(UserPreferences(defaults: defaults).entryLayoutStyle, .classic)
    }

    func testLegacyEntryLayoutStyleMigratesToSocialEquivalent() throws {
        let suiteName = "UserPreferencesTests.legacyEntryLayoutStyle"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("authorFirst", forKey: "entryLayoutStyle")

        XCTAssertEqual(UserPreferences(defaults: defaults).entryLayoutStyle, .instagram)
    }
}
