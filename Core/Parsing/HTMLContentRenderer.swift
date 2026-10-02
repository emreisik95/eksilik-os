import UIKit

enum HTMLContentRenderer {
    static func render(
        html: String,
        fontSize: Int,
        readingFont: ReadingFont,
        textColorHex: String,
        linkColorHex: String,
        spoilerBgHex: String
    ) -> NSAttributedString? {
        var processed = html
        processed = expandStarLinks(processed)
        processed = ExternalLinkPolicy.addingTextMarkers(to: processed)

        let styledHTML = """
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-size: \(fontSize)px;
            font-family: -apple-system, sans-serif;
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

        let imported = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return imported.map { applyingReadingFont(readingFont, to: $0) }
    }

    /// The HTML importer resolves CSS to system fonts. Swap every run for the reading font while
    /// keeping the run's size (so `.star-ref` stays smaller) and its bold/italic traits.
    static func applyingReadingFont(_ readingFont: ReadingFont, to text: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        let fullRange = NSRange(location: 0, length: result.length)
        result.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            guard let font = value as? UIFont else { return }
            let traits = font.fontDescriptor.symbolicTraits
            let replacement = readingFont.uiFont(
                size: font.pointSize,
                bold: traits.contains(.traitBold),
                italic: traits.contains(.traitItalic)
            )
            result.addAttribute(.font, value: replacement, range: range)
        }
        return result
    }

    /// Expand hidden bkz stars: <sup><a data-query="topic">*</a></sup> → (bkz: topic)
    private static func expandStarLinks(_ html: String) -> String {
        // Match <sup class="ab"><a ... data-query="topic name" ...>*</a></sup>
        guard let regex = try? NSRegularExpression(
            pattern: #"<sup[^>]*>\s*<a\s+[^>]*data-query\s*=\s*"([^"]*)"[^>]*>\s*\*\s*</a>\s*</sup>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return html }

        let nsHTML = html as NSString
        let range = NSRange(location: 0, length: nsHTML.length)

        // Replace with visible (bkz: topic) link
        var result = html
        let matches = regex.matches(in: html, range: range)

        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result),
                  let queryRange = Range(match.range(at: 1), in: result) else {
                continue
            }
            let query = String(result[queryRange])
            guard let lookupLink = InternalLinkPolicy.topicLookupLink(for: query) else { continue }
            let displayQuery = htmlEscaped(query)
            let replacement = " <a class=\"star-ref\" href=\"/\(lookupLink)\">(bkz: \(displayQuery))</a>"
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    private static func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
