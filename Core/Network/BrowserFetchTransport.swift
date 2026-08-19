import Foundation

enum BrowserFetchTransportError: Error {
    case invalidRequest
    case invalidBody
    case invalidResponse
}

struct BrowserFetchRequest: Equatable, Sendable {
    static let javaScript = """
    const payload = request;
    const options = {
      method: payload.method,
      credentials: 'include',
      redirect: 'follow',
      headers: payload.headers
    };
    if (Object.prototype.hasOwnProperty.call(payload, 'body')) {
      options.body = payload.body;
    }
    const response = await fetch(payload.url, options);
    const headers = {};
    response.headers.forEach((value, key) => { headers[key] = value; });
    return {
      status: response.status,
      headers: headers,
      body: await response.text()
    };
    """

    let url: String
    let method: String
    let headers: [String: String]
    let body: String?

    private static let browserOwnedHeaders: Set<String> = [
        "accept-encoding",
        "connection",
        "content-length",
        "cookie",
        "host",
        "origin",
        "referer",
        "user-agent",
    ]

    init(request: URLRequest) throws {
        guard let url = request.url?.absoluteString else {
            throw BrowserFetchTransportError.invalidRequest
        }

        self.url = url
        method = request.httpMethod ?? "GET"
        headers = (request.allHTTPHeaderFields ?? [:]).filter { key, _ in
            !Self.browserOwnedHeaders.contains(key.lowercased())
        }

        if let data = request.httpBody {
            guard let body = String(data: data, encoding: .utf8) else {
                throw BrowserFetchTransportError.invalidBody
            }
            self.body = body
        } else {
            body = nil
        }
    }

    var javaScriptValue: [String: Any] {
        var value: [String: Any] = [
            "url": url,
            "method": method,
            "headers": headers,
        ]
        if let body {
            value["body"] = body
        }
        return value
    }
}

struct BrowserFetchResponse: Equatable, Sendable {
    let data: Data
    let statusCode: Int
    let headers: [String: String]

    static func decode(_ value: Any) throws -> BrowserFetchResponse {
        guard let dictionary = value as? [String: Any],
              let statusNumber = dictionary["status"] as? NSNumber,
              let body = dictionary["body"] as? String else {
            throw BrowserFetchTransportError.invalidResponse
        }

        let rawHeaders = dictionary["headers"] as? [String: Any] ?? [:]
        let headers = rawHeaders.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }
        return BrowserFetchResponse(
            data: Data(body.utf8),
            statusCode: statusNumber.intValue,
            headers: headers
        )
    }

    var isCloudflareChallenge: Bool {
        WebBootstrapPolicy.isChallenge(
            statusCode: statusCode,
            headers: headers,
            title: "",
            html: String(data: data, encoding: .utf8) ?? ""
        )
    }
}
