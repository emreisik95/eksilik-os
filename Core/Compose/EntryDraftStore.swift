import Foundation

struct EntryDraftStore {
    static let shared = EntryDraftStore(defaults: .standard)

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func save(_ content: String, for topicLink: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clear(for: topicLink)
            return
        }
        defaults.set(content, forKey: key(for: topicLink))
    }

    func load(for topicLink: String) -> String? {
        defaults.string(forKey: key(for: topicLink))
    }

    func clear(for topicLink: String) {
        defaults.removeObject(forKey: key(for: topicLink))
    }

    func clearAll() {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("entry.draft.") }
            .forEach(defaults.removeObject(forKey:))
    }

    private func key(for topicLink: String) -> String {
        let encodedLink = Data(topicLink.utf8).base64EncodedString()
        return "entry.draft.\(encodedLink)"
    }
}
