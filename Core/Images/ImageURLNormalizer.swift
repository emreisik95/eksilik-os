import Foundation

enum ImageURLNormalizer {
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "avif"]

    static func normalize(_ rawValue: String) -> URL? {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        value = decodeHTMLEntities(value)
        if value.hasPrefix("//") {
            value = "https:\(value)"
        }

        guard var components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              components.host?.isEmpty == false else {
            return nil
        }

        components.scheme = scheme
        return components.url
    }

    static func isImageURL(_ rawValue: String) -> Bool {
        guard let url = normalize(rawValue) else { return false }
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    static func normalizeStrings(_ rawValues: [String]) -> [String] {
        var seen = Set<String>()
        return rawValues.compactMap { rawValue in
            guard let value = normalize(rawValue)?.absoluteString,
                  seen.insert(value).inserted else {
                return nil
            }
            return value
        }
    }

    private static func decodeHTMLEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&", options: .caseInsensitive)
            .replacingOccurrences(of: "&#38;", with: "&")
            .replacingOccurrences(of: "&#x26;", with: "&", options: .caseInsensitive)
            .replacingOccurrences(of: "&quot;", with: "\"", options: .caseInsensitive)
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}

struct ImageGalleryPresentation: Identifiable, Equatable {
    let id = UUID()
    let imageURLs: [String]
    let initialIndex: Int

    init?(imageURLs: [String], initialIndex: Int) {
        let normalizedURLs = ImageURLNormalizer.normalizeStrings(imageURLs)
        guard !normalizedURLs.isEmpty else { return nil }

        self.imageURLs = normalizedURLs
        self.initialIndex = min(max(initialIndex, 0), normalizedURLs.count - 1)
    }
}
