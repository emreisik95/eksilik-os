import Foundation
import Kanna

struct EntryPageParser {
    struct ParsedPage {
        let title: String
        let slug: String
        let topicId: String
        let entries: [Entry]
        let pagination: Pagination
        let showAllLinks: [(text: String, link: String)]
    }

    static func parse(html: String, currentUsername: String?) -> ParsedPage {
        guard let doc = HTMLParser.parse(html) else {
            return ParsedPage(title: "", slug: "", topicId: "", entries: [], pagination: .empty, showAllLinks: [])
        }

        // Parse topic title
        var title = ""
        var slug = ""
        var topicId = ""
        if let titleEl = doc.at_css("h1[id^=title]") {
            title = titleEl["data-title"] ?? titleEl.text ?? ""
            slug = titleEl["data-slug"] ?? ""
            topicId = titleEl["data-id"] ?? ""
        }

        // Parse entries
        var entries: [Entry] = []
        let entryItems = doc.css("ul[id^=entry-item-list] li")
        let contents = doc.css("div[class^=content]")
        let dates = doc.css("a[class^=entry-date permalink]")

        for (index, item) in entryItems.enumerated() {
            let favoriteCount = Int(item["data-favorite-count"] ?? "0") ?? 0
            let isFavorited = item["data-isfavorite"] == "true"
            let authorNick = item["data-author"] ?? ""
            let authorId = item["data-author-id"] ?? ""

            // Author avatar
            var avatarURL: String?
            if let img = item.at_css("img[src*=ekstat]"), let src = img["src"] {
                avatarURL = src.hasPrefix("//") ? "https:\(src)" : src
                // Skip default placeholder
                if avatarURL?.contains("default-profile-picture") == true { avatarURL = nil }
            }

            let contentHTML = index < contents.count ? (contents[index].toHTML ?? "") : ""
            let imageURLs = UserProfileParser.extractImageURLs(from: contentHTML)

            var entryDate = ""
            var entryId = ""
            if index < dates.count {
                entryDate = dates[index].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let href = dates[index]["href"] ?? ""
                entryId = href.replacingOccurrences(of: "/entry/", with: "")
            }

            entries.append(Entry(
                id: entryId,
                contentHTML: contentHTML,
                author: Author(id: authorId, nick: authorNick, avatarURL: avatarURL),
                date: entryDate,
                favoriteCount: favoriteCount,
                isFavorited: isFavorited,
                voteState: .none,
                authorId: authorId,
                imageURLs: imageURLs
            ))
        }

        // Parse "show all" links
        var showAllLinks: [(text: String, link: String)] = []
        for el in doc.css("a[class^=showall more-data]") {
            if let text = el.text, let href = el["href"] {
                showAllLinks.append((text: text, link: href))
            }
        }

        let pagination = PaginationParser.parse(html: html)

        return ParsedPage(
            title: title,
            slug: slug,
            topicId: topicId,
            entries: entries,
            pagination: pagination,
            showAllLinks: showAllLinks
        )
    }
}
