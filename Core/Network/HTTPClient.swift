import Foundation

actor HTTPClient {
    static let shared = HTTPClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String {
        let request = try EksiRouter.buildRequest(for: endpoint)
        print("📡 GET \(request.url?.absoluteString ?? "nil")")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(statusCode: 0)
        }

        print("📡 \(httpResponse.statusCode) \(request.url?.path ?? "")")

        switch httpResponse.statusCode {
        case 200...299:
            guard let html = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingFailed
            }
            return html
        case 401:
            throw NetworkError.unauthorized
        case 403:
            // eksisozluk may return 403 with a paywall popup but still include
            // actual page content underneath. Return the HTML when content markers
            // are present so parsers can extract it normally.
            if let html = String(data: data, encoding: .utf8),
               html.contains("entry-item-list") || html.contains("topic-list") {
                return html
            }
            if let html = String(data: data, encoding: .utf8),
               html.contains("open-subscription-popup") || html.contains("reklamsız üyeliğe") {
                throw NetworkError.paywall
            }
            throw NetworkError.cloudflareBlocked
        case 503:
            throw NetworkError.cloudflareBlocked
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        default:
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }

    func fetchJSON(for endpoint: EksiEndpoint) async throws -> Data {
        let request = try EksiRouter.buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw NetworkError.rateLimited
            }
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }

        return data
    }

    @discardableResult
    func post(
        endpoint: EksiEndpoint,
        body: [String: String],
        csrfToken: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try EksiRouter.buildRequest(for: endpoint, body: body, csrfToken: csrfToken)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.requestFailed(statusCode: 0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return (data, httpResponse)
        case 404:
            throw NetworkError.requestFailed(statusCode: 404)
        case 429:
            throw NetworkError.rateLimited
        default:
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
