import Foundation
import Kanna

enum SeylerArticleParser {
    static func parse(html: String, sourceURL: URL) -> SeylerArticle? {
        guard let document = HTMLParser.parse(html),
              let root = document.at_css("#content-body-area.content-detail")
                ?? document.at_css(".content-detail") else {
            return nil
        }

        let title = normalizedText(root.at_css("h1.content-title")?.text)
        let bodyElements = Array(root.css(".mashup-components > .content-block > .content-body"))
        let blocks = bodyElements.flatMap(parseBody)
        guard !title.isEmpty, !blocks.isEmpty else { return nil }

        let stats = root.at_css(".content-meta .meta-stats")
        let statValues = stats.map { Array($0.css("b")).compactMap { normalizedText($0.text).nilIfEmpty } }
            ?? []
        let authors = unique(
            Array(root.css(".content-seperator .content-author"))
                .compactMap { normalizedText($0.text).nilIfEmpty }
        )

        return SeylerArticle(
            sourceURL: sourceURL,
            title: title,
            summary: normalizedText(root.at_css(".content-spot")?.text).nilIfEmpty,
            category: normalizedText(root.at_css(".meta-category a")?.text).nilIfEmpty,
            date: normalizedText(root.at_css(".meta-date")?.text).nilIfEmpty,
            readCount: statValues.first,
            shareCount: statValues.dropFirst().first,
            heroImageURL: imageURL(from: root.at_css(".cover-img img"), sourceURL: sourceURL),
            authors: authors,
            blocks: blocks
        )
    }

    private static func parseBody(_ body: Kanna.XMLElement) -> [SeylerArticleBlock] {
        body.children.flatMap { parseElement($0) }
    }

    private static func parseElement(_ element: Kanna.XMLElement) -> [SeylerArticleBlock] {
        let tag = element.tagName?.lowercased() ?? ""
        let classNames = Set(element.className?.lowercased().split(separator: " ").map(String.init) ?? [])

        if classNames.contains("medium-insert-embeds") || classNames.contains("embed") {
            return []
        }

        switch tag {
        case "p":
            return normalizedText(element.text).nilIfEmpty.map { [.paragraph($0)] } ?? []
        case "h1", "h2", "h3", "h4", "h5", "h6":
            return normalizedText(element.text).nilIfEmpty.map { [.heading($0)] } ?? []
        case "blockquote":
            return normalizedText(element.text).nilIfEmpty.map { [.quote($0)] } ?? []
        case "ul", "ol":
            return listBlock(from: element)
        case "img":
            return imageBlock(from: element)
        case "figure":
            return figureBlock(from: element)
        default:
            return containerBlocks(from: element, classNames: classNames)
        }
    }

    private static func listBlock(from element: Kanna.XMLElement) -> [SeylerArticleBlock] {
        let items = Array(element.css("li")).compactMap { normalizedText($0.text).nilIfEmpty }
        guard !items.isEmpty else { return [] }
        return [.list(items)]
    }

    private static func figureBlock(from element: Kanna.XMLElement) -> [SeylerArticleBlock] {
        guard let image = element.at_css("img") else { return [] }
        let caption = normalizedText(element.at_css("figcaption")?.text).nilIfEmpty
            ?? normalizedText(image["alt"]).nilIfEmpty
        guard let url = imageURL(from: image, sourceURL: SeylerEndpoint.baseURL) else { return [] }
        return [.image(url: url, caption: caption)]
    }

    private static func containerBlocks(
        from element: Kanna.XMLElement,
        classNames: Set<String>
    ) -> [SeylerArticleBlock] {
        if classNames.contains("medium-insert-images") {
            return Array(element.css("figure")).flatMap { parseElement($0) }
        }
        return element.children.flatMap { parseElement($0) }
    }

    private static func imageBlock(from image: Kanna.XMLElement) -> [SeylerArticleBlock] {
        guard let url = imageURL(from: image, sourceURL: SeylerEndpoint.baseURL) else { return [] }
        return [.image(url: url, caption: normalizedText(image["alt"]).nilIfEmpty)]
    }

    private static func imageURL(from image: Kanna.XMLElement?, sourceURL: URL) -> URL? {
        guard let image else { return nil }
        for value in [image["data-src"], image["src"]].compactMap({ $0 }) {
            guard !value.contains("image-placeholder"),
                  !value.hasSuffix("/empty.png"),
                  let url = URL(string: value, relativeTo: sourceURL)?.absoluteURL,
                  let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http" else {
                continue
            }
            return url
        }
        return nil
    }

    private static func normalizedText(_ value: String?) -> String {
        (value ?? "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
