import Foundation

struct Channel: Identifiable {
    let id: String      // slug like "yasam", "haber"
    let name: String    // "#yaşam"
    let description: String
    let link: String    // "/basliklar/kanal/yasam"
    var isFollowed: Bool
}
