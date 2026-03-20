import Foundation

struct MessageThread: Identifiable {
    let id: String
    let username: String
    let preview: String
    let date: String
    let messageCount: String
    let link: String
    var isUnread: Bool
}
