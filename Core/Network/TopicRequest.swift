import Foundation

struct TopicQueryItem: Codable, Hashable, Sendable {
    let name: String
    let value: String?
}

struct TopicRequest: Codable, Hashable, Sendable {
    private(set) var path: String
    private(set) var queryItems: [TopicQueryItem]

    init(link: String) {
        let normalized = link.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = URLComponents(string: normalized)

        if let components {
            path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            queryItems = (components.queryItems ?? []).map {
                TopicQueryItem(name: $0.name, value: $0.value)
            }
        } else {
            let parts = normalized.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
            path = String(parts.first ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            queryItems = []
        }
    }

    var pathAndQuery: String {
        guard !queryItems.isEmpty else { return path }

        var components = URLComponents()
        components.queryItems = queryItems.map { URLQueryItem(name: $0.name, value: $0.value) }
        guard let query = components.percentEncodedQuery, !query.isEmpty else { return path }
        return "\(path)?\(query)"
    }

    func settingPage(_ page: Int?) -> TopicRequest {
        var copy = self
        copy.queryItems.removeAll { $0.name.caseInsensitiveCompare("p") == .orderedSame }
        if let page {
            copy.queryItems.append(TopicQueryItem(name: "p", value: String(max(1, page))))
        }
        return copy
    }

    func applying(filter: EntryFilter) -> TopicRequest {
        var copy = self
        copy.queryItems = filter.queryItems
        return copy
    }

    func replacingPath(_ newPath: String) -> TopicRequest {
        var copy = self
        copy.path = TopicRequest(link: newPath).path
        return copy
    }
}
