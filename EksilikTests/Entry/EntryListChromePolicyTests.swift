import XCTest
@testable import EksilikApp

final class EntryListChromePolicyTests: XCTestCase {
    func testPaginationControlsLookCompactWithoutShrinkingTheTouchTarget() {
        XCTAssertGreaterThanOrEqual(EntryListChromePolicy.paginationTouchTargetSize, 44)
        XCTAssertLessThanOrEqual(EntryListChromePolicy.paginationVisualButtonSize, 40)
        XCTAssertLessThan(
            EntryListChromePolicy.paginationVisualButtonSize,
            EntryListChromePolicy.paginationTouchTargetSize
        )
        XCTAssertGreaterThanOrEqual(EntryListChromePolicy.paginationControlSpacing, 12)
        XCTAssertEqual(EntryListChromePolicy.leadingPaginationControls, [.first, .previous])
        XCTAssertEqual(EntryListChromePolicy.trailingPaginationControls, [.next, .last])
    }

    func testPaginationControlsTargetTheExpectedPages() {
        let pagination = Pagination(currentPage: 2, totalPages: 3)

        XCTAssertEqual(PaginationControl.first.targetPage(in: pagination), 1)
        XCTAssertEqual(PaginationControl.previous.targetPage(in: pagination), 1)
        XCTAssertEqual(PaginationControl.next.targetPage(in: pagination), 3)
        XCTAssertEqual(PaginationControl.last.targetPage(in: pagination), 3)
    }

    func testPaginationControlsDisableAtBoundaries() {
        let firstPage = Pagination(currentPage: 1, totalPages: 3)
        let lastPage = Pagination(currentPage: 3, totalPages: 3)

        XCTAssertFalse(PaginationControl.first.isEnabled(in: firstPage))
        XCTAssertFalse(PaginationControl.previous.isEnabled(in: firstPage))
        XCTAssertFalse(PaginationControl.next.isEnabled(in: lastPage))
        XCTAssertFalse(PaginationControl.last.isEnabled(in: lastPage))
    }

    func testFilterSwipeOnboardingOnlyAppearsBeforeCompletion() {
        XCTAssertTrue(EntryListChromePolicy.shouldPresentFilterSwipeOnboarding(hasSeen: false))
        XCTAssertFalse(EntryListChromePolicy.shouldPresentFilterSwipeOnboarding(hasSeen: true))
    }
}
