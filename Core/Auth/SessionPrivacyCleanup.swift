import Foundation
import WidgetKit

enum SessionPrivacyCleanup {
    static func perform() {
        perform(
            clearCookies: {
                CookiePersistence.clear()
                Task { @MainActor in
                    await CookiePersistence.clearWebViewCookies()
                }
            },
            clearDrafts: { EntryDraftStore.shared.clearAll() },
            clearFollowingSnapshot: {
                WidgetSnapshotStore.shared.clear(source: .following)
            },
            reloadWidgets: {
                WidgetCenter.shared.reloadTimelines(ofKind: "EksilikWidget")
            }
        )
    }

    static func perform(
        clearCookies: () -> Void,
        clearDrafts: () -> Void,
        clearFollowingSnapshot: () -> Void,
        reloadWidgets: () -> Void
    ) {
        clearCookies()
        clearDrafts()
        clearFollowingSnapshot()
        reloadWidgets()
    }
}
