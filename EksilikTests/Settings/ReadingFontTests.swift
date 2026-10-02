import UIKit
import XCTest
@testable import EksilikApp

final class ReadingFontTests: XCTestCase {
    func testStoredValueResolvesToTheMatchingFont() {
        for font in ReadingFont.allCases {
            XCTAssertEqual(ReadingFont.resolve(storedValue: font.rawValue), font)
        }
    }

    func testMissingOrUnknownStoredValueFallsBackToSystem() {
        XCTAssertEqual(ReadingFont.resolve(storedValue: nil), .system)
        XCTAssertEqual(ReadingFont.resolve(storedValue: ""), .system)
        XCTAssertEqual(ReadingFont.resolve(storedValue: "Comic Sans"), .system)
        XCTAssertEqual(ReadingFont.resolve(storedValue: "Helvetica"), .system)
    }

    func testCatalogOffersSystemDesignsBeforeBundledFonts() {
        XCTAssertEqual(
            ReadingFont.allCases.map(\.name),
            [
                "sistem", "new york", "yuvarlak", "mono",
                "atkinson hyperlegible", "source serif", "ibm plex sans", "jetbrains mono",
            ]
        )
        XCTAssertEqual(Set(ReadingFont.allCases.map(\.rawValue)).count, ReadingFont.allCases.count)
        XCTAssertTrue(ReadingFont.allCases.allSatisfy { !$0.summary.isEmpty })
    }

    func testSystemDesignsMapToUIKitDesigns() {
        XCTAssertEqual(ReadingFont.system.systemDesign, .default)
        XCTAssertEqual(ReadingFont.newYork.systemDesign, .serif)
        XCTAssertEqual(ReadingFont.rounded.systemDesign, .rounded)
        XCTAssertEqual(ReadingFont.monospaced.systemDesign, .monospaced)
        XCTAssertNil(ReadingFont.system.faces)
    }

    func testBundledFontsExposeRegularItalicAndBoldFaces() throws {
        let faces = try XCTUnwrap(ReadingFont.atkinson.faces)

        XCTAssertEqual(faces.regular, "AtkinsonHyperlegibleNext-Regular")
        XCTAssertEqual(faces.italic, "AtkinsonHyperlegibleNext-Italic")
        XCTAssertEqual(faces.bold, "AtkinsonHyperlegibleNext-Bold")
        XCTAssertNil(ReadingFont.atkinson.systemDesign)
    }

    func testBoldWinsWhenBoldAndItalicAreBothRequested() {
        XCTAssertEqual(ReadingFont.sourceSerif.faceName(bold: false, italic: false), "SourceSerif4-Regular")
        XCTAssertEqual(ReadingFont.sourceSerif.faceName(bold: false, italic: true), "SourceSerif4-It")
        XCTAssertEqual(ReadingFont.sourceSerif.faceName(bold: true, italic: false), "SourceSerif4-Bold")
        XCTAssertEqual(ReadingFont.sourceSerif.faceName(bold: true, italic: true), "SourceSerif4-Bold")
        XCTAssertNil(ReadingFont.newYork.faceName(bold: true, italic: false))
    }

    func testEveryBundledFaceIsRegisteredWithTheApp() throws {
        for font in ReadingFont.allCases {
            guard let faces = font.faces else { continue }
            for name in [faces.regular, faces.italic, faces.bold] {
                XCTAssertNotNil(UIFont(name: name, size: 15), "\(name) should be listed in UIAppFonts")
            }
        }
    }

    func testBundledFontUsesItsFaceAtTheRequestedSize() throws {
        let font = ReadingFont.plexSans.uiFont(size: 19, bold: false, italic: true)

        XCTAssertEqual(font.fontName, "IBMPlexSans-Italic")
        XCTAssertEqual(font.pointSize, 19)
    }

    func testMissingBundledFaceFallsBackToSystemFontWithTraits() {
        let font = ReadingFont.jetBrainsMono.uiFont(size: 17, bold: true, italic: false) { _, _ in nil }

        XCTAssertEqual(font.pointSize, 17)
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertEqual(font.fontName, ReadingFont.system.uiFont(size: 17, bold: true).fontName)
    }

    func testSystemDesignKeepsBoldAndItalicTraits() {
        let font = ReadingFont.newYork.uiFont(size: 16, bold: true, italic: true)
        let traits = font.fontDescriptor.symbolicTraits

        XCTAssertEqual(font.pointSize, 16)
        XCTAssertTrue(traits.contains(.traitBold))
        XCTAssertTrue(traits.contains(.traitItalic))
        XCTAssertNotEqual(font.familyName, UIFont.systemFont(ofSize: 16).familyName)
    }

    func testRendererAppliesReadingFontToBodyAndBoldRuns() throws {
        let rendered = try XCTUnwrap(HTMLContentRenderer.render(
            html: "düz metin <b>kalın</b> <i>eğik</i>",
            fontSize: 18,
            readingFont: .sourceSerif,
            textColorHex: "#000000",
            linkColorHex: "#0000FF",
            spoilerBgHex: "#FFFF00"
        ))

        let fonts = Self.fontNames(in: rendered)
        XCTAssertEqual(fonts["düz"], "SourceSerif4-Regular")
        XCTAssertEqual(fonts["kalın"], "SourceSerif4-Bold")
        XCTAssertEqual(fonts["eğik"], "SourceSerif4-It")
    }

    func testRendererKeepsTheConfiguredFontSize() throws {
        let rendered = try XCTUnwrap(HTMLContentRenderer.render(
            html: "metin",
            fontSize: 21,
            readingFont: .monospaced,
            textColorHex: "#000000",
            linkColorHex: "#0000FF",
            spoilerBgHex: "#FFFF00"
        ))

        let font = try XCTUnwrap(rendered.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        XCTAssertEqual(font.pointSize, 21, accuracy: 0.5)
        let narrow = ("iiii" as NSString).size(withAttributes: [.font: font]).width
        let wide = ("MMMM" as NSString).size(withAttributes: [.font: font]).width
        XCTAssertEqual(narrow, wide, accuracy: 0.5, "mono design should keep a fixed advance")
    }

    private static func fontNames(in text: NSAttributedString) -> [String: String] {
        var result: [String: String] = [:]
        let string = text.string as NSString
        text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let font = value as? UIFont else { return }
            for word in string.substring(with: range).split(whereSeparator: \.isWhitespace) {
                result[String(word)] = font.fontName
            }
        }
        return result
    }
}
