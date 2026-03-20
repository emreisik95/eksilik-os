import Foundation

struct EksiRouter {
    static let baseURL = "https://eksisozluk.com"

    static let defaultHeaders: [String: String] = [
        "X-Requested-With": "XMLHttpRequest",
        "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
        "Accept-Encoding": "gzip, deflate, br",
        "User-Agent": "Mozilla/5.0 (Linux; U; Android 11; en-gb; V2026 Build/RP1A.200720.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.7559.132 Mobile Safari/537.36 PHX/20.7"
    ]

    static func buildRequest(
        for endpoint: EksiEndpoint,
        body: [String: String]? = nil,
        csrfToken: String? = nil
    ) throws -> URLRequest {
        var urlString = baseURL + endpoint.path

        if let queryItems = endpoint.queryItems {
            var components = URLComponents(string: urlString)
            let existing = components?.queryItems ?? []
            components?.queryItems = existing + queryItems
            guard let url = components?.url else { throw NetworkError.invalidURL }
            urlString = url.absoluteString
        }

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 15

        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body {
            var params = body
            if let csrfToken {
                params["__RequestVerificationToken"] = csrfToken
            }
            let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
