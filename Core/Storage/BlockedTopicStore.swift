import Foundation

struct FilterRule: Identifiable, Codable, Equatable {
    let id: UUID
    var pattern: String
    var type: FilterType
    var isEnabled: Bool

    enum FilterType: String, Codable, CaseIterable {
        case exact
        case contains
        case regex

        var label: String {
            switch self {
            case .exact: return "tam eslesme"
            case .contains: return "iceren"
            case .regex: return "regex"
            }
        }
    }

    func matches(_ title: String) -> Bool {
        guard isEnabled else { return false }
        let lower = title.lowercased()
        switch type {
        case .exact:
            return lower == pattern.lowercased()
        case .contains:
            return lower.contains(pattern.lowercased())
        case .regex:
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
            return regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil
        }
    }
}

final class BlockedTopicStore: ObservableObject {
    @Published var rules: [FilterRule] {
        didSet { persistRules() }
    }

    private static let rulesKey = "blockedTopicRules"
    private static let legacyKey = "blockedTopics"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.rulesKey),
           let decoded = try? JSONDecoder().decode([FilterRule].self, from: data) {
            rules = decoded
        } else {
            rules = []
            migrateLegacyBlockedTopics()
        }
    }

    // MARK: - Public API

    /// Check if a topic title matches any enabled filter rule.
    func isBlocked(_ topic: String) -> Bool {
        rules.contains { $0.matches(topic) }
    }

    func addRule(_ rule: FilterRule) {
        rules.append(rule)
    }

    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    func toggleRule(id: UUID) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].isEnabled.toggle()
    }

    /// Legacy convenience: block a topic by exact title (used by swipe/context menu actions).
    func block(_ topic: String) {
        guard !rules.contains(where: { $0.pattern == topic && $0.type == .exact }) else { return }
        addRule(FilterRule(id: UUID(), pattern: topic, type: .exact, isEnabled: true))
    }

    /// Legacy convenience: unblock an exact-match rule by pattern string.
    func unblock(_ topic: String) {
        rules.removeAll { $0.pattern == topic && $0.type == .exact }
    }

    /// Computed list of blocked topic strings for backward-compatible parser calls.
    var blockedTopics: [String] {
        rules.filter(\.isEnabled).map(\.pattern)
    }

    // MARK: - Persistence

    private func persistRules() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: Self.rulesKey)
    }

    /// Migrate old [String] blocked list to .exact rules on first launch.
    private func migrateLegacyBlockedTopics() {
        guard let legacy = UserDefaults.standard.stringArray(forKey: Self.legacyKey), !legacy.isEmpty else { return }
        let migrated = legacy.map { FilterRule(id: UUID(), pattern: $0, type: .exact, isEnabled: true) }
        rules = migrated
        UserDefaults.standard.removeObject(forKey: Self.legacyKey)
    }
}
