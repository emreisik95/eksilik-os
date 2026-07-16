import SwiftUI

final class UserPreferences: ObservableObject {
    private static let entryLayoutStyleKey = "entryLayoutStyle"
    private static let homeNavigationStyleKey = "homeNavigationStyle"
    private static let legacyHomeTabBarPositionKey = "homeTabBarPosition"
    private static let visibleHomeTabsKey = "visibleHomeTabs"
    private static let homeTabOrderKey = "homeTabOrder"

    private let defaults: UserDefaults

    @AppStorage("selectedFont") var selectedFont: String = "Helvetica"
    @AppStorage("selectedFontSize") var selectedFontSize: Int = 15
    @AppStorage("openLinksInSafari") var openLinksInSafari: Bool = true
    @AppStorage("hideEntriesEnabled") var hideEntriesEnabled: Bool = false
    @AppStorage("baseURL") var baseURL: String = "https://eksisozluk.com"
    @AppStorage("useIconFilters") var useIconFilters: Bool = false

    @Published var entryLayoutStyle: EntryLayoutStyle {
        didSet {
            defaults.set(entryLayoutStyle.rawValue, forKey: Self.entryLayoutStyleKey)
        }
    }

    @Published var homeNavigationStyle: HomeNavigationStyle {
        didSet {
            defaults.set(homeNavigationStyle.rawValue, forKey: Self.homeNavigationStyleKey)
        }
    }

    @Published var visibleHomeTabs: [String] {
        didSet {
            defaults.set(Self.encode(visibleHomeTabs), forKey: Self.visibleHomeTabsKey)
        }
    }

    @Published var homeTabOrder: [String] {
        didSet {
            defaults.set(
                Self.encode(HomeTabCatalog.normalizedOrder(homeTabOrder)),
                forKey: Self.homeTabOrderKey
            )
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entryLayoutStyle = EntryLayoutStyle.resolve(
            storedValue: defaults.string(forKey: Self.entryLayoutStyleKey)
        )
        homeNavigationStyle = HomeNavigationStyle.resolve(
            storedValue: defaults.string(forKey: Self.homeNavigationStyleKey),
            legacyPosition: defaults.string(forKey: Self.legacyHomeTabBarPositionKey)
        )
        visibleHomeTabs = Self.decode(defaults.data(forKey: Self.visibleHomeTabsKey))
        homeTabOrder = HomeTabCatalog.normalizedOrder(
            Self.decode(defaults.data(forKey: Self.homeTabOrderKey))
        )

        if defaults.string(forKey: Self.homeNavigationStyleKey) == nil {
            defaults.set(homeNavigationStyle.rawValue, forKey: Self.homeNavigationStyleKey)
        }
        defaults.set(Self.encode(homeTabOrder), forKey: Self.homeTabOrderKey)
    }

    private static func encode(_ values: [String]) -> Data {
        (try? JSONEncoder().encode(values)) ?? Data()
    }

    private static func decode(_ data: Data?) -> [String] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}
