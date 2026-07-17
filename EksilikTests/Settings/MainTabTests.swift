import XCTest
@testable import EksilikApp

final class MainTabTests: XCTestCase {
    func testOlayRemainsInPrimaryTabBarAndOfflineDoesNotReplaceIt() {
        XCTAssertEqual(MainTab.allCases, [.home, .search, .events, .profile, .settings])
        XCTAssertEqual(MainTab.events.title, "olay")
        XCTAssertFalse(MainTab.allCases.map(\.rawValue).contains("offline"))
    }
}
