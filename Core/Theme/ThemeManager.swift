import SwiftUI

/// Owns the active palette. Built-in selection still lives in the legacy `selectedTheme` Int, so
/// existing installs resolve to exactly the theme they had; a custom selection is stored beside it.
final class ThemeManager: ObservableObject {
    static let selectedThemeKey = "selectedTheme"
    static let selectedCustomThemeKey = "selectedCustomTheme"

    @Published private(set) var current: ThemePalette
    @Published private(set) var selection: ThemeSelection
    @Published private(set) var customThemes: [CustomTheme]

    /// `nil` for preview managers, which keep everything in memory.
    private let defaults: UserDefaults?

    init(defaults: UserDefaults = .standard) {
        let themes = CustomThemeStore(defaults: defaults).load()
        let selection = Self.resolveSelection(defaults: defaults, customThemes: themes)
        self.defaults = defaults
        self.customThemes = themes
        self.selection = selection
        self.current = Self.palette(for: selection, in: themes) ?? AppTheme.dark.palette
    }

    /// A non-persisting manager for rendering real components with a draft palette.
    init(previewPalette: ThemePalette) {
        defaults = nil
        customThemes = []
        selection = .builtIn(.dark)
        current = previewPalette
    }

    /// The palette the app would use right now, for code that runs outside the view tree.
    static func activePalette(defaults: UserDefaults = .standard) -> ThemePalette {
        let themes = CustomThemeStore(defaults: defaults).load()
        let selection = resolveSelection(defaults: defaults, customThemes: themes)
        return palette(for: selection, in: themes) ?? AppTheme.dark.palette
    }

    var currentName: String {
        switch selection {
        case .builtIn(let theme):
            return theme.name
        case .custom(let id):
            return customThemes.first { $0.id == id }?.name ?? AppTheme.dark.name
        }
    }

    func isSelected(_ candidate: ThemeSelection) -> Bool {
        selection == candidate
    }

    func setTheme(_ theme: AppTheme) {
        select(.builtIn(theme))
    }

    func select(_ newSelection: ThemeSelection) {
        guard let palette = Self.palette(for: newSelection, in: customThemes) else { return }
        selection = newSelection
        current = palette
        persistSelection()
    }

    /// Swaps the palette of a preview manager without touching any selection.
    func applyPreview(_ palette: ThemePalette) {
        guard defaults == nil else { return }
        current = palette
    }

    func palette(for selection: ThemeSelection) -> ThemePalette? {
        Self.palette(for: selection, in: customThemes)
    }

    // MARK: - Custom themes

    func makeDraft(from base: AppTheme) -> CustomTheme {
        CustomTheme(name: nextDraftName(), baseTheme: base, palette: base.palette)
    }

    /// Inserts a new theme or replaces the one with the same id.
    func saveCustomTheme(_ theme: CustomTheme) {
        var theme = theme
        theme.name = CustomTheme.sanitizedName(theme.name)
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme
        } else {
            customThemes.append(theme)
        }
        persistCustomThemes()
        if selection == .custom(theme.id) {
            current = theme.palette
            persistSelection()
        }
    }

    @discardableResult
    func duplicateCustomTheme(id: UUID) -> CustomTheme? {
        guard let index = customThemes.firstIndex(where: { $0.id == id }) else { return nil }
        let original = customThemes[index]
        let copy = CustomTheme(
            name: CustomTheme.sanitizedName("\(original.name) kopyası"),
            baseTheme: original.baseTheme,
            palette: original.palette
        )
        customThemes.insert(copy, at: index + 1)
        persistCustomThemes()
        return copy
    }

    func renameCustomTheme(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = customThemes.firstIndex(where: { $0.id == id }) else { return }
        customThemes[index].name = CustomTheme.sanitizedName(trimmed)
        persistCustomThemes()
    }

    func deleteCustomTheme(id: UUID) {
        guard let index = customThemes.firstIndex(where: { $0.id == id }) else { return }
        let removed = customThemes.remove(at: index)
        persistCustomThemes()
        if selection == .custom(id) {
            select(.builtIn(removed.baseTheme))
        }
    }

    // MARK: - Persistence

    private func nextDraftName() -> String {
        let base = "yeni tema"
        let names = Set(customThemes.map(\.name))
        guard names.contains(base) else { return base }
        var index = 2
        while names.contains("\(base) \(index)") {
            index += 1
        }
        return "\(base) \(index)"
    }

    private func persistCustomThemes() {
        guard let defaults else { return }
        CustomThemeStore(defaults: defaults).save(customThemes)
    }

    private func persistSelection() {
        guard let defaults else { return }
        switch selection {
        case .builtIn(let theme):
            defaults.set(theme.rawValue, forKey: Self.selectedThemeKey)
            defaults.removeObject(forKey: Self.selectedCustomThemeKey)
        case .custom(let id):
            // Keep the legacy key on the closest built-in so a downgrade still looks familiar.
            if let base = customThemes.first(where: { $0.id == id })?.baseTheme {
                defaults.set(base.rawValue, forKey: Self.selectedThemeKey)
            }
            defaults.set(id.uuidString, forKey: Self.selectedCustomThemeKey)
        }
    }

    private static func resolveSelection(defaults: UserDefaults, customThemes: [CustomTheme]) -> ThemeSelection {
        if let raw = defaults.string(forKey: selectedCustomThemeKey),
           let id = UUID(uuidString: raw),
           customThemes.contains(where: { $0.id == id }) {
            return .custom(id)
        }
        return .builtIn(AppTheme(rawValue: defaults.integer(forKey: selectedThemeKey)) ?? .dark)
    }

    private static func palette(for selection: ThemeSelection, in themes: [CustomTheme]) -> ThemePalette? {
        switch selection {
        case .builtIn(let theme):
            return theme.palette
        case .custom(let id):
            return themes.first { $0.id == id }?.palette
        }
    }
}
