import UIKit

enum HTMLContentRenderer {
    static func render(
        html: String,
        fontSize: Int,
        fontName: String,
        textColorHex: String,
        linkColorHex: String,
        spoilerBgHex: String
    ) -> NSAttributedString? {
        var processed = html
        processed = expandStarLinks(processed)
        processed = addExternalLinkIcons(processed)

        let styledHTML = """
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-size: \(fontSize)px;
            font-family: '\(fontName)', -apple-system, sans-serif;
            color: \(textColorHex);
            word-wrap: break-word;
            overflow-wrap: break-word;
            -webkit-text-size-adjust: none;
            line-height: 1.5;
        }
        a { color: \(linkColorHex); text-decoration: none; }
        mark { background-color: \(spoilerBgHex); padding: 2px 4px; }
        .star-ref { font-size: 0.85em; }
        </style></head><body>\(processed)</body></html>
        """

        guard let data = styledHTML.data(using: .utf8) else { return nil }

        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }

    /// Expand hidden bkz stars: <sup><a data-query="topic">*</a></sup> → (bkz: topic)
    private static func expandStarLinks(_ html: String) -> String {
        // Match <sup><a ... data-query="topic name" ...>*</a></sup>
        guard let regex = try? NSRegularExpression(
            pattern: #"<sup>\s*<a\s+[^>]*data-query\s*=\s*"([^"]*)"[^>]*>\s*\*\s*</a>\s*</sup>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return html }

        let nsHTML = html as NSString
        let range = NSRange(location: 0, length: nsHTML.length)

        // Replace with visible (bkz: topic) link
        var result = html
        let matches = regex.matches(in: html, range: range)

        for match in matches.reversed() {
            let fullRange = Range(match.range, in: result)!
            let queryRange = Range(match.range(at: 1), in: result)!
            let query = String(result[queryRange])

            let replacement = " <a class=\"star-ref\" href=\"/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)\">(bkz: \(query))</a>"
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    /// Add → icon to external links
    private static func addExternalLinkIcons(_ html: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"(<a\s+[^>]*href\s*=\s*"https?://[^"]*"[^>]*>)(.*?)(</a>)"#,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return html }

        let nsHTML = html as NSString
        let range = NSRange(location: 0, length: nsHTML.length)

        return regex.stringByReplacingMatches(
            in: html,
            range: range,
            withTemplate: "$1$2 →$3"
        )
    }
}
