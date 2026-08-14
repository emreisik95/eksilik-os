import XCTest
@testable import EksilikApp

final class PaginationSelectionPolicyTests: XCTestCase {
    func testManualPageInputTrimsAndClampsToAvailablePages() {
        XCTAssertEqual(PaginationSelectionPolicy.page(from: " 7 ", totalPages: 20), 7)
        XCTAssertEqual(PaginationSelectionPolicy.page(from: "0", totalPages: 20), 1)
        XCTAssertEqual(PaginationSelectionPolicy.page(from: "999", totalPages: 20), 20)
        XCTAssertEqual(PaginationSelectionPolicy.page(from: "1", totalPages: 0), 1)
    }

    func testManualPageInputRejectsEmptyNonNumericAndSignedValues() {
        XCTAssertNil(PaginationSelectionPolicy.page(from: "", totalPages: 20))
        XCTAssertNil(PaginationSelectionPolicy.page(from: "iki", totalPages: 20))
        XCTAssertNil(PaginationSelectionPolicy.page(from: "2.5", totalPages: 20))
        XCTAssertNil(PaginationSelectionPolicy.page(from: "+3", totalPages: 20))
    }

    func testQuickPagesIncludeBoundariesAndANearbyWindow() {
        XCTAssertEqual(
            PaginationSelectionPolicy.quickPages(currentPage: 10, totalPages: 20),
            [1, 8, 9, 10, 11, 12, 20]
        )
        XCTAssertEqual(
            PaginationSelectionPolicy.quickPages(currentPage: 1, totalPages: 4),
            [1, 2, 3, 4]
        )
        XCTAssertEqual(
            PaginationSelectionPolicy.quickPages(currentPage: 20, totalPages: 20),
            [1, 16, 17, 18, 19, 20]
        )
    }

    func testWheelSelectionClampsToAvailablePages() {
        XCTAssertEqual(PaginationSelectionPolicy.clampedPage(-4, totalPages: 20), 1)
        XCTAssertEqual(PaginationSelectionPolicy.clampedPage(7, totalPages: 20), 7)
        XCTAssertEqual(PaginationSelectionPolicy.clampedPage(999, totalPages: 20), 20)
        XCTAssertEqual(PaginationSelectionPolicy.clampedPage(4, totalPages: 0), 1)
    }

    func testWheelAnchorsKeepFirstCurrentAndLastWithoutDuplicates() {
        XCTAssertEqual(
            PaginationSelectionPolicy.anchorPages(currentPage: 10, totalPages: 20),
            [1, 10, 20]
        )
        XCTAssertEqual(
            PaginationSelectionPolicy.anchorPages(currentPage: 1, totalPages: 4),
            [1, 4]
        )
        XCTAssertEqual(
            PaginationSelectionPolicy.anchorPages(currentPage: 1, totalPages: 1),
            [1]
        )
    }
}
