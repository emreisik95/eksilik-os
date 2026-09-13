import Foundation

enum WidgetFeedFamily: Sendable {
    case small
    case medium
    case large
}

enum WidgetPresentationPolicy {
    static func topicLimit(for family: WidgetFeedFamily) -> Int {
        switch family {
        case .small: return 1
        case .medium: return 4
        case .large: return 10
        }
    }

    static func titleLineLimit(for family: WidgetFeedFamily) -> Int {
        switch family {
        case .small: return 5
        case .medium, .large: return 2
        }
    }
}
