import Foundation

enum SeylerArticleBlock: Codable, Hashable, Sendable {
    case paragraph(String)
    case heading(String)
    case image(url: URL, caption: String?)
    case quote(String)
    case list([String])
}

struct SeylerArticle: Codable, Hashable, Sendable {
    let sourceURL: URL
    let title: String
    let summary: String?
    let category: String?
    let date: String?
    let readCount: String?
    let shareCount: String?
    let heroImageURL: URL?
    let authors: [String]
    let blocks: [SeylerArticleBlock]

    var imageURLs: [URL] {
        var values = heroImageURL.map { [$0] } ?? []
        values.append(contentsOf: blocks.compactMap { block in
            guard case .image(let url, _) = block else { return nil }
            return url
        })
        var seen = Set<URL>()
        return values.filter { seen.insert($0).inserted }
    }
}
