import XCTest
@testable import EksilikApp

final class ImageURLNormalizerTests: XCTestCase {
    func testProtocolRelativeURLUsesHTTPS() {
        XCTAssertEqual(
            ImageURLNormalizer.normalize("//cdn.example.com/photo.jpg")?.absoluteString,
            "https://cdn.example.com/photo.jpg"
        )
    }

    func testHTMLEntitiesAreDecoded() {
        XCTAssertEqual(
            ImageURLNormalizer.normalize("https://cdn.example.com/a.jpg?x=1&amp;y=2")?.absoluteString,
            "https://cdn.example.com/a.jpg?x=1&y=2"
        )
    }

    func testImageExtensionAllowsQueryString() {
        XCTAssertTrue(ImageURLNormalizer.isImageURL("https://cdn.example.com/a.webp?size=large"))
    }

    func testInvalidSchemeIsRejected() {
        XCTAssertNil(ImageURLNormalizer.normalize("javascript:alert(1)"))
    }

    func testExtractionPreservesOrderAndDeduplicates() {
        let html = """
        <a href="https://cdn.example.com/first.png">first</a>
        <img src="//cdn.example.com/second.jpg">
        <a href="https://cdn.example.com/first.png">duplicate</a>
        """

        XCTAssertEqual(UserProfileParser.extractImageURLs(from: html), [
            "https://cdn.example.com/first.png",
            "https://cdn.example.com/second.jpg",
        ])
    }
}
