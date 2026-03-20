import Foundation

struct SearchService {
    private let client = HTTPClient.shared

    func search(query: String) async throws -> SearchResult {
        let data = try await client.fetchJSON(for: .autocomplete(query: query))
        return SearchResultParser.parse(data: data)
    }
}
