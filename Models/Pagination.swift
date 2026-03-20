import Foundation

struct Pagination: Equatable {
    let currentPage: Int
    let totalPages: Int

    var hasNextPage: Bool { currentPage < totalPages }
    var hasPreviousPage: Bool { currentPage > 1 }

    static let empty = Pagination(currentPage: 1, totalPages: 1)
}
