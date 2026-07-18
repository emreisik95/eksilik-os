import XCTest
@testable import EksilikApp

final class MainTabTests: XCTestCase {
    func testOlayRemainsInPrimaryTabBarAndOfflineDoesNotReplaceIt() {
        XCTAssertEqual(MainTab.allCases, [.home, .search, .events, .profile, .settings])
        XCTAssertEqual(MainTab.events.title, "olay")
        XCTAssertFalse(MainTab.allCases.map(\.rawValue).contains("offline"))
    }

    func testVisibleTabsIncludeOlayWhenLoggedIn() {
        XCTAssertEqual(
            MainTab.visibleTabs(isLoggedIn: true),
            [.home, .search, .events, .profile, .settings]
        )
    }

    func testVisibleTabsHideOlayWhenLoggedOut() {
        XCTAssertEqual(
            MainTab.visibleTabs(isLoggedIn: false),
            [.home, .search, .profile, .settings]
        )
    }
}
