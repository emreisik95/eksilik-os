import Foundation

enum SkeletonLayout {
    private static let topicFractions: [Double] = [0.72, 0.56, 0.84, 0.64, 0.78, 0.49, 0.88, 0.68]
    private static let entryFractions: [Double] = [0.96, 0.74, 0.87, 0.62]
    private static let profileFractions: [Double] = [0.82, 0.64, 0.91, 0.70, 0.77]

    static func topicTitleFraction(row: Int) -> Double {
        topicFractions[positiveIndex(row, count: topicFractions.count)]
    }

    static func entryLineFraction(row: Int) -> Double {
        entryFractions[positiveIndex(row, count: entryFractions.count)]
    }

    static func profileLineFraction(row: Int) -> Double {
        profileFractions[positiveIndex(row, count: profileFractions.count)]
    }

    static func rowCount(
        viewportHeight: Double,
        reservedHeight: Double = 0,
        estimatedRowHeight: Double,
        minimumRows: Int
    ) -> Int {
        guard estimatedRowHeight > 0 else { return max(0, minimumRows) }
        let availableHeight = max(0, viewportHeight - reservedHeight)
        let rowsToCoverViewport = Int(ceil(availableHeight / estimatedRowHeight)) + 1
        return max(max(0, minimumRows), rowsToCoverViewport)
    }

    private static func positiveIndex(_ value: Int, count: Int) -> Int {
        let remainder = value % count
        return remainder >= 0 ? remainder : remainder + count
    }
}

enum SkeletonMotionPolicy {
    private static let halfCycle = 0.85
    private static let minimumOpacity = 0.48

    static func opacity(elapsed: TimeInterval, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 1 }

        let period = halfCycle * 2
        let positiveElapsed = max(0, elapsed)
        let phase = positiveElapsed.truncatingRemainder(dividingBy: period)
        let progress = phase <= halfCycle
            ? phase / halfCycle
            : (period - phase) / halfCycle
        return 1 - ((1 - minimumOpacity) * min(max(progress, 0), 1))
    }
}

enum TopicPageMerger {
    static func merge(existing: [Topic], incoming: [Topic]) -> [Topic] {
        var seen = Set(existing.map(\.id))
        return existing + incoming.filter { seen.insert($0.id).inserted }
    }
}
