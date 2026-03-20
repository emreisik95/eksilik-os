import SwiftUI

@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var pendingRoute: Route?

    /// Handles eksilik:// deep links from the widget
    /// Format: eksilik://topic?link=/slug--id
    func handle(_ url: URL) {
        guard url.scheme == "eksilik" else { return }

        switch url.host {
        case "topic":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let link = components.queryItems?.first(where: { $0.name == "link" })?.value {
                let decoded = link.removingPercentEncoding ?? link
                pendingRoute = .entryList(link: decoded, title: "")
            }
        case "entry":
            if let id = url.pathComponents.last, !id.isEmpty {
                pendingRoute = .entryById(id: id)
            }
        case "profile":
            if let username = url.pathComponents.last, !username.isEmpty {
                pendingRoute = .profile(username: username)
            }
        default:
            break
        }
    }

    func consumeRoute() -> Route? {
        defer { pendingRoute = nil }
        return pendingRoute
    }
}
