import SwiftUI

@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var pendingRoute: Route?
    @Published var selectedMainTab: MainTab = .home

    /// Handles eksilik:// deep links from the widget
    /// Format: eksilik://topic?link=/slug--id
    func handle(_ url: URL) {
        guard url.scheme == "eksilik" else { return }

        switch url.host {
        case "topic":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let link = components.queryItems?.first(where: { $0.name == "link" })?.value {
                let decoded = link.removingPercentEncoding ?? link
                open(.entryList(link: decoded, title: ""))
            }
        case "entry":
            if let id = url.pathComponents.last, !id.isEmpty {
                open(.entryById(id: id))
            }
        case "feed":
            let supportedSources = Set(["gundem", "bugun", "takip", "debe"])
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let source = components.queryItems?.first(where: { $0.name == "source" })?.value,
               supportedSources.contains(source) {
                open(.topicFeed(source: source))
            }
        case "profile":
            if let username = url.pathComponents.last, !username.isEmpty {
                open(.profile(username: username))
            }
        default:
            break
        }
    }

    func consumeRoute() -> Route? {
        defer { pendingRoute = nil }
        return pendingRoute
    }

    private func open(_ route: Route) {
        selectedMainTab = .home
        pendingRoute = route
    }
}
