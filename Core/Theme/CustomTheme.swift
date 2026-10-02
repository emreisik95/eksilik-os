import Foundation

/// A user-made palette. It remembers the built-in it started from so the app can fall back to it
/// (and so older app versions, which only read `selectedTheme`, land on something close).
struct CustomTheme: Codable, Hashable, Identifiable, Sendable {
    static let maximumNameLength = 32
    static let fallbackName = "adsız tema"

    let id: UUID
    var name: String
    var baseTheme: AppTheme
    var palette: ThemePalette

    init(id: UUID = UUID(), name: String, baseTheme: AppTheme, palette: ThemePalette) {
        self.id = id
        self.name = name
        self.baseTheme = baseTheme
        self.palette = palette
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = Self.sanitizedName(try container.decode(String.self, forKey: .name))
        let rawBase = try container.decodeIfPresent(Int.self, forKey: .baseTheme)
        baseTheme = rawBase.flatMap(AppTheme.init(rawValue:)) ?? .dark
        palette = try container.decode(ThemePalette.self, forKey: .palette)
    }

    static func sanitizedName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallbackName }
        return String(trimmed.prefix(maximumNameLength))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case baseTheme
        case palette
    }
}

enum ThemeSelection: Hashable, Sendable {
    case builtIn(AppTheme)
    case custom(UUID)
}

/// Persists custom themes as one JSON array. Decoding is per element so a single corrupt entry
/// (for example written by a future version) never wipes the user's other themes.
struct CustomThemeStore {
    static let key = "customThemes"

    let defaults: UserDefaults

    func load() -> [CustomTheme] {
        guard let data = defaults.data(forKey: Self.key),
              let elements = try? JSONDecoder().decode([LossyElement].self, from: data) else {
            return []
        }
        var seen = Set<UUID>()
        return elements.compactMap(\.theme).filter { seen.insert($0.id).inserted }
    }

    func save(_ themes: [CustomTheme]) {
        do {
            defaults.set(try JSONEncoder().encode(themes), forKey: Self.key)
        } catch {
            assertionFailure("Custom themes failed to encode: \(error)")
        }
    }

    private struct LossyElement: Decodable {
        let theme: CustomTheme?

        init(from decoder: Decoder) throws {
            theme = try? CustomTheme(from: decoder)
        }
    }
}
