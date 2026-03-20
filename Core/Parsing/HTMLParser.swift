import Foundation
import Kanna

enum HTMLParser {
    static func parse(_ html: String) -> HTMLDocument? {
        try? Kanna.HTML(html: html, encoding: .utf8)
    }
}
