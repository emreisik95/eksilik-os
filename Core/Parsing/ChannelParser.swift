import Foundation
import Kanna

struct ChannelParser {
    static func parse(html: String) -> [Channel] {
        guard let doc = HTMLParser.parse(html) else { return [] }

        var channels: [Channel] = []

        for li in doc.css("ul#channel-follow-list li") {
            guard let a = li.at_css("h3 a.index-link") else { continue }

            let name = a.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let href = a["href"] ?? ""
            let description = a["title"] ?? li.at_css("p")?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Extract slug from href: /basliklar/m/kanal/yasam → yasam
            let slug = href.components(separatedBy: "/").last ?? name

            let isFollowed = li.at_css("button.channel-button")?["data-followed"] == "true"

            // Use the non-mobile channel link for topic list navigation
            let channelLink = "basliklar/kanal/\(slug)"

            channels.append(Channel(
                id: slug,
                name: name,
                description: description,
                link: channelLink,
                isFollowed: isFollowed
            ))
        }

        return channels
    }
}
