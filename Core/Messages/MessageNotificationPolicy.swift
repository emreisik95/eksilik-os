import Foundation

enum MessageNotificationPolicy {
    static func badgeValue(for tab: MainTab, hasUnreadMessages: Bool) -> Int? {
        guard tab == .profile, hasUnreadMessages else { return nil }
        return 1
    }
}
