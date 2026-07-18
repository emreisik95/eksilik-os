import Foundation

enum WidgetFeedParser {
    static func parseTopics(html: String) -> [WidgetFeedItem] {
        guard let listStart = html.range(of: "topic-list", options: .caseInsensitive) else {
            return []
        }

        return anchorMatches(in: String(html[listStart.lowerBound...])).compactMap { link, body in
            guard link.hasPrefix("/"), !link.hasPrefix("/entry/") else { return nil }
            let metadata = firstMatch(
                pattern: #"<small\b[^>]*>(.*?)</small>"#,
                in: body
            ).map(cleanText)
            let titleBody = body.replacingOccurrences(
                of: #"<small\b[^>]*>.*?</small>"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            let title = cleanText(titleBody)
            guard !title.isEmpty else { return nil }

            return WidgetFeedItem(
                title: title,
                subtitle: nil,
                metadata: metadata?.isEmpty == false ? metadata : nil,
                link: link
            )
        }
    }

    static func parseDebe(html: String) -> [WidgetFeedItem] {
        anchorMatches(in: html).compactMap { link, body in
            guard link.range(of: #"^/entry/\d+"#, options: .regularExpression) != nil,
                  let caption = firstMatch(
                    pattern: #"<span\b[^>]*class\s*=\s*[\"'][^\"']*caption[^\"']*[\"'][^>]*>(.*?)</span>"#,
                    in: body
                  ) else {
                return nil
            }

            let title = cleanText(caption)
            guard !title.isEmpty else { return nil }
            let directLink = link.components(separatedBy: "?").first ?? link
            return WidgetFeedItem(
                title: title,
                subtitle: "debe",
                metadata: nil,
                link: directLink
            )
        }
    }

    private static func anchorMatches(in html: String) -> [(String, String)] {
        let pattern = #"<a\b[^>]*href\s*=\s*[\"']([^\"']+)[\"'][^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        let source = html as NSString
        return regex.matches(
            in: html,
            range: NSRange(location: 0, length: source.length)
        ).prefix(20).compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }
            return (
                source.substring(with: match.range(at: 1)),
                source.substring(with: match.range(at: 2))
            )
        }
    }

    private static func firstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return nil
        }

        let source = text as NSString
        guard let match = regex.firstMatch(
            in: text,
            range: NSRange(location: 0, length: source.length)
        ), match.numberOfRanges > 1 else {
            return nil
        }
        return source.substring(with: match.range(at: 1))
    }

    private static func cleanText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
