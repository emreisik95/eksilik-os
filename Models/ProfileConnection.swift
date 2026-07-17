import Foundation

struct ProfileConnection: Identifiable, Equatable {
    let username: String
    let profileLink: String
    let avatarURL: String?
    let followsYou: Bool
    let isFollowing: Bool

    var id: String { profileLink }
}
