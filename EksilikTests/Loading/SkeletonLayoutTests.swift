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

    func testSkeletonPulseIsOpacityOnlyDeterministicAndBounded() {
        let samples = stride(from: 0.0, through: 3.4, by: 0.1).map {
            SkeletonMotionPolicy.opacity(elapsed: $0, reduceMotion: false)
        }

        XCTAssertTrue(samples.allSatisfy { (0.48...1).contains($0) })
        XCTAssertEqual(SkeletonMotionPolicy.opacity(elapsed: 0, reduceMotion: false), 1, accuracy: 0.001)
        XCTAssertEqual(SkeletonMotionPolicy.opacity(elapsed: 0.85, reduceMotion: false), 0.48, accuracy: 0.001)
        XCTAssertEqual(SkeletonMotionPolicy.opacity(elapsed: 1.7, reduceMotion: false), 1, accuracy: 0.001)
    }

    func testSkeletonPulseStopsForReduceMotion() {
        XCTAssertEqual(SkeletonMotionPolicy.opacity(elapsed: 0.85, reduceMotion: true), 1)
    }
}
