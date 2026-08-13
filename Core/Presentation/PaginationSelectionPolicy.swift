import Foundation

enum PaginationSelectionPolicy {
    static func page(from input: String, totalPages: Int) -> Int? {
        let input = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty,
              input.unicodeScalars.allSatisfy({ (48...57).contains($0.value) }),
              let value = Int(input) else {
            return nil
        }

        return min(max(1, value), max(1, totalPages))
    }

    static func quickPages(currentPage: Int, totalPages: Int) -> [Int] {
        let totalPages = max(1, totalPages)
        let currentPage = min(max(1, currentPage), totalPages)
        let windowSize = min(5, totalPages)
        let latestStart = max(1, totalPages - windowSize + 1)
        let windowStart = min(max(1, currentPage - 2), latestStart)

        var pages: Set<Int> = [1, totalPages]
        for page in windowStart..<(windowStart + windowSize) {
            pages.insert(page)
        }
        return pages.sorted()
    }
}
