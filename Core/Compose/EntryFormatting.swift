import Foundation

struct EntryTextMutation: Equatable {
    let text: String
    let selection: NSRange
}

enum EntryFormatting {
    static func insert(
        _ replacement: String,
        into text: String,
        selection: NSRange
    ) -> EntryTextMutation {
        let source = text as NSString
        let location = min(max(selection.location, 0), source.length)
        let availableLength = source.length - location
        let length = min(max(selection.length, 0), availableLength)
        let safeSelection = NSRange(location: location, length: length)
        let updatedText = source.replacingCharacters(in: safeSelection, with: replacement)
        let caret = location + (replacement as NSString).length

        return EntryTextMutation(
            text: updatedText,
            selection: NSRange(location: caret, length: 0)
        )
    }

    static func bkz(_ text: String) -> String {
        "(bkz: \(clean(text)))"
    }

    static func hede(_ text: String) -> String {
        "`\(clean(text))`"
    }

    static func hidden(_ text: String) -> String {
        "`:\(clean(text))`"
    }

    static func spoiler(_ text: String) -> String {
        "--- `spoiler` ---\n\(clean(text))\n--- `spoiler` ---"
    }

    static func link(_ text: String) -> String {
        let value = clean(text)
        guard !value.isEmpty else { return "https://" }
        guard !value.lowercased().hasPrefix("http://"),
              !value.lowercased().hasPrefix("https://") else {
            return value
        }
        return "https://\(value)"
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
