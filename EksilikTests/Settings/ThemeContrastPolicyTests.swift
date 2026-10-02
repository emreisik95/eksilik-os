import XCTest
@testable import EksilikApp

final class ThemeContrastPolicyTests: XCTestCase {
    func testPolicyChecksTheFourReadingPairs() {
        let checks = ThemeContrastPolicy.checks(for: AppTheme.light.palette)

        XCTAssertEqual(checks.map(\.foreground), [.entryText, .link, .label, .date])
        XCTAssertEqual(checks.map(\.background), [.background, .background, .cellPrimary, .background])
        XCTAssertEqual(checks.map(\.title), [
            "entry metni / arka plan",
            "link / arka plan",
            "başlık / hücre",
            "tarih / arka plan",
        ])
    }

    func testReadablePaletteProducesNoWarnings() {
        XCTAssertTrue(ThemeContrastPolicy.warnings(for: AppTheme.highContrast.palette).isEmpty)
    }

    func testLowContrastPairsAreFlaggedBelowFourPointFive() {
        var palette = AppTheme.light.palette
        palette.entryText = ThemeColorToken(hex: 0xBBBBBB)
        palette.link = ThemeColorToken(hex: 0x595959)

        let warnings = ThemeContrastPolicy.warnings(for: palette)

        XCTAssertEqual(warnings.map(\.foreground), [.entryText])
        XCTAssertEqual(ThemeContrastPolicy.minimumRatio, 4.5)
    }

    func testRatioAtTheThresholdIsNotAWarning() {
        XCTAssertFalse(check(ratio: 4.5).isBelowMinimum)
        XCTAssertTrue(check(ratio: 4.49).isBelowMinimum)
    }

    func testIdenticalColorsAreTheWorstCase() {
        var palette = AppTheme.dark.palette
        palette.label = palette.cellPrimary

        let labelCheck = ThemeContrastPolicy.checks(for: palette).first { $0.foreground == .label }

        XCTAssertEqual(labelCheck?.ratio ?? 0, 1, accuracy: 0.0001)
        XCTAssertEqual(labelCheck?.isBelowMinimum, true)
    }

    func testRatioIsFormattedWithATurkishDecimalCommaAndNeverRoundsUpPastTheLimit() {
        XCTAssertEqual(check(ratio: 21).formattedRatio, "21,0:1")
        XCTAssertEqual(check(ratio: 4.48).formattedRatio, "4,4:1")
        XCTAssertEqual(check(ratio: 4.5).formattedRatio, "4,5:1")
    }

    private func check(ratio: Double) -> ThemeContrastCheck {
        ThemeContrastCheck(foreground: .link, background: .background, ratio: ratio)
    }
}
