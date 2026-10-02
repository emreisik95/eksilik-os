import Foundation

struct ThemeContrastCheck: Hashable, Sendable {
    let foreground: ThemeTokenKey
    let background: ThemeTokenKey
    let ratio: Double

    var isBelowMinimum: Bool {
        ratio < ThemeContrastPolicy.minimumRatio
    }

    var title: String {
        "\(foreground.title) / \(background.title)"
    }

    /// One decimal, truncated rather than rounded, so 4.48 never reads as a passing "4,5:1".
    var formattedRatio: String {
        let truncated = (ratio * 10).rounded(.down) / 10
        let text = String(format: "%.1f", truncated).replacingOccurrences(of: ".", with: ",")
        return "\(text):1"
    }
}

/// WCAG 2.x AA contrast for the text the app is mostly read through. Advisory only: the editor
/// warns below the minimum but still lets people save the theme they want.
enum ThemeContrastPolicy {
    static let minimumRatio = 4.5

    static let pairs: [(foreground: ThemeTokenKey, background: ThemeTokenKey)] = [
        (.entryText, .background),
        (.link, .background),
        (.label, .cellPrimary),
        (.date, .background),
    ]

    static func checks(for palette: ThemePalette) -> [ThemeContrastCheck] {
        pairs.map { pair in
            ThemeContrastCheck(
                foreground: pair.foreground,
                background: pair.background,
                ratio: palette[pair.foreground].contrastRatio(with: palette[pair.background])
            )
        }
    }

    static func warnings(for palette: ThemePalette) -> [ThemeContrastCheck] {
        checks(for: palette).filter(\.isBelowMinimum)
    }
}
