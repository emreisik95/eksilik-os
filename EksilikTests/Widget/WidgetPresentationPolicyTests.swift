import XCTest
@testable import EksilikApp

final class WidgetPresentationPolicyTests: XCTestCase {
    func testSmallWidgetShowsOneTopicSoTheTitleCanWrap() {
        XCTAssertEqual(
            WidgetPresentationPolicy.topicLimit(for: .small),
            1
        )
        XCTAssertGreaterThanOrEqual(
            WidgetPresentationPolicy.titleLineLimit(for: .small),
            4
        )
    }

    func testLargerWidgetsRetainTheirFeedDensity() {
        XCTAssertEqual(WidgetPresentationPolicy.topicLimit(for: .medium), 4)
        XCTAssertEqual(WidgetPresentationPolicy.topicLimit(for: .large), 10)
    }
}
