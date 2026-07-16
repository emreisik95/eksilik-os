import XCTest
@testable import EksilikApp

final class TopicRequestTests: XCTestCase {
    func testChangingPagePreservesTodayScope() {
        let request = TopicRequest(link: "/ornek-baslik--42?day=2026-07-16")

        XCTAssertEqual(
            request.settingPage(8).pathAndQuery,
            "ornek-baslik--42?day=2026-07-16&p=8"
        )
    }

    func testChangingPagePreservesNicePeriod() {
        let request = TopicRequest(link: "/ornek-baslik--42?a=nice&period=week&p=2")

        XCTAssertEqual(
            request.settingPage(9).pathAndQuery,
            "ornek-baslik--42?a=nice&period=week&p=9"
        )
    }

    func testChangingPageRemovesDuplicatePageItems() {
        let request = TopicRequest(link: "/ornek?p=1&a=search&author=test&p=3")
        let result = request.settingPage(4).pathAndQuery

        XCTAssertEqual(result.components(separatedBy: "p=").count - 1, 1)
        XCTAssertTrue(result.contains("a=search"))
        XCTAssertTrue(result.contains("author=test"))
        XCTAssertTrue(result.hasSuffix("p=4"))
    }

    func testAbsoluteLinkIsNormalized() {
        let request = TopicRequest(link: "https://eksisozluk.com/ornek--42?a=find&keywords=swift")

        XCTAssertEqual(request.pathAndQuery, "ornek--42?a=find&keywords=swift")
    }

    func testFilterValuesAreSafelyEncoded() {
        let request = TopicRequest(link: "/ornek--42?day=2026-07-16")
            .applying(filter: .author("a&b"))

        XCTAssertEqual(request.pathAndQuery, "ornek--42?a=search&author=a%26b")
    }

    func testAgendaPageEndpointIncludesRequestedPage() {
        XCTAssertEqual(EksiEndpoint.popularPage(page: 3).path, "/basliklar/gundem?p=3")
    }

    func testCanonicalTopicReplacementPreservesIDFilterAndPage() {
        let request = TopicRequest(link: "/eski-baslik--42?a=popular")
            .replacingTopic(slug: "yeni-baslik", id: "42")
            .settingPage(105)

        XCTAssertEqual(request.pathAndQuery, "yeni-baslik--42?a=popular&p=105")
    }

    func testCanonicalTopicReplacementDoesNotDuplicateID() {
        let request = TopicRequest(link: "/eski-baslik--42?day=2026-07-16")
            .replacingTopic(slug: "yeni-baslik--42", id: "42")

        XCTAssertEqual(request.pathAndQuery, "yeni-baslik--42?day=2026-07-16")
    }
}
