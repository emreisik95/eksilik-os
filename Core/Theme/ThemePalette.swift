import Foundation
import SwiftUI
import UIKit

struct ThemeColorToken: Hashable, Sendable {
    let hex: UInt32

    init(hex: UInt32) {
        self.hex = hex & 0xFFFFFF
    }

    /// Parses `#RRGGBB` or `RRGGBB`; anything else (short, long, alpha, signs) is rejected.
    init?(hexString: String) {
        var digits = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if digits.hasPrefix("#") {
            digits.removeFirst()
        }
        guard digits.count == 6,
              digits.unicodeScalars.allSatisfy({ Self.hexDigits.contains($0) }),
              let value = UInt32(digits, radix: 16) else {
            return nil
        }
        self.init(hex: value)
    }

    /// Snaps any SwiftUI color (for example a wide-gamut ColorPicker pick) to the nearest sRGB token.
    init(color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            self.init(hex: 0)
            return
        }
        self.init(hex: Self.channel(red) << 16 | Self.channel(green) << 8 | Self.channel(blue))
    }

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

    private static let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")

    private static func channel(_ value: CGFloat) -> UInt32 {
        UInt32((min(max(value, 0), 1) * 255).rounded())
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

extension ThemeColorToken: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let token = ThemeColorToken(hexString: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a #RRGGBB color, found \(raw.prefix(16))"
            )
        }
        self = token
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }
}

struct ThemePalette: Codable, Hashable, Sendable {
    enum Appearance: String, Codable, Hashable, Sendable {
        case light
        case dark
    }

    var background: ThemeColorToken
    var cellPrimary: ThemeColorToken
    var cellSecondary: ThemeColorToken
    var accent: ThemeColorToken
    var entryText: ThemeColorToken
    var link: ThemeColorToken
    var label: ThemeColorToken
    var date: ThemeColorToken
    var separator: ThemeColorToken
    var navBar: ThemeColorToken
    var tabBarTint: ThemeColorToken
    var entryCount: ThemeColorToken
    var spoilerBackground: ThemeColorToken
    var appearance: Appearance

    subscript(key: ThemeTokenKey) -> ThemeColorToken {
        get { self[keyPath: key.keyPath] }
        set { self[keyPath: key.keyPath] = newValue }
    }
}

extension ThemePalette {
    var backgroundColor: Color { background.color }
    var cellPrimaryColor: Color { cellPrimary.color }
    var cellSecondaryColor: Color { cellSecondary.color }
    var accentColor: Color { accent.color }
    var entryTextColor: Color { entryText.color }
    var linkColor: Color { link.color }
    var labelColor: Color { label.color }
    var dateColor: Color { date.color }
    var separatorColor: Color { separator.color }
    var navBarColor: Color { navBar.color }
    var tabBarTintColor: Color { tabBarTint.color }
    var entryCountColor: Color { entryCount.color }

    var colorScheme: ColorScheme {
        appearance == .dark ? .dark : .light
    }

    var spoilerBackgroundHex: String {
        spoilerBackground.hexString
    }
}

/// Every editable color in a palette, in the order the theme editor lists them.
enum ThemeTokenKey: String, CaseIterable, Identifiable, Sendable {
    case background
    case cellPrimary
    case cellSecondary
    case accent
    case entryText
    case link
    case label
    case date
    case separator
    case navBar
    case tabBarTint
    case entryCount
    case spoilerBackground

    var id: String { rawValue }

    var title: String {
        switch self {
        case .background: return "arka plan"
        case .cellPrimary: return "hücre"
        case .cellSecondary: return "ikincil hücre"
        case .accent: return "vurgu"
        case .entryText: return "entry metni"
        case .link: return "link"
        case .label: return "başlık"
        case .date: return "tarih"
        case .separator: return "ayırıcı"
        case .navBar: return "üst bar"
        case .tabBarTint: return "sekme"
        case .entryCount: return "entry sayısı"
        case .spoilerBackground: return "spoiler"
        }
    }

    var hint: String {
        switch self {
        case .background: return "sayfa ve liste zemini"
        case .cellPrimary: return "başlık satırları ve kartlar"
        case .cellSecondary: return "sıralı satırların ikinci tonu"
        case .accent: return "butonlar, nickler ve seçimler"
        case .entryText: return "entry gövdesindeki yazı"
        case .link: return "bağlantılar ve (bkz)"
        case .label: return "başlıklar ve ana yazılar"
        case .date: return "tarih ve ikincil bilgiler"
        case .separator: return "satır ve bölüm çizgileri"
        case .navBar: return "üstteki gezinme çubuğu"
        case .tabBarTint: return "seçili sekme"
        case .entryCount: return "başlıklardaki entry sayısı"
        case .spoilerBackground: return "spoiler vurgusunun zemini"
        }
    }

    var keyPath: WritableKeyPath<ThemePalette, ThemeColorToken> {
        switch self {
        case .background: return \.background
        case .cellPrimary: return \.cellPrimary
        case .cellSecondary: return \.cellSecondary
        case .accent: return \.accent
        case .entryText: return \.entryText
        case .link: return \.link
        case .label: return \.label
        case .date: return \.date
        case .separator: return \.separator
        case .navBar: return \.navBar
        case .tabBarTint: return \.tabBarTint
        case .entryCount: return \.entryCount
        case .spoilerBackground: return \.spoilerBackground
        }
    }
}
