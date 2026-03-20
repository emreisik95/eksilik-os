import Foundation

struct Topic: Identifiable, Hashable {
    let id: String
    let title: String
    let slug: String
    let entryCount: String
    let link: String

    var fullURL: String {
        "https://eksisozluk.com\(link)"
    }
}
