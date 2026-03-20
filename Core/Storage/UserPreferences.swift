import SwiftUI

final class UserPreferences: ObservableObject {
    @AppStorage("selectedFont") var selectedFont: String = "Helvetica"
    @AppStorage("selectedFontSize") var selectedFontSize: Int = 15
    @AppStorage("openLinksInSafari") var openLinksInSafari: Bool = true
    @AppStorage("hideEntriesEnabled") var hideEntriesEnabled: Bool = false
    @AppStorage("visibleHomeTabs") var visibleHomeTabsData: Data = Data()
    @AppStorage("homeTabBarPosition") var homeTabBarPosition: String = "bottom"  // "top" or "bottom"
    @AppStorage("baseURL") var baseURL: String = "https://eksisozluk.com"

    var visibleHomeTabs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: visibleHomeTabsData)) ?? []
        }
        set {
            visibleHomeTabsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
