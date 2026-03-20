import Foundation
import UIKit

struct DebeEntry: Identifiable {
    let id: String           // entry ID from href
    let topicTitle: String   // span.caption text
    let entryLink: String    // /entry/12345?debe=true
    var isExpanded: Bool = false
    var contentHTML: String?
    var authorNick: String?
    var date: String?
    var parsedContent: NSAttributedString?
}
