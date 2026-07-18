import Foundation

struct WidgetSnapshotStore {
    static let appGroupID = "group.emre.isik.Eksilik"
    static let shared = WidgetSnapshotStore(
        defaults: UserDefaults(suiteName: appGroupID) ?? .standard
    )

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func save(_ snapshot: WidgetFeedSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: key(for: snapshot.source))
    }

    func load(source: WidgetFeedSource) -> WidgetFeedSnapshot? {
        guard let data = defaults.data(forKey: key(for: source)) else { return nil }
        return try? decoder.decode(WidgetFeedSnapshot.self, from: data)
    }

    func clear(source: WidgetFeedSource) {
        defaults.removeObject(forKey: key(for: source))
    }

    private func key(for source: WidgetFeedSource) -> String {
        "widget.feed.\(source.rawValue)"
    }
}
