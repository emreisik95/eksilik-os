import Foundation

struct SeylerStory: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let url: URL
    let imageURL: URL?
    let category: String?
    let readCount: String?
    let isFeatured: Bool

    init(
        title: String,
        url: URL,
        imageURL: URL?,
        category: String?,
        readCount: String?,
        isFeatured: Bool
    ) {
        id = url.absoluteString
        self.title = title
        self.url = url
        self.imageURL = imageURL
        self.category = category
        self.readCount = readCount
        self.isFeatured = isFeatured
    }
}
