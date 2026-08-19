import XCTest
@testable import EksilikApp

final class BrowserFetchTransportTests: XCTestCase {
    func testPayloadPreservesMethodBodyAndApplicationHeaders() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://eksisozluk.com/entry/ekle")))
        request.httpMethod = "POST"
        request.httpBody = "content=merhaba".data(using: .utf8)
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("fake-browser", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, br", forHTTPHeaderField: "Accept-Encoding")

        let payload = try BrowserFetchRequest(request: request)

        XCTAssertEqual(payload.url, "https://eksisozluk.com/entry/ekle")
        XCTAssertEqual(payload.method, "POST")
        XCTAssertEqual(payload.body, "content=merhaba")
        XCTAssertEqual(payload.headers["X-Requested-With"], "XMLHttpRequest")
        XCTAssertEqual(
            payload.headers["Content-Type"],
            "application/x-www-form-urlencoded; charset=utf-8"
        )
        XCTAssertNil(payload.headers["User-Agent"])
        XCTAssertNil(payload.headers["Accept-Encoding"])
    }

    func testResponseDecoderAcceptsWebKitDictionaryValues() throws {
        let response = try BrowserFetchResponse.decode([
            "status": NSNumber(value: 200),
            "headers": [
                "content-type": "text/html; charset=utf-8",
                "x-test": "ok",
            ],
            "body": "<html><body>gündem</body></html>",
        ])

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["content-type"], "text/html; charset=utf-8")
        XCTAssertEqual(String(data: response.data, encoding: .utf8), "<html><body>gündem</body></html>")
    }

    func testResponseIdentifiesCloudflareChallengeCaseInsensitively() throws {
        let response = try BrowserFetchResponse.decode([
            "status": NSNumber(value: 403),
            "headers": ["CF-Mitigated": "Challenge"],
            "body": "<html><script>window._cf_chl_opt = {};</script></html>",
        ])

        XCTAssertTrue(response.isCloudflareChallenge)
    }

    func testJavaScriptFetchUsesTheVerifiedBrowserSession() {
        XCTAssertTrue(BrowserFetchRequest.javaScript.contains("credentials: 'include'"))
        XCTAssertTrue(BrowserFetchRequest.javaScript.contains("redirect: 'follow'"))
        XCTAssertTrue(BrowserFetchRequest.javaScript.contains("response.headers.forEach"))
        XCTAssertTrue(BrowserFetchRequest.javaScript.contains("await response.text()"))
        XCTAssertFalse(
            BrowserFetchRequest.javaScript.contains("const request ="),
            "callAsyncJavaScript injects request as an argument; redeclaring it throws"
        )
    }
}
