import Foundation

enum InternalLinkPolicy {
    enum Destination: Equatable, Sendable {
        case topicLookup(query: String)
        case topic(link: String)
        case profile(username: String)
        case entry(id: String)
    }

    private static let internalHosts: Set<String> = [
        "eksisozluk.com",
        "www.eksisozluk.com",
    ]

    static func topicLookupLink(for query: String) -> String? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let encodedQuery = components.percentEncodedQuery, !encodedQuery.isEmpty else {
            return nil
        }
        return "?\(encodedQuery)"
    }

    static func destination(for rawLink: String) -> Destination? {
        let rawLink = rawLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawLink.isEmpty, let components = URLComponents(string: rawLink) else {
            return nil
        }
        guard isTrustedSource(components) else { return nil }

        if let query = lookupQuery(from: components) {
            return .topicLookup(query: query)
        }

        guard let decodedPath = components.percentEncodedPath.removingPercentEncoding else {
            return nil
        }
        let path = decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty, !path.split(separator: "/").contains("..") else {
            return nil
        }

        let pathParts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        if pathParts.first == "biri" {
            guard pathParts.count == 2 else { return nil }
            let username = pathParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return username.isEmpty ? nil : .profile(username: username)
        }

        if pathParts.first == "entry" {
            guard pathParts.count == 2, Int(pathParts[1]) != nil else { return nil }
            return .entry(id: pathParts[1])
        }

        let querySuffix = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        return .topic(link: path + querySuffix)
    }

    private static func isTrustedSource(_ components: URLComponents) -> Bool {
        guard let scheme = components.scheme?.lowercased() else {
            guard let host = components.host?.lowercased() else { return true }
            return internalHosts.contains(host)
        }

        switch scheme {
        case "applewebdata":
            return true
        case "http", "https":
            guard let host = components.host?.lowercased() else { return false }
            return internalHosts.contains(host)
        default:
            return false
        }
    }

    private static func lookupQuery(from components: URLComponents) -> String? {
        guard let encodedQuery = components.percentEncodedQuery else { return nil }

        for item in encodedQuery.split(separator: "&", omittingEmptySubsequences: false) {
            let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.first?.lowercased() == "q", pair.count == 2 else { continue }
            let encodedValue = String(pair[1]).replacingOccurrences(of: "+", with: "%20")
            let value = (encodedValue.removingPercentEncoding ?? encodedValue)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        return nil
    }
}
