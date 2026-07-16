import XCTest
@testable import EksilikApp

final class SkeletonLayoutTests: XCTestCase {
    func testTopicWidthsAreDeterministicAndBounded() {
        let firstPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))
        let secondPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))

        XCTAssertEqual(firstPass, secondPass)
        XCTAssertTrue(firstPass.allSatisfy { (0.45...0.90).contains($0) })
    }

    func testRowCountCoversTallViewportWithOverscan() {
        let count = SkeletonLayout.rowCount(
            viewportHeight: 874,
            reservedHeight: 184,
            estimatedRowHeight: 92,
            minimumRows: 5
        )

        XCTAssertGreaterThanOrEqual(count, 9)
        XCTAssertGreaterThanOrEqual(Double(count) * 92, 874 - 184)
    }

    func testRowCountKeepsMinimumForShortViewport() {
        XCTAssertEqual(
            SkeletonLayout.rowCount(
                viewportHeight: 320,
                reservedHeight: 200,
                estimatedRowHeight: 100,
                minimumRows: 5
            ),
            5
        )
    }

    func testPageMergePreservesOrderAndRemovesDuplicates() {
        let existing = [
            Topic(id: "1", title: "bir", slug: "bir", entryCount: "1", link: "/bir"),
            Topic(id: "2", title: "iki", slug: "iki", entryCount: "2", link: "/iki"),
        ]
        let incoming = [
            Topic(id: "2", title: "iki", slug: "iki", entryCount: "2", link: "/iki"),
            Topic(id: "3", title: "uc", slug: "uc", entryCount: "3", link: "/uc"),
        ]

        XCTAssertEqual(
            TopicPageMerger.merge(existing: existing, incoming: incoming).map(\.id),
            ["1", "2", "3"]
        )
    }
}
