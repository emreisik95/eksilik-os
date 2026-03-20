import XCTest
@testable import EksilikApp

final class PaginationParserTests: XCTestCase {

    func testParseEmptyHTML() {
        let pagination = PaginationParser.parse(html: "")
        XCTAssertEqual(pagination, .empty)
    }

    func testParsePagination() {
        let html = """
        <div class="pager" data-currentpage="3" data-pagecount="10"></div>
        """

        let pagination = PaginationParser.parse(html: html)
        XCTAssertEqual(pagination.currentPage, 3)
        XCTAssertEqual(pagination.totalPages, 10)
        XCTAssertTrue(pagination.hasNextPage)
        XCTAssertTrue(pagination.hasPreviousPage)
    }

    func testFirstPage() {
        let html = """
        <div class="pager" data-currentpage="1" data-pagecount="5"></div>
        """

        let pagination = PaginationParser.parse(html: html)
        XCTAssertFalse(pagination.hasPreviousPage)
        XCTAssertTrue(pagination.hasNextPage)
    }

    func testLastPage() {
        let html = """
        <div class="pager" data-currentpage="5" data-pagecount="5"></div>
        """

        let pagination = PaginationParser.parse(html: html)
        XCTAssertTrue(pagination.hasPreviousPage)
        XCTAssertFalse(pagination.hasNextPage)
    }
}
