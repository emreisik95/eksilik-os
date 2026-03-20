import XCTest
@testable import EksilikApp

final class AuthParserTests: XCTestCase {

    func testLoggedOutState() {
        let html = """
        <a id="top-login-link">giris</a>
        """

        let state = AuthParser.parseAuthState(html: html)
        XCTAssertFalse(state.isLoggedIn)
        XCTAssertNil(state.username)
    }

    func testLoggedInState() {
        let html = """
        <li class="buddy mobile-only"><a href="/biri/testuser">testuser</a></li>
        <li class="not-mobile"><a title="testuser">testuser</a></li>
        """

        let state = AuthParser.parseAuthState(html: html)
        XCTAssertTrue(state.isLoggedIn)
        XCTAssertEqual(state.username, "testuser")
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
