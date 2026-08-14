import Foundation
import Kanna

enum HTMLPlainText {
    static func render(_ html: String) -> String {
        let prepared = html
            .replacingOccurrences(
                of: #"<br\s*/?>"#,
                with: "\n",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"</(?:p|div|li|h[1-6]|blockquote)>"#,
                with: "\n",
                options: [.regularExpression, .caseInsensitive]
            )

        guard let document = HTMLParser.parse("<html><body>\(prepared)</body></html>"),
              let text = document.at_css("body")?.text else {
            return normalize(fallback(from: prepared))
        }

        return normalize(text)
    }

    private static func fallback(from html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    private static func normalize(_ value: String) -> String {
        value
            .components(separatedBy: .newlines)
            .map { line in
                line
                    .replacingOccurrences(of: #"[\t ]+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
