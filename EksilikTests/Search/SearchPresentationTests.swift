import XCTest
@testable import EksilikApp

final class SearchPresentationTests: XCTestCase {
    func testScreenStateDistinguishesDiscoveryGuidanceAndLoading() {
        XCTAssertEqual(
            SearchPresentation.state(query: "", isSearching: false, titleCount: 0, nickCount: 0, error: nil),
            .discovery
        )
        XCTAssertEqual(
            SearchPresentation.state(query: "a", isSearching: false, titleCount: 0, nickCount: 0, error: nil),
            .needsMoreCharacters
        )
        XCTAssertEqual(
            SearchPresentation.state(query: "arama", isSearching: true, titleCount: 0, nickCount: 0, error: nil),
            .loading
        )
    }

    func testScreenStateDistinguishesResultsEmptyAndFailure() {
        XCTAssertEqual(
            SearchPresentation.state(query: "arama", isSearching: false, titleCount: 2, nickCount: 0, error: nil),
            .results
        )
        XCTAssertEqual(
            SearchPresentation.state(query: "arama", isSearching: false, titleCount: 0, nickCount: 0, error: nil),
            .empty
        )
        XCTAssertEqual(
            SearchPresentation.state(query: "arama", isSearching: false, titleCount: 0, nickCount: 0, error: "bağlantı yok"),
            .failure
        )
    }

    func testResolveSupportsEntryAuthorAndTopicQueries() {
        XCTAssertEqual(SearchPresentation.resolve(query: " #123 "), .entry(id: "123"))
        XCTAssertEqual(SearchPresentation.resolve(query: "@sherlockun besinci sezonu"), .profile(username: "sherlockun besinci sezonu"))
        XCTAssertEqual(
            SearchPresentation.resolve(query: "swift & ios"),
            .topic(link: "swift%20&%20ios", title: "swift & ios")
        )
    }

    func testResolveRejectsEmptyPrefixOnlyAndMalformedEntryQueries() {
        XCTAssertNil(SearchPresentation.resolve(query: "   "))
        XCTAssertNil(SearchPresentation.resolve(query: "@"))
        XCTAssertNil(SearchPresentation.resolve(query: "#abc"))
    }
}
