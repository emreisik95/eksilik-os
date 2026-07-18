import XCTest
@testable import EksilikApp

final class SessionPrivacyCleanupTests: XCTestCase {
    func testCleanupRemovesEveryAccountScopedLocalArtifact() {
        var calls: [String] = []

        SessionPrivacyCleanup.perform(
            clearCookies: { calls.append("cookies") },
            clearDrafts: { calls.append("drafts") },
            clearFollowingSnapshot: { calls.append("following") },
            reloadWidgets: { calls.append("widgets") }
        )

        XCTAssertEqual(calls, ["cookies", "drafts", "following", "widgets"])
    }
}
