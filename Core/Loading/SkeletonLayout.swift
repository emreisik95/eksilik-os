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

    private static func positiveIndex(_ value: Int, count: Int) -> Int {
        let remainder = value % count
        return remainder >= 0 ? remainder : remainder + count
    }
}

enum TopicPageMerger {
    static func merge(existing: [Topic], incoming: [Topic]) -> [Topic] {
        var seen = Set(existing.map(\.id))
        return existing + incoming.filter { seen.insert($0.id).inserted }
    }
}
