import Foundation

struct UserProfile {
    let nick: String
    let avatarURL: String?
    let bio: String?
    let isVerified: Bool
    let badges: [Badge]
    let entryCount: Int
    let followerCount: Int
    let followingCount: Int
    let joinDate: String?
    var entries: [ProfileEntry]

    struct Badge {
        let name: String
        let imageURL: String
    }

    struct ProfileEntry: Identifiable {
        let id: String
        let topicTitle: String
        let topicLink: String
        let contentHTML: String
        let author: String
        let authorId: String
        let date: String
        var favoriteCount: Int
        var isFavorited: Bool
        var voteState: Entry.VoteState
        var isPinned: Bool
        var imageURLs: [String]
        var parsedContent: NSAttributedString?

        static func orderedUnique(_ entries: [ProfileEntry]) -> [ProfileEntry] {
            var seen = Set<String>()
            return entries.filter { entry in
                let key = entry.id.isEmpty
                    ? "\(entry.topicLink)|\(entry.date)|\(entry.contentHTML)"
                    : entry.id
                return seen.insert(key).inserted
            }
        }
    }
}
