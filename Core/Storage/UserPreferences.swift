import SwiftUI

final class UserPreferences: ObservableObject {
    @AppStorage("selectedFont") var selectedFont: String = "Helvetica"
    @AppStorage("selectedFontSize") var selectedFontSize: Int = 15
    @AppStorage("openLinksInSafari") var openLinksInSafari: Bool = true
    @AppStorage("hideEntriesEnabled") var hideEntriesEnabled: Bool = false
    @AppStorage("visibleHomeTabs") var visibleHomeTabsData: Data = Data()

    var visibleHomeTabs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: visibleHomeTabsData)) ?? []
        }
        set {
            visibleHomeTabsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
