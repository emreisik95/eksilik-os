import Foundation

actor HTTPClient {
    typealias BrowserFetch = @Sendable (URLRequest) async throws -> BrowserFetchResponse

    static let shared = HTTPClient()

    private let session: URLSession
    private let browserFetch: BrowserFetch

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
        browserFetch = { request in
            try await WebViewFetcher.shared.fetch(request)
        }
    }

    init(session: URLSession, browserFetch: @escaping BrowserFetch) {
        self.session = session
        self.browserFetch = browserFetch
    }

    func fetchHTML(for endpoint: EksiEndpoint) async throws -> String {
        let request = try EksiRouter.buildRequest(for: endpoint)
        print("📡 GET \(request.url?.absoluteString ?? "nil")")
        let response = try await perform(request)

        print("📡 \(response.statusCode) \(request.url?.path ?? "")")

        switch response.statusCode {
        case 200...299:
            guard let html = String(data: response.data, encoding: .utf8) else {
                throw NetworkError.decodingFailed
            }
            return html
        case 401:
            throw NetworkError.unauthorized
        case 403:
            // eksisozluk may return 403 with a paywall popup but still include
            // actual page content underneath. Return the HTML when content markers
            // are present so parsers can extract it normally.
            if let html = String(data: response.data, encoding: .utf8),
               html.contains("entry-item-list") || html.contains("topic-list") {
                return html
            }
            if let html = String(data: response.data, encoding: .utf8),
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
            throw NetworkError.requestFailed(statusCode: response.statusCode)
        }
    }

    func fetchJSON(for endpoint: EksiEndpoint) async throws -> Data {
        let request = try EksiRouter.buildRequest(for: endpoint)
        let response = try await perform(request)

        guard (200...299).contains(response.statusCode) else {
            if response.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            if response.statusCode == 403 || response.statusCode == 503 {
                throw NetworkError.cloudflareBlocked
            }
            if response.statusCode == 429 {
                throw NetworkError.rateLimited
            }
            throw NetworkError.requestFailed(statusCode: response.statusCode)
        }

        return response.data
    }

    @discardableResult
    func post(
        endpoint: EksiEndpoint,
        body: [String: String],
        csrfToken: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try EksiRouter.buildRequest(for: endpoint, body: body, csrfToken: csrfToken)
        let response = try await perform(request)

        switch response.statusCode {
        case 200...299:
            return (response.data, try makeHTTPResponse(from: response, for: request))
        case 401:
            throw NetworkError.unauthorized
        case 403, 503:
            throw NetworkError.cloudflareBlocked
        case 404:
            throw NetworkError.requestFailed(statusCode: 404)
        case 429:
            throw NetworkError.rateLimited
        default:
            throw NetworkError.requestFailed(statusCode: response.statusCode)
        }
    }

    private func perform(_ request: URLRequest) async throws -> BrowserFetchResponse {
        do {
            return try await browserFetch(request)
        } catch {
            // WebKit is the primary transport because Cloudflare binds clearance
            // to that browser context. URLSession remains a last-resort fallback
            // for environments where WebKit cannot be initialized.
            print("🌐 Browser transport unavailable; falling back to URLSession")
            let (data, rawResponse) = try await session.data(for: request)
            guard let response = rawResponse as? HTTPURLResponse else {
                throw NetworkError.requestFailed(statusCode: 0)
            }
            let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                guard let key = pair.key as? String else { return }
                result[key] = String(describing: pair.value)
            }
            return BrowserFetchResponse(
                data: data,
                statusCode: response.statusCode,
                headers: headers
            )
        }
    }

    private func makeHTTPResponse(
        from response: BrowserFetchResponse,
        for request: URLRequest
    ) throws -> HTTPURLResponse {
        guard let url = request.url,
              let httpResponse = HTTPURLResponse(
                  url: url,
                  statusCode: response.statusCode,
                  httpVersion: "HTTP/2",
                  headerFields: response.headers
              ) else {
            throw NetworkError.requestFailed(statusCode: 0)
        }
        return httpResponse
    }
}
