import Foundation
import Kanna

struct ProfileConnectionParser {
    static func parse(html: String) -> [ProfileConnection] {
        guard let doc = HTMLParser.parse(html) else { return [] }

        var seen = Set<String>()
        return doc.css("ul#follow-list li").compactMap { row in
            guard let nickAnchor = row.at_css("a#follows-nick"),
                  let profileLink = nickAnchor["href"],
                  profileLink.hasPrefix("/biri/"),
                  profileLink.count > "/biri/".count else {
                return nil
            }

            let username = nickAnchor.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !username.isEmpty, seen.insert(profileLink).inserted else { return nil }

            let avatarURL = normalizedAvatarURL(row.at_css("img")?["src"])
            let buddyLink = row.at_css("a#buddy-link")
            let buddyClasses = buddyLink?["class"] ?? ""
            let buddyText = buddyLink?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return ProfileConnection(
                username: username,
                profileLink: profileLink,
                avatarURL: avatarURL,
                followsYou: row["data-reverse-follow"] == "true",
                isFollowing: buddyClasses.contains("remove-relation") || buddyText == "takip ediliyor"
            )
        }
    }

    private static func normalizedAvatarURL(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let lowercaseValue = rawValue.lowercased()
        guard !lowercaseValue.contains("default-profile-picture"),
              !lowercaseValue.hasSuffix(".svg") else {
            return nil
        }
        return ImageURLNormalizer.normalize(rawValue)?.absoluteString
    }
}
