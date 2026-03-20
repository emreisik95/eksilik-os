import Foundation
import Kanna

struct PaginationParser {
    static func parse(html: String) -> Pagination {
        guard let doc = HTMLParser.parse(html) else { return .empty }

        for pager in doc.css("div[class^=pager]") {
            guard let currentStr = pager["data-currentpage"],
                  let totalStr = pager["data-pagecount"],
                  let current = Int(currentStr),
                  let total = Int(totalStr) else { continue }
            return Pagination(currentPage: current, totalPages: total)
        }

        return .empty
    }
}
