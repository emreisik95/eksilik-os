import Foundation

enum SettingsSectionKind: String, CaseIterable, Identifiable, Sendable {
    case appearance
    case home
    case content
    case account
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "görünüm ve okuma"
        case .home: return "ana sayfa"
        case .content: return "içerik"
        case .account: return "hesap"
        case .advanced: return "gelişmiş"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: return "paintbrush"
        case .home: return "house"
        case .content: return "books.vertical"
        case .account: return "person.crop.circle"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

enum SettingsItem: String, Identifiable, Hashable, Sendable {
    case theme
    case entryLayout
    case fontSize
    case filterStyle
    case appIcon
    case homeNavigation
    case homeTabs
    case offlineLibrary
    case blockedTopics
    case login
    case accountPreferences
    case trackingAndBlocks
    case logout
    case server

    var id: String { rawValue }
}

struct SettingsSectionDescriptor: Identifiable, Equatable, Sendable {
    let kind: SettingsSectionKind
    let items: [SettingsItem]

    var id: String { kind.id }
}

enum SettingsPresentationPolicy {
    static let fontSizeRange = 10...24

    static func sections(isLoggedIn: Bool) -> [SettingsSectionDescriptor] {
        [
            SettingsSectionDescriptor(
                kind: .appearance,
                items: [.theme, .entryLayout, .fontSize, .filterStyle, .appIcon]
            ),
            SettingsSectionDescriptor(
                kind: .home,
                items: [.homeNavigation, .homeTabs]
            ),
            SettingsSectionDescriptor(
                kind: .content,
                items: [.offlineLibrary, .blockedTopics]
            ),
            SettingsSectionDescriptor(
                kind: .account,
                items: isLoggedIn
                    ? [.accountPreferences, .trackingAndBlocks, .logout]
                    : [.login]
            ),
            SettingsSectionDescriptor(
                kind: .advanced,
                items: [.server]
            ),
        ]
    }

    static func adjustedFontSize(_ current: Int, delta: Int) -> Int {
        min(fontSizeRange.upperBound, max(fontSizeRange.lowerBound, current + delta))
    }
}
