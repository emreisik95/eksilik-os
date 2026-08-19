import XCTest
@testable import EksilikApp

final class WebBootstrapPolicyTests: XCTestCase {
    func testTurkishCloudflareChallengeDoesNotCompleteBootstrap() {
        XCTAssertFalse(WebBootstrapPolicy.shouldComplete(
            statusCode: 403,
            headers: ["cf-mitigated": "challenge"],
            title: "ekşi sözlük - lütfen bekleyiniz",
            html: "<html><script src='/cdn-cgi/challenge-platform/h/g/orchestrate/chl_page/v1'></script></html>"
        ))
    }

    func testChallengeHeaderMatchingIsCaseInsensitive() {
        XCTAssertFalse(WebBootstrapPolicy.shouldComplete(
            statusCode: 200,
            headers: ["CF-Mitigated": "Challenge"],
            title: "ekşi sözlük",
            html: "<html><body>challenge</body></html>"
        ))
    }

    func testChallengeDOMDoesNotCompleteWithoutHeader() {
        XCTAssertFalse(WebBootstrapPolicy.shouldComplete(
            statusCode: 200,
            headers: [:],
            title: "ekşi sözlük",
            html: "<html><script>window._cf_chl_opt = { cType: 'non-interactive' };</script></html>"
        ))
    }

    func testSuccessfulSiteDocumentCompletesBootstrap() {
        XCTAssertTrue(WebBootstrapPolicy.shouldComplete(
            statusCode: 200,
            headers: ["content-type": "text/html; charset=utf-8"],
            title: "ekşi sözlük - kutsal bilgi kaynağı",
            html: "<html><body><ul class='topic-list'><li>gündem</li></ul></body></html>"
        ))
    }

    func testNonSuccessfulResponseNeverCompletesBootstrap() {
        XCTAssertFalse(WebBootstrapPolicy.shouldComplete(
            statusCode: 403,
            headers: [:],
            title: "erişim reddedildi",
            html: "<html><body>forbidden</body></html>"
        ))
    }
}
