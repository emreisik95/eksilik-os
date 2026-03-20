import Foundation

struct SearchResultParser {
    static func parse(data: Data) -> SearchResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return SearchResult(titles: [], nicks: [])
        }

        let titles = json["Titles"] as? [String] ?? []
        let nicks = json["Nicks"] as? [String] ?? []

        return SearchResult(titles: titles, nicks: nicks)
    }
}
