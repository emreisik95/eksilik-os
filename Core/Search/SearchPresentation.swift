import Foundation

enum SearchPresentation {
    enum State: Equatable {
        case discovery
        case needsMoreCharacters
        case loading
        case results
        case empty
        case failure
    }

    enum Destination: Equatable {
        case entry(id: String)
        case profile(username: String)
        case topic(link: String, title: String)
    }

    static func state(
        query: String,
        isSearching: Bool,
        titleCount: Int,
        nickCount: Int,
        error: String?
    ) -> State {
        let query = normalizedQuery(query)
        if query.isEmpty { return .discovery }
        if query.count < 2 { return .needsMoreCharacters }
        if isSearching { return .loading }
        if error != nil { return .failure }
        if titleCount > 0 || nickCount > 0 { return .results }
        return .empty
    }

    static func resolve(query: String) -> Destination? {
        let text = normalizedQuery(query)
        guard !text.isEmpty else { return nil }

        if text.hasPrefix("#") {
            let id = String(text.dropFirst())
            guard !id.isEmpty, Int(id) != nil else { return nil }
            return .entry(id: id)
        }

        if text.hasPrefix("@") {
            let username = String(text.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !username.isEmpty else { return nil }
            return .profile(username: username)
        }

        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? text
        return .topic(link: encoded, title: text)
    }

    private static func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
