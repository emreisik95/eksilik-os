import XCTest
@testable import EksilikApp

final class InternalLinkPolicyTests: XCTestCase {
    func testTopicLookupUsesQueryEncodingInsteadOfInventingASlug() {
        XCTAssertEqual(
            InternalLinkPolicy.topicLookupLink(for: "swift & ios"),
            "?q=swift%20%26%20ios"
        )
        XCTAssertEqual(
            InternalLinkPolicy.topicLookupLink(for: "valla mı lan"),
            "?q=valla%20m%C4%B1%20lan"
        )
    }

    func testBkzURLsResolveThroughCanonicalTopicLookup() {
        XCTAssertEqual(
            InternalLinkPolicy.destination(
                for: "applewebdata://5E9E913A-50CE-4B18-8504-A9F1669BE324/?q=valla%20mi%20lan"
            ),
            .topicLookup(query: "valla mi lan")
        )
        XCTAssertEqual(
            InternalLinkPolicy.destination(for: "/?q=swift+ios"),
            .topicLookup(query: "swift ios")
        )
    }

    func testKnownInternalPathsResolveToTypedDestinations() {
        XCTAssertEqual(
            InternalLinkPolicy.destination(for: "https://eksisozluk.com/biri/sherlockun%20besinci%20sezonu"),
            .profile(username: "sherlockun besinci sezonu")
        )
        XCTAssertEqual(
            InternalLinkPolicy.destination(for: "/entry/12345"),
            .entry(id: "12345")
        )
        XCTAssertEqual(
            InternalLinkPolicy.destination(for: "/sherlockun-besinci-sezonu--5088471?a=nice"),
            .topic(link: "sherlockun-besinci-sezonu--5088471?a=nice")
        )
    }

    func testMalformedAndExternalLinksAreRejected() {
        XCTAssertNil(InternalLinkPolicy.destination(for: ""))
        XCTAssertNil(InternalLinkPolicy.destination(for: "/?q="))
        XCTAssertNil(InternalLinkPolicy.destination(for: "javascript:alert(1)"))
        XCTAssertNil(InternalLinkPolicy.destination(for: "https://example.com/entry/123"))
        XCTAssertNil(InternalLinkPolicy.destination(for: "//example.com/entry/123"))
        XCTAssertNil(InternalLinkPolicy.destination(for: "/entry/not-a-number"))
    }
}
