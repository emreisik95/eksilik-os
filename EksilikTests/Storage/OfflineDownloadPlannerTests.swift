import XCTest
@testable import EksilikApp

final class OfflineDownloadPlannerTests: XCTestCase {
    func testLimitsClampToAvailablePages() {
        XCTAssertEqual(OfflineDownloadPlanner.pages(for: .fivePages, totalPages: 3), [1, 2, 3])
        XCTAssertEqual(OfflineDownloadPlanner.pages(for: .fivePages, totalPages: 12), Array(1...5))
        XCTAssertEqual(OfflineDownloadPlanner.pages(for: .tenPages, totalPages: 12), Array(1...10))
        XCTAssertEqual(OfflineDownloadPlanner.pages(for: .allPages, totalPages: 12), Array(1...12))
    }

    func testMediaFilenamesAreStableAndDistinct() {
        let first = OfflineMediaKey.filename(for: "https://cdn.example.com/a.jpg")
        XCTAssertEqual(first, OfflineMediaKey.filename(for: "https://cdn.example.com/a.jpg"))
        XCTAssertNotEqual(first, OfflineMediaKey.filename(for: "https://cdn.example.com/b.jpg"))
    }
}
