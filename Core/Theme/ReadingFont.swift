import SwiftUI
import UIKit

/// Typeface for reading surfaces: entry bodies, topic titles and entry lists. The size still comes
/// from `UserPreferences.selectedFontSize`; this only chooses the face.
enum ReadingFont: String, CaseIterable, Identifiable, Sendable {
    case system
    case newYork
    case rounded
    case monospaced
    case atkinson
    case sourceSerif
    case plexSans
    case jetBrainsMono

    /// PostScript names of the bundled faces. No bold-italic is shipped; bold wins when both are asked.
    struct Faces: Hashable, Sendable {
        let regular: String
        let italic: String
        let bold: String
    }

    typealias FaceLoader = (_ postScriptName: String, _ size: CGFloat) -> UIFont?

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system: return "sistem"
        case .newYork: return "new york"
        case .rounded: return "yuvarlak"
        case .monospaced: return "mono"
        case .atkinson: return "atkinson hyperlegible"
        case .sourceSerif: return "source serif"
        case .plexSans: return "ibm plex sans"
        case .jetBrainsMono: return "jetbrains mono"
        }
    }

    var summary: String {
        switch self {
        case .system: return "san francisco, uygulamanın varsayılanı"
        case .newYork: return "apple'ın kitap okumaya uygun serifi"
        case .rounded: return "yumuşak köşeli sistem yazısı"
        case .monospaced: return "eşit genişlikli sistem yazısı"
        case .atkinson: return "az görenler için ayırt edici harfler"
        case .sourceSerif: return "uzun metinler için sakin bir serif"
        case .plexSans: return "net ve sıkı bir grotesk"
        case .jetBrainsMono: return "okunaklı, bitişiksiz kod yazısı"
        }
    }

    var systemDesign: UIFontDescriptor.SystemDesign? {
        switch self {
        case .system: return .default
        case .newYork: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        case .atkinson, .sourceSerif, .plexSans, .jetBrainsMono: return nil
        }
    }

    var faces: Faces? {
        switch self {
        case .system, .newYork, .rounded, .monospaced:
            return nil
        case .atkinson:
            return Faces(
                regular: "AtkinsonHyperlegibleNext-Regular",
                italic: "AtkinsonHyperlegibleNext-Italic",
                bold: "AtkinsonHyperlegibleNext-Bold"
            )
        case .sourceSerif:
            return Faces(regular: "SourceSerif4-Regular", italic: "SourceSerif4-It", bold: "SourceSerif4-Bold")
        case .plexSans:
            return Faces(regular: "IBMPlexSans", italic: "IBMPlexSans-Italic", bold: "IBMPlexSans-Bold")
        case .jetBrainsMono:
            return Faces(
                regular: "JetBrainsMonoNL-Regular",
                italic: "JetBrainsMonoNL-Italic",
                bold: "JetBrainsMonoNL-Bold"
            )
        }
    }

    static func resolve(storedValue: String?) -> ReadingFont {
        storedValue.flatMap(ReadingFont.init(rawValue:)) ?? .system
    }

    func faceName(bold: Bool, italic: Bool) -> String? {
        guard let faces else { return nil }
        if bold {
            return faces.bold
        }
        return italic ? faces.italic : faces.regular
    }

    /// Bundled faces fall back to the system font (same size and traits) if they fail to load.
    func uiFont(
        size: CGFloat,
        bold: Bool = false,
        italic: Bool = false,
        loader: FaceLoader = { UIFont(name: $0, size: $1) }
    ) -> UIFont {
        if let name = faceName(bold: bold, italic: italic), let font = loader(name, size) {
            return font
        }
        return Self.systemFont(size: size, design: systemDesign ?? .default, bold: bold, italic: italic)
    }

    func font(size: CGFloat, bold: Bool = false) -> Font {
        if let design = swiftUIDesign {
            return .system(size: size, weight: bold ? .bold : .regular, design: design)
        }
        return Font(uiFont(size: size, bold: bold) as CTFont)
    }

    /// Dynamic Type aware variant for places that used a text style (for example `.subheadline`).
    func font(_ style: Font.TextStyle, basePointSize: CGFloat, bold: Bool = false) -> Font {
        if let design = swiftUIDesign {
            let font = Font.system(style, design: design)
            return bold ? font.bold() : font
        }
        guard let name = faceName(bold: bold, italic: false), UIFont(name: name, size: basePointSize) != nil else {
            let font = Font.system(style)
            return bold ? font.bold() : font
        }
        return .custom(name, size: basePointSize, relativeTo: style)
    }

    private var swiftUIDesign: Font.Design? {
        switch self {
        case .system: return .default
        case .newYork: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        case .atkinson, .sourceSerif, .plexSans, .jetBrainsMono: return nil
        }
    }

    private static func systemFont(
        size: CGFloat,
        design: UIFontDescriptor.SystemDesign,
        bold: Bool,
        italic: Bool
    ) -> UIFont {
        let weighted = UIFont.systemFont(ofSize: size, weight: bold ? .bold : .regular).fontDescriptor
        var descriptor = weighted.withDesign(design) ?? weighted
        if italic, let slanted = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) {
            descriptor = slanted
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}
