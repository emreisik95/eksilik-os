import XCTest
@testable import EksilikApp

final class ExternalLinkPolicyTests: XCTestCase {
    func testExternalMarkerForcesTextPresentationInsteadOfEmoji() {
        let html = #"<a href="https://x.com/example/status/1">kaynak</a>"#

        let marked = ExternalLinkPolicy.addingTextMarkers(to: html)

        XCTAssertTrue(marked.contains("kaynak \u{2197}\u{FE0E}"))
        XCTAssertFalse(marked.contains("\u{FE0F}"))
    }

    func testSocialAndMediaLinksPreferInstalledNativeApps() throws {
        let urls = try [
            "https://x.com/example/status/1",
            "https://www.instagram.com/p/example/",
            "https://youtu.be/example",
            "https://m.youtube.com/watch?v=example",
            "https://www.tiktok.com/@example/video/1",
            "https://www.linkedin.com/posts/example",
        ].map { try XCTUnwrap(URL(string: $0)) }

        XCTAssertTrue(urls.allSatisfy(ExternalLinkPolicy.prefersNativeApp))
    }

    func testUnrelatedAndLookalikeDomainsStayInApp() throws {
        let unrelated = try XCTUnwrap(URL(string: "https://example.com/x.com"))
        let lookalike = try XCTUnwrap(URL(string: "https://notx.com/example"))

        XCTAssertFalse(ExternalLinkPolicy.prefersNativeApp(unrelated))
        XCTAssertFalse(ExternalLinkPolicy.prefersNativeApp(lookalike))
    }
}
