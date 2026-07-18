import XCTest
@testable import EksilikApp

@MainActor
final class WidgetDeepLinkTests: XCTestCase {
    func testQuickAccessSourcesOpenNativeFeeds() throws {
        let expectations: [(String, Route)] = [
            ("gundem", .topicFeed(source: "gundem")),
            ("bugun", .topicFeed(source: "bugun")),
            ("takip", .topicFeed(source: "takip")),
            ("debe", .topicFeed(source: "debe")),
        ]

        for (source, route) in expectations {
            let router = DeepLinkRouter()
            let url = try XCTUnwrap(URL(string: "eksilik://feed?source=\(source)"))

            router.handle(url)

            XCTAssertEqual(router.consumeRoute(), route)
        }
    }

    func testUnknownQuickAccessSourceIsIgnored() throws {
        let router = DeepLinkRouter()

        router.handle(try XCTUnwrap(URL(string: "eksilik://feed?source=bilinmeyen")))

        XCTAssertNil(router.consumeRoute())
    }
}
