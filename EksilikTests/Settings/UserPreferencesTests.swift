import Combine
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

    func testHomeNavigationStylePersistsAcrossPreferenceInstances() throws {
        let suiteName = "UserPreferencesTests.homeNavigationStyle"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = UserPreferences(defaults: defaults)
        XCTAssertEqual(preferences.homeNavigationStyle, .floatingDock)

        preferences.homeNavigationStyle = .sidebar

        XCTAssertEqual(defaults.string(forKey: "homeNavigationStyle"), HomeNavigationStyle.sidebar.rawValue)
        XCTAssertEqual(UserPreferences(defaults: defaults).homeNavigationStyle, .sidebar)
    }

    func testLegacyTopTabBarMigratesToTopRail() throws {
        let suiteName = "UserPreferencesTests.legacyHomeNavigation"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("top", forKey: "homeTabBarPosition")

        XCTAssertEqual(UserPreferences(defaults: defaults).homeNavigationStyle, .topRail)
    }

    func testHomeTabOrderAndVisibilityPersistTogether() throws {
        let suiteName = "UserPreferencesTests.homeTabOrder"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = UserPreferences(defaults: defaults)
        preferences.homeTabOrder = ["today", "popular", "debe"]
        preferences.visibleHomeTabs = ["today", "popular"]

        let restored = UserPreferences(defaults: defaults)
        XCTAssertEqual(Array(restored.homeTabOrder.prefix(3)), ["today", "popular", "debe"])
        XCTAssertEqual(restored.visibleHomeTabs, ["today", "popular"])
    }

    func testFontSizePublishesImmediatelyAndPersists() throws {
        let suiteName = "UserPreferencesTests.fontSize"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = UserPreferences(defaults: defaults)
        var changeCount = 0
        let observation = preferences.objectWillChange.sink { changeCount += 1 }

        preferences.selectedFontSize = 19

        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(defaults.integer(forKey: "selectedFontSize"), 19)
        XCTAssertEqual(UserPreferences(defaults: defaults).selectedFontSize, 19)
        withExtendedLifetime(observation) {}
    }

    func testFormerAppStoragePreferencesUseInjectedDefaults() throws {
        let suiteName = "UserPreferencesTests.observableStorage"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = UserPreferences(defaults: defaults)
        preferences.selectedFont = "Avenir Next"
        preferences.openLinksInSafari = false
        preferences.hideEntriesEnabled = true
        preferences.baseURL = "https://eksisozluk.com"
        preferences.useIconFilters = true

        let restored = UserPreferences(defaults: defaults)
        XCTAssertEqual(restored.selectedFont, "Avenir Next")
        XCTAssertFalse(restored.openLinksInSafari)
        XCTAssertTrue(restored.hideEntriesEnabled)
        XCTAssertEqual(restored.baseURL, "https://eksisozluk.com")
        XCTAssertTrue(restored.useIconFilters)
    }

    func testAllVisibleLegacyTabsMigrateToIncludeEksiSeyler() throws {
        let suiteName = "UserPreferencesTests.seylerVisibilityMigration"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let legacyTabs = HomeTabCatalog.defaultOrder.filter { $0 != "eksiSeyler" }
        defaults.set(try JSONEncoder().encode(legacyTabs), forKey: "visibleHomeTabs")

        let preferences = UserPreferences(defaults: defaults)

        XCTAssertEqual(preferences.visibleHomeTabs, legacyTabs + ["eksiSeyler"])
    }
}
