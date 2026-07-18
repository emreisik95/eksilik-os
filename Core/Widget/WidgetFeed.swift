import Foundation

enum WidgetFeedSource: String, Codable, CaseIterable {
    case popular = "gundem"
    case today = "bugun"
    case following = "takip"
    case debe
    case user
}

struct WidgetFeedItem: Codable, Hashable, Identifiable {
    let title: String
    let subtitle: String?
    let metadata: String?
    let link: String

    var id: String {
        Self.normalizedLink(link)
    }

    init(title: String, subtitle: String?, metadata: String?, link: String) {
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.link = link
    }

    private static func normalizedLink(_ link: String) -> String {
        guard var components = URLComponents(string: link) else { return link }
        components.fragment = nil
        return components.string ?? link
    }
}

struct WidgetFeedSnapshot: Codable, Equatable {
    let source: WidgetFeedSource
    let items: [WidgetFeedItem]
    let updatedAt: Date
}
