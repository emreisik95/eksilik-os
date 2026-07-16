import WebKit
import XCTest
@testable import EksilikApp

@MainActor
final class LoginWebViewTests: XCTestCase {
    func testAuthenticatedLoginPageImportsCookiesAndCompletes() async {
        let cookie = HTTPCookie(properties: [
            .domain: "eksisozluk.com",
            .path: "/",
            .name: "a",
            .value: "session-token",
            .secure: "TRUE",
        ])!
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        await cookieStore.setCookie(cookie)

        let completed = expectation(description: "authenticated web session imported")
        var completedUsername: String?
        let coordinator = LoginWebView.Coordinator { username in
            completedUsername = username
            completed.fulfill()
        }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.loadHTMLString(
            """
            <html><body><ul>
              <li class="buddy mobile-only">
                <a href="/biri/testuser">testuser</a>
              </li>
            </ul></body></html>
            """,
            baseURL: URL(string: "https://eksisozluk.com/giris")!
        )

        await fulfillment(of: [completed], timeout: 2)
        XCTAssertEqual(completedUsername, "testuser")

        await cookieStore.delete(cookie)
        HTTPCookieStorage.shared.deleteCookie(cookie)
    }
}
