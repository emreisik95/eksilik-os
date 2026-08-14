import Foundation

struct SeylerService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchStories(category: SeylerCategory) async throws -> [SeylerStory] {
        let html = try await fetchHTML(from: SeylerEndpoint.url(for: category))
        return SeylerParser.parse(html: html)
    }

    func fetchArticle(url: URL) async throws -> SeylerArticle {
        guard let normalizedURL = SeylerEndpoint.articleURL(from: url.absoluteString) else {
            throw NetworkError.invalidURL
        }
        let html = try await fetchHTML(from: normalizedURL)
        guard let article = SeylerArticleParser.parse(html: html, sourceURL: normalizedURL) else {
            throw NetworkError.decodingFailed
        }
        return article
    }

    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
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

        return html
    }
}
