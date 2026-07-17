import Foundation

enum PaginationControl: String, CaseIterable, Identifiable, Sendable {
    case first
    case previous
    case next
    case last

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .first: return "backward.end.fill"
        case .previous: return "chevron.left"
        case .next: return "chevron.right"
        case .last: return "forward.end.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .first: return "ilk sayfaya git"
        case .previous: return "önceki sayfaya git"
        case .next: return "sonraki sayfaya git"
        case .last: return "son sayfaya git"
        }
    }

    func targetPage(in pagination: Pagination) -> Int {
        switch self {
        case .first:
            return 1
        case .previous:
            return max(1, pagination.currentPage - 1)
        case .next:
            return min(max(1, pagination.totalPages), pagination.currentPage + 1)
        case .last:
            return max(1, pagination.totalPages)
        }
    }

    func isEnabled(in pagination: Pagination) -> Bool {
        switch self {
        case .first, .previous:
            return pagination.hasPreviousPage
        case .next, .last:
            return pagination.hasNextPage
        }
    }
}

enum EntryListChromePolicy {
    static let paginationButtonSize = 48.0
    static let paginationControlSpacing = 14.0
    static let paginationSectionSpacing = 8.0
    static let leadingPaginationControls: [PaginationControl] = [.first, .previous]
    static let trailingPaginationControls: [PaginationControl] = [.next, .last]
    static let filterSwipeOnboardingStorageKey = "hasSeenEntryFilterSwipeOnboardingV2"

    static func shouldPresentFilterSwipeOnboarding(hasSeen: Bool) -> Bool {
        !hasSeen
    }
}
