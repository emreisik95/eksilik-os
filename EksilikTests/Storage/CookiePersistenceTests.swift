import XCTest
@testable import EksilikApp

final class CookiePersistenceTests: XCTestCase {
    func testClearDeletesEksiCookiesWithoutDeletingOtherDomains() throws {
        let eksiName = "eksi-test-\(UUID().uuidString)"
        let otherName = "other-test-\(UUID().uuidString)"
        let eksiCookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: ".eksisozluk.com",
            .path: "/",
            .name: eksiName,
            .value: "secret",
            .secure: "TRUE",
        ]))
        let otherCookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: ".example.com",
            .path: "/",
            .name: otherName,
            .value: "keep",
            .secure: "TRUE",
        ]))
        HTTPCookieStorage.shared.setCookie(eksiCookie)
        HTTPCookieStorage.shared.setCookie(otherCookie)
        defer { HTTPCookieStorage.shared.deleteCookie(otherCookie) }

        CookiePersistence.clear()

        XCTAssertFalse(HTTPCookieStorage.shared.cookies?.contains(where: { $0.name == eksiName }) ?? false)
        XCTAssertTrue(HTTPCookieStorage.shared.cookies?.contains(where: { $0.name == otherName }) ?? false)
    }
}
