import Foundation

struct TopicService {
    private let client = HTTPClient.shared

    func fetchPopularTopics(isBlocked: ((String) -> Bool)? = nil) async throws -> [Topic] {
        let html = try await client.fetchHTML(for: .popular)
        await SessionManager.shared.updateFromHTML(html)
        return TopicListParser.parse(html: html, isBlocked: isBlocked)
    }

    func fetchTodayTopics(page: Int = 1, isBlocked: ((String) -> Bool)? = nil) async throws -> [Topic] {
        let html = try await client.fetchHTML(for: .today(page: page))
        await SessionManager.shared.updateFromHTML(html)
        return TopicListParser.parse(html: html, isBlocked: isBlocked)
    }

    func fetchFromEndpoint(_ endpoint: EksiEndpoint, isBlocked: ((String) -> Bool)? = nil) async throws -> [Topic] {
        let html = try await client.fetchHTML(for: endpoint)
        await SessionManager.shared.updateFromHTML(html)
        return TopicListParser.parse(html: html, isBlocked: isBlocked)
    }

    func fetchPopularTopicsPaginated(page: Int, isBlocked: ((String) -> Bool)? = nil) async throws -> (topics: [Topic], pagination: Pagination) {
        let endpoint = EksiEndpoint.popular
        let html = try await client.fetchHTML(for: endpoint)
        await SessionManager.shared.updateFromHTML(html)
        let topics = TopicListParser.parse(html: html, isBlocked: isBlocked)
        let pagination = PaginationParser.parse(html: html)
        return (topics, pagination)
    }
}
