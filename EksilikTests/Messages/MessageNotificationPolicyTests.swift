import XCTest
@testable import EksilikApp

final class MessageNotificationPolicyTests: XCTestCase {
    func testUnreadMessagesBadgeOnlyAppearsOnTheProfileTab() {
        XCTAssertEqual(
            MessageNotificationPolicy.badgeValue(for: .profile, hasUnreadMessages: true),
            1
        )
        XCTAssertNil(
            MessageNotificationPolicy.badgeValue(for: .home, hasUnreadMessages: true)
        )
        XCTAssertNil(
            MessageNotificationPolicy.badgeValue(for: .profile, hasUnreadMessages: false)
        )
    }
}
