import Foundation

enum MessageDirection: Equatable, Sendable {
    case incoming
    case outgoing
    case unknown
}

struct Message: Identifiable {
    let id: String
    let contentHTML: String
    let sender: String
    let date: String
    let direction: MessageDirection
}
