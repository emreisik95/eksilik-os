import Foundation

struct MessageService {
    private let client = HTTPClient.shared

    func fetchMessages(page: Int? = nil) async throws -> (threads: [MessageThread], pagination: Pagination) {
        let html = try await client.fetchHTML(for: .messages(page: page))
        let threads = MessageParser.parseThreadList(html: html)
        let pagination = PaginationParser.parse(html: html)
        return (threads, pagination)
    }
}
