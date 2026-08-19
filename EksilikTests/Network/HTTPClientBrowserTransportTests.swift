import XCTest
@testable import EksilikApp

final class HTTPClientBrowserTransportTests: XCTestCase {
    override func tearDown() {
        BrowserTransportURLProtocol.handler = nil
        super.tearDown()
    }

    func testFetchHTMLUsesVerifiedBrowserTransportBeforeURLSession() async throws {
        BrowserTransportURLProtocol.handler = { _ in
            XCTFail("URLSession should not run when browser transport succeeds")
            throw URLError(.badServerResponse)
        }
        let client = HTTPClient(
            session: makeSession(),
            browserFetch: { _ in
                BrowserFetchResponse(
                    data: Data("<html><body>browser</body></html>".utf8),
                    statusCode: 200,
                    headers: ["content-type": "text/html"]
                )
            }
        )

        let html = try await client.fetchHTML(for: .popular)

        XCTAssertEqual(html, "<html><body>browser</body></html>")
    }

    func testFetchHTMLFallsBackToURLSessionWhenWebKitIsUnavailable() async throws {
        BrowserTransportURLProtocol.handler = { request in
            let response = try XCTUnwrap(HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: "HTTP/2",
                headerFields: ["Content-Type": "text/html"]
            ))
            return (response, Data("<html><body>fallback</body></html>".utf8))
        }
        let client = HTTPClient(
            session: makeSession(),
            browserFetch: { _ in throw BrowserFetchTransportError.invalidResponse }
        )

        let html = try await client.fetchHTML(for: .popular)

        XCTAssertEqual(html, "<html><body>fallback</body></html>")
    }

    func testFetchJSONUsesVerifiedBrowserTransport() async throws {
        let expected = Data("{\"ok\":true}".utf8)
        let client = HTTPClient(
            session: makeSession(),
            browserFetch: { _ in
                BrowserFetchResponse(
                    data: expected,
                    statusCode: 200,
                    headers: ["content-type": "application/json"]
                )
            }
        )

        let data = try await client.fetchJSON(for: .popular)

        XCTAssertEqual(data, expected)
    }

    func testPostUsesVerifiedBrowserTransportAndPreservesResponseStatus() async throws {
        let client = HTTPClient(
            session: makeSession(),
            browserFetch: { request in
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertNotNil(request.httpBody)
                return BrowserFetchResponse(
                    data: Data("ok".utf8),
                    statusCode: 201,
                    headers: ["content-type": "text/plain"]
                )
            }
        )

        let (data, response) = try await client.post(
            endpoint: .favoriteEntry,
            body: ["entryId": "123"]
        )

        XCTAssertEqual(String(decoding: data, as: UTF8.self), "ok")
        XCTAssertEqual(response.statusCode, 201)
    }

    func testChallengeResponseDoesNotRetryThroughURLSession() async throws {
        BrowserTransportURLProtocol.handler = { _ in
            XCTFail("A valid browser response must not be replayed through URLSession")
            throw URLError(.badServerResponse)
        }
        let client = HTTPClient(
            session: makeSession(),
            browserFetch: { _ in
                BrowserFetchResponse(
                    data: Data("<html>challenge</html>".utf8),
                    statusCode: 403,
                    headers: ["CF-Mitigated": "challenge"]
                )
            }
        )

        do {
            _ = try await client.fetchHTML(for: .popular)
            XCTFail("Expected Cloudflare response to map to cloudflareBlocked")
        } catch NetworkError.cloudflareBlocked {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BrowserTransportURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class BrowserTransportURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
