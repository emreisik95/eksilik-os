import SwiftUI

final class UserPreferences: ObservableObject {
    private static let selectedFontKey = "selectedFont"
    private static let selectedFontSizeKey = "selectedFontSize"
    private static let openLinksInSafariKey = "openLinksInSafari"
    private static let hideEntriesEnabledKey = "hideEntriesEnabled"
    private static let baseURLKey = "baseURL"
    private static let useIconFiltersKey = "useIconFilters"
    private static let entryLayoutStyleKey = "entryLayoutStyle"
    private static let homeNavigationStyleKey = "homeNavigationStyle"
    private static let legacyHomeTabBarPositionKey = "homeTabBarPosition"
    private static let visibleHomeTabsKey = "visibleHomeTabs"
    private static let homeTabOrderKey = "homeTabOrder"

    private let defaults: UserDefaults

    @Published var selectedFont: String {
        didSet { defaults.set(selectedFont, forKey: Self.selectedFontKey) }
    }

    @Published var selectedFontSize: Int {
        didSet { defaults.set(selectedFontSize, forKey: Self.selectedFontSizeKey) }
    }

    @Published var openLinksInSafari: Bool {
        didSet { defaults.set(openLinksInSafari, forKey: Self.openLinksInSafariKey) }
    }

    @Published var hideEntriesEnabled: Bool {
        didSet { defaults.set(hideEntriesEnabled, forKey: Self.hideEntriesEnabledKey) }
    }

    @Published var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Self.baseURLKey) }
    }

    @Published var useIconFilters: Bool {
        didSet { defaults.set(useIconFilters, forKey: Self.useIconFiltersKey) }
    }

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
        selectedFont = defaults.string(forKey: Self.selectedFontKey) ?? "Helvetica"
        if defaults.object(forKey: Self.selectedFontSizeKey) == nil {
            selectedFontSize = 15
        } else {
            selectedFontSize = min(
                SettingsPresentationPolicy.fontSizeRange.upperBound,
                max(
                    SettingsPresentationPolicy.fontSizeRange.lowerBound,
                    defaults.integer(forKey: Self.selectedFontSizeKey)
                )
            )
        }
        openLinksInSafari = defaults.object(forKey: Self.openLinksInSafariKey) as? Bool ?? true
        hideEntriesEnabled = defaults.object(forKey: Self.hideEntriesEnabledKey) as? Bool ?? false
        baseURL = defaults.string(forKey: Self.baseURLKey) ?? "https://eksisozluk.com"
        useIconFilters = defaults.object(forKey: Self.useIconFiltersKey) as? Bool ?? false
        entryLayoutStyle = EntryLayoutStyle.resolve(
            storedValue: defaults.string(forKey: Self.entryLayoutStyleKey)
        )
        homeNavigationStyle = HomeNavigationStyle.resolve(
            storedValue: defaults.string(forKey: Self.homeNavigationStyleKey),
            legacyPosition: defaults.string(forKey: Self.legacyHomeTabBarPositionKey)
        )
        visibleHomeTabs = HomeTabCatalog.migratedVisibility(
            Self.decode(defaults.data(forKey: Self.visibleHomeTabsKey))
        )
        homeTabOrder = HomeTabCatalog.migratedOrder(
            Self.decode(defaults.data(forKey: Self.homeTabOrderKey))
        )

        if defaults.string(forKey: Self.homeNavigationStyleKey) == nil {
            defaults.set(homeNavigationStyle.rawValue, forKey: Self.homeNavigationStyleKey)
        }
        defaults.set(Self.encode(visibleHomeTabs), forKey: Self.visibleHomeTabsKey)
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
