import Foundation
import Kanna

enum SeylerParser {
    static func parse(html: String) -> [SeylerStory] {
        guard let document = HTMLParser.parse(html) else { return [] }

        var stories: [SeylerStory] = []
        var seenURLs = Set<String>()

        for element in document.css("a.hero-item") {
            append(parseHero(element), to: &stories, seenURLs: &seenURLs)
        }
        for element in document.css(".content-box") {
            append(parseCard(element, family: .content), to: &stories, seenURLs: &seenURLs)
        }
        for element in document.css(".mashup-box") {
            append(parseCard(element, family: .mashup), to: &stories, seenURLs: &seenURLs)
        }

        return stories
    }

    private enum CardFamily {
        case content
        case mashup

        var titleSelector: String {
            switch self {
            case .content: return ".content-title a[href]"
            case .mashup: return ".mashup-title a[href]"
            }
        }

        var imageSelector: String {
            switch self {
            case .content: return ".content-img img"
            case .mashup: return ".mashup-img img"
            }
        }
    }

    private static func parseHero(_ element: Kanna.XMLElement) -> SeylerStory? {
        guard let href = element["href"],
              let url = SeylerEndpoint.articleURL(from: href) else { return nil }

        let image = element.at_css("img")
        let title = normalizedText(
            element.at_css(".hero-headline")?.text
                ?? image?["alt"]
                ?? element.text
        )
        guard !title.isEmpty else { return nil }

        return SeylerStory(
            title: title,
            url: url,
            imageURL: imageURL(from: image, prefersCSSBackground: true),
            category: nil,
            readCount: nil,
            isFeatured: true
        )
    }

    private static func parseCard(_ element: Kanna.XMLElement, family: CardFamily) -> SeylerStory? {
        let titleLink = element.at_css(family.titleSelector)
        let image = element.at_css(family.imageSelector)
        let imageLink = image?.parent
        guard let href = titleLink?["href"] ?? imageLink?["href"],
              let url = SeylerEndpoint.articleURL(from: href) else { return nil }

        let title = normalizedText(
            titleLink?.text
                ?? titleLink?["title"]
                ?? image?["alt"]
        )
        guard !title.isEmpty else { return nil }

        return SeylerStory(
            title: title,
            url: url,
            imageURL: imageURL(from: image, prefersCSSBackground: false),
            category: normalizedText(element.at_css(".meta-category")?.text).nilIfEmpty,
            readCount: normalizedText(element.at_css(".meta-stats")?.text).nilIfEmpty,
            isFeatured: false
        )
    }

    private static func append(
        _ story: SeylerStory?,
        to stories: inout [SeylerStory],
        seenURLs: inout Set<String>
    ) {
        guard let story, seenURLs.insert(story.id).inserted else { return }
        stories.append(story)
    }

    private static func imageURL(
        from image: Kanna.XMLElement?,
        prefersCSSBackground: Bool
    ) -> URL? {
        guard let image else { return nil }
        let cssValue = cssBackgroundURL(from: image["style"])
        let candidates = prefersCSSBackground
            ? [cssValue, image["data-src"], image["src"]]
            : [image["data-src"], image["src"], cssValue]

        for candidate in candidates.compactMap({ $0 }) {
            guard !candidate.contains("/public/images/layout/empty.png"),
                  !candidate.hasSuffix("/empty.png"),
                  let url = URL(string: candidate, relativeTo: SeylerEndpoint.baseURL)?.absoluteURL,
                  let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http" else {
                continue
            }
            return url
        }
        return nil
    }

    private static func cssBackgroundURL(from style: String?) -> String? {
        guard let style,
              let markerRange = style.range(of: "url(", options: .caseInsensitive) else {
            return nil
        }
        let remainder = style[markerRange.upperBound...]
        guard let closing = remainder.firstIndex(of: ")") else { return nil }
        return remainder[..<closing]
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(
                CharacterSet(charactersIn: "'\"")
            ))
            .nilIfEmpty
    }

    private static func normalizedText(_ value: String?) -> String {
        (value ?? "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
