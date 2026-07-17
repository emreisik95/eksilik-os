import Foundation

enum ExternalLinkPolicy {
    static let textMarker = "\u{2197}\u{FE0E}"

    private static let nativeAppDomains: Set<String> = [
        "x.com",
        "twitter.com",
        "instagram.com",
        "threads.net",
        "youtube.com",
        "youtu.be",
        "tiktok.com",
        "linkedin.com",
        "facebook.com",
        "fb.watch",
        "reddit.com",
        "redd.it",
        "twitch.tv",
        "spotify.com",
        "soundcloud.com",
        "pinterest.com",
        "snapchat.com",
        "bsky.app",
        "t.me",
        "telegram.me",
        "wa.me",
        "discord.com",
        "discord.gg",
    ]

    static func addingTextMarkers(to html: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"(<a\s+[^>]*href\s*=\s*"https?://[^"]*"[^>]*>)(.*?)(</a>)"#,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return html }

        let range = NSRange(location: 0, length: (html as NSString).length)
        return regex.stringByReplacingMatches(
            in: html,
            range: range,
            withTemplate: "$1$2 \(textMarker)$3"
        )
    }

    static func prefersNativeApp(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else {
            return false
        }

        return nativeAppDomains.contains { domain in
            host == domain || host.hasSuffix(".\(domain)")
        }
    }
}
