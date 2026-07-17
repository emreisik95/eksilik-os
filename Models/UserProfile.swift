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
    let followerLink: String?
    let followingLink: String?
    let joinDate: String?
    var entries: [ProfileEntry]

    init(
        nick: String,
        avatarURL: String?,
        bio: String?,
        isVerified: Bool,
        badges: [Badge],
        entryCount: Int,
        followerCount: Int,
        followingCount: Int,
        followerLink: String? = nil,
        followingLink: String? = nil,
        joinDate: String?,
        entries: [ProfileEntry]
    ) {
        self.nick = nick
        self.avatarURL = avatarURL
        self.bio = bio
        self.isVerified = isVerified
        self.badges = badges
        self.entryCount = entryCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.followerLink = followerLink
        self.followingLink = followingLink
        self.joinDate = joinDate
        self.entries = entries
    }

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
