import Foundation

enum SettingsSectionKind: String, CaseIterable, Identifiable, Sendable {
    case appearance
    case home
    case content
    case account
    case about
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "görünüm ve okuma"
        case .home: return "ana sayfa"
        case .content: return "içerik"
        case .account: return "hesap"
        case .about: return "destek ve yasal"
        case .advanced: return "gelişmiş"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: return "paintbrush"
        case .home: return "house"
        case .content: return "books.vertical"
        case .account: return "person.crop.circle"
        case .about: return "info.circle"
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
    case privacyPolicy
    case support
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
                kind: .about,
                items: [.privacyPolicy, .support]
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

    static func layoutMetrics(fontSize: Int) -> SettingsLayoutMetrics {
        SettingsLayoutMetrics(fontSize: fontSize)
    }
}

struct SettingsLayoutMetrics: Equatable, Sendable {
    let scale: Double
    let rowMinimumHeight: Double
    let horizontalPadding: Double
    let sectionSpacing: Double
    let controlMinimumSize: Double
    let iconContainerSize: Double
    let cardPadding: Double
    let cornerRadius: Double

    init(fontSize: Int) {
        let proposedScale = 1 + (Double(fontSize) - 15) * 0.045
        scale = min(1.45, max(0.9, proposedScale))
        rowMinimumHeight = 62 * max(1, scale)
        horizontalPadding = 14 * scale
        sectionSpacing = 22 * scale
        controlMinimumSize = 44 * min(1.25, max(1, scale))
        iconContainerSize = 36 * min(1.3, max(1, scale))
        cardPadding = 18 * scale
        cornerRadius = 20 * min(1.25, max(1, scale))
    }
}
