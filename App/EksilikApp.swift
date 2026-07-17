import SwiftUI
import UIKit

@main
struct EksilikApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let backButton = UIBarButtonItem.appearance(
            whenContainedInInstancesOf: [UINavigationBar.self]
        )
        let iconOnlyOffset = UIOffset(horizontal: -1_000, vertical: 0)
        backButton.setBackButtonTitlePositionAdjustment(iconOnlyOffset, for: .default)
        backButton.setBackButtonTitlePositionAdjustment(iconOnlyOffset, for: .compact)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
