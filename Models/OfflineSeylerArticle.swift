import Foundation

struct OfflineSeylerArticle: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var article: SeylerArticle
    var savedAt: Date

    init(article: SeylerArticle, savedAt: Date = Date()) {
        id = OfflineIdentifier.value(for: article.sourceURL.absoluteString)
        self.article = article
        self.savedAt = savedAt
    }
}
