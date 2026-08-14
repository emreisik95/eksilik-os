import Foundation
import SwiftUI

struct ThemeColorToken: Hashable, Sendable {
    let hex: UInt32

    var color: Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    var hexString: String {
        String(format: "#%06X", hex)
    }

    func contrastRatio(with other: ThemeColorToken) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        let red = Self.linearChannel(Double((hex >> 16) & 0xFF) / 255)
        let green = Self.linearChannel(Double((hex >> 8) & 0xFF) / 255)
        let blue = Self.linearChannel(Double(hex & 0xFF) / 255)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private static func linearChannel(_ value: Double) -> Double {
        value <= 0.03928
            ? value / 12.92
            : pow((value + 0.055) / 1.055, 2.4)
    }
}

struct ThemePalette: Hashable, Sendable {
    enum Appearance: Hashable, Sendable {
        case light
        case dark
    }

    let background: ThemeColorToken
    let cellPrimary: ThemeColorToken
    let cellSecondary: ThemeColorToken
    let accent: ThemeColorToken
    let entryText: ThemeColorToken
    let link: ThemeColorToken
    let label: ThemeColorToken
    let date: ThemeColorToken
    let separator: ThemeColorToken
    let navBar: ThemeColorToken
    let tabBarTint: ThemeColorToken
    let entryCount: ThemeColorToken
    let spoilerBackground: ThemeColorToken
    let appearance: Appearance
}

enum AppTheme: Int, CaseIterable, Identifiable {
    case dark = 0
    case light = 1
    case classic = 2
    case twitter = 3
    case oled = 4
    case notebook = 5
    case bosphorus = 6
    case burgundy = 7
    case terminal = 8
    case lilac = 9
    case solarDark = 10
    case solarLight = 11
    case ice = 12
    case coffee = 13
    case highContrast = 14

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .dark: return "gece"
        case .light: return "gündüz"
        case .classic: return "klasik"
        case .twitter: return "x"
        case .oled: return "oled"
        case .notebook: return "defter"
        case .bosphorus: return "boğaz"
        case .burgundy: return "bordo"
        case .terminal: return "terminal"
        case .lilac: return "leylak"
        case .solarDark: return "solar gece"
        case .solarLight: return "solar gündüz"
        case .ice: return "buz"
        case .coffee: return "kahve"
        case .highContrast: return "yüksek kontrast"
        }
    }

    var summary: String {
        switch self {
        case .dark: return "ekşi yeşili, dengeli koyu yüzey"
        case .light: return "temiz beyaz, güçlü okunabilirlik"
        case .classic: return "eski okul gri ve sözlük mavisi"
        case .twitter: return "serin lacivert sosyal akış"
        case .oled: return "tam siyah, sıcak turuncu"
        case .notebook: return "kağıt, mürekkep ve zeytin"
        case .bosphorus: return "gece mavisi ve turkuaz"
        case .burgundy: return "şarap tonları ve gül pembesi"
        case .terminal: return "fosfor yeşili komut satırı"
        case .lilac: return "yumuşak mor gece"
        case .solarDark: return "solarized koyu palet"
        case .solarLight: return "solarized açık palet"
        case .ice: return "nordik mavi gri"
        case .coffee: return "espresso, krema ve bakır"
        case .highContrast: return "siyah, beyaz ve sinyal sarısı"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .dark:
            return Self.palette(
                background: 0x252525, primary: 0x1C1C1C, secondary: 0x161616,
                accent: 0x66B43F, entryText: 0xFFFFFF, link: 0xB4EE74,
                label: 0xFFFFFF, date: 0x808080, separator: 0x000000,
                navBar: 0x161616, tab: 0x88CA40, count: 0xB4EE74,
                spoiler: 0x616161, appearance: .dark
            )
        case .light:
            return Self.palette(
                background: 0xFFFFFF, primary: 0xF5F5F5, secondary: 0xF5F5F5,
                accent: 0x4E7D1C, entryText: 0x000000, link: 0x4E7D1C,
                label: 0x000000, date: 0x737373, separator: 0x555555,
                navBar: 0xFFFFFF, tab: 0x88CA40, count: 0x4E7D1C,
                spoiler: 0xFFFF9E, appearance: .light
            )
        case .classic:
            return Self.palette(
                background: 0xDDDDDD, primary: 0xDDDDDD, secondary: 0xDDDDDD,
                accent: 0x0027B8, entryText: 0x000000, link: 0x0027B8,
                label: 0x000000, date: 0x666666, separator: 0x808080,
                navBar: 0xDDDDDD, tab: 0xFFFFFF, count: 0x0027B8,
                spoiler: 0xFFFF9E, appearance: .light
            )
        case .twitter:
            return Self.palette(
                background: 0x17202A, primary: 0x17202A, secondary: 0x17202A,
                accent: 0x4C9EEB, entryText: 0xFFFFFF, link: 0x4C9EEB,
                label: 0xFFFFFF, date: 0x8899A6, separator: 0x000000,
                navBar: 0x17202A, tab: 0x4C9EEB, count: 0x4C9EEB,
                spoiler: 0x616161, appearance: .dark
            )
        case .oled:
            return Self.palette(
                background: 0x000000, primary: 0x0A0A0A, secondary: 0x050505,
                accent: 0xE89838, entryText: 0xB4B4B4, link: 0xF5B250,
                label: 0xC8C8C8, date: 0x808080, separator: 0x191919,
                navBar: 0x000000, tab: 0xE89838, count: 0xE89838,
                spoiler: 0x616161, appearance: .dark
            )
        case .notebook:
            return Self.palette(
                background: 0xF4EBD8, primary: 0xFFF8E8, secondary: 0xE9DCC3,
                accent: 0x5E6B31, entryText: 0x2F2A24, link: 0x4F5D24,
                label: 0x29251F, date: 0x6F665B, separator: 0xB9AA8E,
                navBar: 0xF4EBD8, tab: 0x5E6B31, count: 0x5E6B31,
                spoiler: 0xE0D191, appearance: .light
            )
        case .bosphorus:
            return Self.palette(
                background: 0x071A2B, primary: 0x0D2438, secondary: 0x102D44,
                accent: 0x2DD4BF, entryText: 0xE6F7F5, link: 0x67E8F9,
                label: 0xF3FAFC, date: 0x9DB4C4, separator: 0x21445B,
                navBar: 0x071A2B, tab: 0x2DD4BF, count: 0x67E8F9,
                spoiler: 0x164E63, appearance: .dark
            )
        case .burgundy:
            return Self.palette(
                background: 0x261018, primary: 0x341521, secondary: 0x401A29,
                accent: 0xF4729B, entryText: 0xFCE7EF, link: 0xFDA4AF,
                label: 0xFFF1F5, date: 0xC5A3AF, separator: 0x623146,
                navBar: 0x261018, tab: 0xF4729B, count: 0xFDA4AF,
                spoiler: 0x6B2941, appearance: .dark
            )
        case .terminal:
            return Self.palette(
                background: 0x020A05, primary: 0x06130A, secondary: 0x0A1C0F,
                accent: 0x39FF14, entryText: 0xC7FFC0, link: 0x66FF55,
                label: 0xE6FFE2, date: 0x79A47A, separator: 0x173D1F,
                navBar: 0x020A05, tab: 0x39FF14, count: 0x66FF55,
                spoiler: 0x185922, appearance: .dark
            )
        case .lilac:
            return Self.palette(
                background: 0x181425, primary: 0x211B32, secondary: 0x2B2340,
                accent: 0xB794F4, entryText: 0xF1ECFA, link: 0xC4B5FD,
                label: 0xFAF7FF, date: 0xA89EBB, separator: 0x403755,
                navBar: 0x181425, tab: 0xB794F4, count: 0xC4B5FD,
                spoiler: 0x51416F, appearance: .dark
            )
        case .solarDark:
            return Self.palette(
                background: 0x002B36, primary: 0x073642, secondary: 0x0A3A45,
                accent: 0xB58900, entryText: 0xEEE8D5, link: 0x2AA198,
                label: 0xFDF6E3, date: 0x93A1A1, separator: 0x31545C,
                navBar: 0x002B36, tab: 0xB58900, count: 0x2AA198,
                spoiler: 0x586E75, appearance: .dark
            )
        case .solarLight:
            return Self.palette(
                background: 0xFDF6E3, primary: 0xEEE8D5, secondary: 0xE3DCC8,
                accent: 0xA63D00, entryText: 0x073642, link: 0x006A71,
                label: 0x002B36, date: 0x657B83, separator: 0xC9BFA6,
                navBar: 0xFDF6E3, tab: 0xA63D00, count: 0x006A71,
                spoiler: 0xE1D78E, appearance: .light
            )
        case .ice:
            return Self.palette(
                background: 0x242933, primary: 0x2E3440, secondary: 0x3B4252,
                accent: 0x88C0D0, entryText: 0xECEFF4, link: 0x8FBCBB,
                label: 0xF4F7FA, date: 0xAEB8C6, separator: 0x4C566A,
                navBar: 0x242933, tab: 0x88C0D0, count: 0x8FBCBB,
                spoiler: 0x46566F, appearance: .dark
            )
        case .coffee:
            return Self.palette(
                background: 0x1B1410, primary: 0x261C16, secondary: 0x32231A,
                accent: 0xD49A5B, entryText: 0xF4E7D5, link: 0xE7B77E,
                label: 0xFFF4E5, date: 0xB9A38F, separator: 0x513A2B,
                navBar: 0x1B1410, tab: 0xD49A5B, count: 0xE7B77E,
                spoiler: 0x64452E, appearance: .dark
            )
        case .highContrast:
            return Self.palette(
                background: 0x000000, primary: 0x0A0A0A, secondary: 0x181818,
                accent: 0xFFE600, entryText: 0xFFFFFF, link: 0xFFE600,
                label: 0xFFFFFF, date: 0xD0D0D0, separator: 0xFFFFFF,
                navBar: 0x000000, tab: 0xFFE600, count: 0xFFE600,
                spoiler: 0x4D4600, appearance: .dark
            )
        }
    }

    var backgroundColor: Color { palette.background.color }
    var cellPrimaryColor: Color { palette.cellPrimary.color }
    var cellSecondaryColor: Color { palette.cellSecondary.color }
    var accentColor: Color { palette.accent.color }
    var entryTextColor: Color { palette.entryText.color }
    var linkColor: Color { palette.link.color }
    var labelColor: Color { palette.label.color }
    var dateColor: Color { palette.date.color }
    var separatorColor: Color { palette.separator.color }
    var navBarColor: Color { palette.navBar.color }
    var tabBarTintColor: Color { palette.tabBarTint.color }
    var entryCountColor: Color { palette.entryCount.color }

    var colorScheme: ColorScheme {
        palette.appearance == .dark ? .dark : .light
    }

    var spoilerBackgroundHex: String {
        palette.spoilerBackground.hexString
    }

    // Exhaustive declarative palette construction intentionally names every token.
    // swiftlint:disable:next function_parameter_count
    private static func palette(
        background: UInt32,
        primary: UInt32,
        secondary: UInt32,
        accent: UInt32,
        entryText: UInt32,
        link: UInt32,
        label: UInt32,
        date: UInt32,
        separator: UInt32,
        navBar: UInt32,
        tab: UInt32,
        count: UInt32,
        spoiler: UInt32,
        appearance: ThemePalette.Appearance
    ) -> ThemePalette {
        ThemePalette(
            background: ThemeColorToken(hex: background),
            cellPrimary: ThemeColorToken(hex: primary),
            cellSecondary: ThemeColorToken(hex: secondary),
            accent: ThemeColorToken(hex: accent),
            entryText: ThemeColorToken(hex: entryText),
            link: ThemeColorToken(hex: link),
            label: ThemeColorToken(hex: label),
            date: ThemeColorToken(hex: date),
            separator: ThemeColorToken(hex: separator),
            navBar: ThemeColorToken(hex: navBar),
            tabBarTint: ThemeColorToken(hex: tab),
            entryCount: ThemeColorToken(hex: count),
            spoilerBackground: ThemeColorToken(hex: spoiler),
            appearance: appearance
        )
    }
}
