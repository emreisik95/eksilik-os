import XCTest
@testable import EksilikApp

final class EntryLayoutRenderingPolicyTests: XCTestCase {
    func testStyleOverrideWinsSoPreviewUsesTheRequestedProductionLayout() {
        XCTAssertEqual(
            EntryRowRenderingPolicy.style(preferred: .classic, override: .reddit),
            .reddit
        )
        XCTAssertEqual(
            EntryRowRenderingPolicy.style(preferred: .instagram, override: nil),
            .instagram
        )
    }

    func testLayoutMetricsGrowAlongsideTheUserSelectedFontSize() {
        let base = EntryLayoutMetrics(
            fontSize: 15,
            presentation: EntryLayoutStyle.classic.presentation
        )
        let large = EntryLayoutMetrics(
            fontSize: 24,
            presentation: EntryLayoutStyle.classic.presentation
        )

        XCTAssertEqual(base.horizontalPadding, 16, accuracy: 0.001)
        XCTAssertEqual(base.verticalPadding, 16, accuracy: 0.001)
        XCTAssertGreaterThan(large.horizontalPadding, base.horizontalPadding)
        XCTAssertGreaterThan(large.verticalPadding, base.verticalPadding)
        XCTAssertGreaterThan(large.contentSpacing, base.contentSpacing)
        XCTAssertGreaterThan(large.imageScale, base.imageScale)
        XCTAssertGreaterThanOrEqual(large.minimumActionTarget, 44)
    }

    func testLayoutMetricsClampExtremeValuesWithoutUndersizingControls() {
        let tiny = EntryLayoutMetrics(
            fontSize: -100,
            presentation: EntryLayoutStyle.reader.presentation
        )
        let huge = EntryLayoutMetrics(
            fontSize: 1_000,
            presentation: EntryLayoutStyle.reader.presentation
        )

        XCTAssertGreaterThanOrEqual(tiny.scale, 0.9)
        XCTAssertLessThanOrEqual(huge.scale, 1.45)
        XCTAssertEqual(tiny.minimumActionTarget, 44, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(huge.minimumActionTarget, 44)
    }
}
