import Foundation

struct SeylerService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchStories(category: SeylerCategory) async throws -> [SeylerStory] {
        var request = URLRequest(url: SeylerEndpoint.url(for: category))
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("tr-TR,tr;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(statusCode: 0)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingFailed
        }

        return SeylerParser.parse(html: html)
    }
}
