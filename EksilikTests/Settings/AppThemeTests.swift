import XCTest
@testable import EksilikApp

final class AppThemeTests: XCTestCase {
    func testThemeCatalogContainsFifteenStableUniqueChoices() {
        XCTAssertEqual(AppTheme.allCases.count, 15)
        XCTAssertEqual(Set(AppTheme.allCases.map(\.rawValue)).count, 15)
        XCTAssertEqual(Set(AppTheme.allCases.map(\.name)).count, 15)
        XCTAssertEqual(Set(AppTheme.allCases.map(\.palette)).count, 15)
    }

    func testExistingThemeStorageValuesRemainBackwardCompatible() {
        XCTAssertEqual(AppTheme.dark.rawValue, 0)
        XCTAssertEqual(AppTheme.light.rawValue, 1)
        XCTAssertEqual(AppTheme.classic.rawValue, 2)
        XCTAssertEqual(AppTheme.twitter.rawValue, 3)
        XCTAssertEqual(AppTheme.oled.rawValue, 4)
    }

    func testEveryThemeKeepsPrimaryTextReadableOnItsSurfaces() {
        for theme in AppTheme.allCases {
            XCTAssertGreaterThanOrEqual(
                theme.palette.label.contrastRatio(with: theme.palette.background),
                4.5,
                "\(theme.name) label/background contrast"
            )
            XCTAssertGreaterThanOrEqual(
                theme.palette.entryText.contrastRatio(with: theme.palette.cellPrimary),
                4.5,
                "\(theme.name) entry/surface contrast"
            )
        }
    }

    func testNewThemesAreAppendedAfterExistingValues() {
        XCTAssertEqual(
            AppTheme.allCases.map(\.name),
            [
                "dark", "light", "oldschool", "x", "oled",
                "notebook", "bosphorus", "burgundy", "terminal", "lilac",
                "solar dark", "solar light", "ice", "coffee", "high contrast",
            ]
        )
    }
}
