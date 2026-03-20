import Foundation

struct Author: Identifiable, Hashable {
    let id: String
    let nick: String
    var avatarURL: String?

    var profileURL: String {
        "https://eksisozluk.com/biri/\(nick.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? nick)"
    }
}
