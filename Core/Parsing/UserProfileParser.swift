import Foundation
import Kanna

struct UserProfileParser {
    static func parse(html: String) -> UserProfile {
        guard let doc = HTMLParser.parse(html) else {
            return emptyProfile()
        }

        // Username — h1#user-profile-title[data-nick]
        let nick = doc.at_css("h1#user-profile-title")?["data-nick"]
            ?? doc.at_css("h1#user-profile-title")?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        // Avatar — img inside #profile-logo with ekstat.com/profiles src
        var avatarURL: String?
        if let img = doc.at_css("div#profile-logo img"), let src = img["src"], src.contains("ekstat.com/profiles") {
            avatarURL = src.hasPrefix("//") ? "https:\(src)" : src
        }

        // Bio — p.muted (e.g. "bıçkın (495)")
        let bio = doc.at_css("p.muted")?.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Verified badge
        let isVerified = doc.at_css("div#verified-badge") != nil

        // Badges — a.user-profile-badge-item with child img
        var badges: [UserProfile.Badge] = []
        for a in doc.css("a.user-profile-badge-item") {
            let name = a["data-name"] ?? a["title"] ?? ""
            if let img = a.at_css("img"), let src = img["src"] {
                let url = src.hasPrefix("//") ? "https:\(src)" : src
                badges.append(UserProfile.Badge(name: name, imageURL: url))
            }
        }

        // Stats — exact IDs
        let entryCount = Int(doc.at_css("span#entry-count-total")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
        let followerCount = Int(doc.at_css("span#user-follower-count")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
        let followingCount = Int(doc.at_css("span#user-following-count")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0

        // Join date — div.recorddate text content (e.g. "şubat 1999")
        var joinDate: String?
        if let el = doc.at_css("div.recorddate") {
            // Text includes SVG icon text, strip it — just get the date portion
            let raw = el.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !raw.isEmpty {
                joinDate = raw
            }
        }

        return UserProfile(
            nick: nick,
            avatarURL: avatarURL,
            bio: bio,
            isVerified: isVerified,
            badges: badges,
            entryCount: entryCount,
            followerCount: followerCount,
            followingCount: followingCount,
            joinDate: joinDate,
            entries: [] // Entries loaded separately via tab endpoints
        )
    }

    /// Parse entry list pages for profile tabs (son-entryleri, favori-entryleri, etc.)
    static func parseProfileEntries(html: String) -> [UserProfile.ProfileEntry] {
        guard let doc = HTMLParser.parse(html) else { return [] }

        var entries: [UserProfile.ProfileEntry] = []

        let entryItems = doc.css("ul[id^=entry-item-list] li")
        let contents = doc.css("div[class^=content]")
        let dates = doc.css("a[class^=entry-date permalink]")
        let topicTitles = doc.css("h1[id^=title]")

        for (index, item) in entryItems.enumerated() {
            let authorNick = item["data-author"] ?? ""
            let authorId = item["data-author-id"] ?? ""
            let favoriteCount = Int(item["data-favorite-count"] ?? "0") ?? 0
            let isFavorited = item["data-isfavorite"] == "true"
            let contentHTML = index < contents.count ? (contents[index].toHTML ?? "") : ""

            // Pinned entry check
            let isPinned = item.at_css("div[class*=pinned-icon]") != nil

            // Extract image URLs from content
            let imageURLs = extractImageURLs(from: contentHTML)

            var entryDate = ""
            var entryId = ""
            if index < dates.count {
                entryDate = dates[index].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let href = dates[index]["href"] ?? ""
                entryId = href.replacingOccurrences(of: "/entry/", with: "")
            }

            var topicTitle = ""
            var topicLink = ""
            if index < topicTitles.count {
                topicTitle = topicTitles[index]["data-title"] ?? topicTitles[index].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                topicLink = topicTitles[index]["data-slug"] ?? ""
            } else if let first = topicTitles.first {
                topicTitle = first["data-title"] ?? first.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                topicLink = first["data-slug"] ?? ""
            }

            entries.append(UserProfile.ProfileEntry(
                id: entryId,
                topicTitle: topicTitle,
                topicLink: topicLink,
                contentHTML: contentHTML,
                author: authorNick,
                authorId: authorId,
                date: entryDate,
                favoriteCount: favoriteCount,
                isFavorited: isFavorited,
                voteState: .none,
                isPinned: isPinned,
                imageURLs: imageURLs
            ))
        }

        return entries
    }

    /// Extract image URLs from HTML content (img src and links to image files)
    static func extractImageURLs(from html: String) -> [String] {
        let imgPattern = try? NSRegularExpression(pattern: #"<img[^>]+src\s*=\s*"([^"]+)"#)
        let linkPattern = try? NSRegularExpression(pattern: #"<a[^>]+href\s*=\s*"([^"]+\.(?:jpg|jpeg|png|gif|webp)(?:\?[^"]*)?)""#, options: .caseInsensitive)
        let range = NSRange(html.startIndex..., in: html)
        var urls: [String] = []

        for pattern in [imgPattern, linkPattern].compactMap({ $0 }) {
            for match in pattern.matches(in: html, range: range) {
                if let urlRange = Range(match.range(at: 1), in: html) {
                    var url = String(html[urlRange])
                    if url.hasPrefix("//") { url = "https:\(url)" }
                    if url.hasPrefix("http"), !url.contains("eksisozluk.com/Content"), !url.contains("logo") {
                        urls.append(url)
                    }
                }
            }
        }
        return Array(Set(urls)) // deduplicate
    }

    private static func emptyProfile() -> UserProfile {
        UserProfile(nick: "", avatarURL: nil, bio: nil, isVerified: false, badges: [], entryCount: 0,
                    followerCount: 0, followingCount: 0, joinDate: nil, entries: [])
    }
}
