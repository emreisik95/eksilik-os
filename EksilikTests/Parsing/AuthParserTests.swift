import XCTest
#if canImport(EksilikApp)
@testable import EksilikApp
#else
@testable import EksilikCore
#endif

final class AuthParserTests: XCTestCase {

    func testLoggedOutState() {
        let html = """
        <a id="top-login-link">giris</a>
        """

        let state = AuthParser.parseAuthState(html: html)
        XCTAssertFalse(state.isLoggedIn)
        XCTAssertNil(state.username)
        XCTAssertFalse(state.isIndeterminate)
    }

    func testLoggedInState() {
        let html = """
        <li class="buddy mobile-only"><a href="/biri/testuser">testuser</a></li>
        <li class="not-mobile"><a title="testuser">testuser</a></li>
        """

        let state = AuthParser.parseAuthState(html: html)
        XCTAssertTrue(state.isLoggedIn)
        XCTAssertEqual(state.username, "testuser")
        XCTAssertFalse(state.isIndeterminate)
    }

    func testPageWithoutAuthNavigationIsIndeterminate() {
        let state = AuthParser.parseAuthState(html: "<main>entry içeriği</main>")

        XCTAssertTrue(state.isIndeterminate)
    }

    func testLoginReturnURLRecognition() {
        XCTAssertTrue(LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://eksisozluk.com/")!))
        XCTAssertTrue(LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://eksisozluk.com/?returnUrl=%2F")!))
        XCTAssertFalse(LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://eksisozluk.com/giris")!))
        XCTAssertFalse(LoginFlowPolicy.isSuccessfulReturnURL(URL(string: "https://example.com/")!))
    }

    func testLoginRequiresAnAuthenticationCookie() {
        let authCookie = HTTPCookie(properties: [
            .domain: ".eksisozluk.com",
            .path: "/",
            .name: ".AspNetCore.Cookies",
            .value: "session-token",
        ])!
        let unrelatedCookie = HTTPCookie(properties: [
            .domain: ".eksisozluk.com",
            .path: "/",
            .name: "theme",
            .value: "dark",
        ])!

        XCTAssertTrue(LoginFlowPolicy.hasAuthCookie(in: [authCookie]))
        XCTAssertFalse(LoginFlowPolicy.hasAuthCookie(in: [unrelatedCookie]))
    }

    func testAuthenticatedLoginPageCompletesWithoutRootRedirect() {
        let html = """
        <li class="buddy mobile-only">
          <a href="/biri/testuser">testuser</a>
        </li>
        """

        let completion = LoginFlowPolicy.completion(
            for: URL(string: "https://eksisozluk.com/giris")!,
            html: html
        )

        XCTAssertEqual(completion, .authenticated(username: "testuser"))
    }

    func testLoginFormWithoutSessionDoesNotComplete() {
        let completion = LoginFlowPolicy.completion(
            for: URL(string: "https://eksisozluk.com/giris")!,
            html: #"<a id="top-login-link">giriş</a>"#
        )

        XCTAssertNil(completion)
    }

    func testCSRFToken() {
        let html = """
        <input name="__RequestVerificationToken" value="abc123token" />
        """

        let token = AuthParser.parseCSRFToken(html: html)
        XCTAssertEqual(token, "abc123token")
    }

    func testUnreadMessages() {
        let html = """
        <li class="messages mobile-only"><a><svg class="green"></svg></a></li>
        """

        let state = AuthParser.parseAuthState(html: html)
        XCTAssertTrue(state.hasUnreadMessages)
    }

    func testFormFields() {
        let html = """
        <input name="__RequestVerificationToken" value="token123" />
        <input name="Title" value="test baslik" />
        <input name="Id" value="456" />
        <input name="ReturnUrl" value="/test" />
        """

        let fields = AuthParser.parseEntryFormFields(html: html)
        XCTAssertNotNil(fields)
        XCTAssertEqual(fields?.token, "token123")
        XCTAssertEqual(fields?.title, "test baslik")
        XCTAssertEqual(fields?.id, "456")
    }
}
