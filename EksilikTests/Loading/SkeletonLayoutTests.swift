import XCTest
@testable import EksilikApp

final class SkeletonLayoutTests: XCTestCase {
    func testTopicWidthsAreDeterministicAndBounded() {
        let firstPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))
        let secondPass = (0..<24).map(SkeletonLayout.topicTitleFraction(row:))

        XCTAssertEqual(firstPass, secondPass)
        XCTAssertTrue(firstPass.allSatisfy { (0.45...0.90).contains($0) })
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
