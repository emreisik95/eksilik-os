import Foundation
import UIKit

struct Entry: Identifiable {
    let id: String
    let contentHTML: String
    let author: Author
    let date: String
    var favoriteCount: Int
    var isFavorited: Bool
    var voteState: VoteState
    let authorId: String
    var imageURLs: [String]
    var parsedContent: NSAttributedString?

    enum VoteState {
        case none, upvoted, downvoted
    }

    var shareURL: String {
        "https://eksisozluk.com/entry/\(id)"
    }
}
