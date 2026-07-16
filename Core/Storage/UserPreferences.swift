import SwiftUI

final class UserPreferences: ObservableObject {
    private static let entryLayoutStyleKey = "entryLayoutStyle"

    private let defaults: UserDefaults

    @AppStorage("selectedFont") var selectedFont: String = "Helvetica"
    @AppStorage("selectedFontSize") var selectedFontSize: Int = 15
    @AppStorage("openLinksInSafari") var openLinksInSafari: Bool = true
    @AppStorage("hideEntriesEnabled") var hideEntriesEnabled: Bool = false
    @AppStorage("visibleHomeTabs") var visibleHomeTabsData: Data = Data()
    @AppStorage("homeTabBarPosition") var homeTabBarPosition: String = "bottom"  // "top" or "bottom"
    @AppStorage("baseURL") var baseURL: String = "https://eksisozluk.com"
    @AppStorage("useIconFilters") var useIconFilters: Bool = false

    @Published var entryLayoutStyle: EntryLayoutStyle {
        didSet {
            defaults.set(entryLayoutStyle.rawValue, forKey: Self.entryLayoutStyleKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entryLayoutStyle = EntryLayoutStyle.resolve(
            storedValue: defaults.string(forKey: Self.entryLayoutStyleKey)
        )
    }

    var visibleHomeTabs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: visibleHomeTabsData)) ?? []
        }
        set {
            visibleHomeTabsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
