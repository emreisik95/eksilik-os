import XCTest
@testable import EksilikApp

final class SettingsPresentationPolicyTests: XCTestCase {
    func testSectionsHaveAStableScannableOrder() {
        let sections = SettingsPresentationPolicy.sections(isLoggedIn: false)

        XCTAssertEqual(
            sections.map(\.kind),
            [.appearance, .home, .content, .account, .advanced]
        )
    }

    func testEverySignedOutItemAppearsExactlyOnce() {
        let items = SettingsPresentationPolicy.sections(isLoggedIn: false).flatMap(\.items)

        XCTAssertEqual(items.count, Set(items).count)
        XCTAssertEqual(
            items,
            [
                .theme, .entryLayout, .fontSize, .filterStyle, .appIcon,
                .homeNavigation, .homeTabs,
                .offlineLibrary, .blockedTopics,
                .login,
                .server,
            ]
        )
    }

    func testAccountItemsAdaptToSessionState() {
        let signedOut = SettingsPresentationPolicy.sections(isLoggedIn: false)
            .first(where: { $0.kind == .account })
        let signedIn = SettingsPresentationPolicy.sections(isLoggedIn: true)
            .first(where: { $0.kind == .account })

        XCTAssertEqual(signedOut?.items, [.login])
        XCTAssertEqual(signedIn?.items, [.accountPreferences, .trackingAndBlocks, .logout])
    }

    func testFontAdjustmentClampsToSupportedRange() {
        XCTAssertEqual(SettingsPresentationPolicy.adjustedFontSize(10, delta: -1), 10)
        XCTAssertEqual(SettingsPresentationPolicy.adjustedFontSize(15, delta: 1), 16)
        XCTAssertEqual(SettingsPresentationPolicy.adjustedFontSize(24, delta: 1), 24)
    }
}
