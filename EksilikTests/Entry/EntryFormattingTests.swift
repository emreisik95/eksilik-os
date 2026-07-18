import XCTest
@testable import EksilikApp

final class EntryFormattingTests: XCTestCase {
    func testInsertionHappensAtTheCurrentCaret() {
        let mutation = EntryFormatting.insert(
            " güzel",
            into: "ekşi sözlük",
            selection: NSRange(location: 4, length: 0)
        )

        XCTAssertEqual(mutation.text, "ekşi güzel sözlük")
        XCTAssertEqual(mutation.selection, NSRange(location: 10, length: 0))
    }

    func testInsertionReplacesSelectionAndMovesCaretAfterMarkup() {
        let mutation = EntryFormatting.insert(
            EntryFormatting.bkz("sözlük"),
            into: "ekşi sözlük güzel",
            selection: NSRange(location: 5, length: 6)
        )

        XCTAssertEqual(mutation.text, "ekşi (bkz: sözlük) güzel")
        XCTAssertEqual(mutation.selection, NSRange(location: 18, length: 0))
    }

    func testSelectionIsClampedToUTF16TextBounds() {
        let mutation = EntryFormatting.insert(
            "!",
            into: "a🙂b",
            selection: NSRange(location: 99, length: 8)
        )

        XCTAssertEqual(mutation.text, "a🙂b!")
        XCTAssertEqual(mutation.selection, NSRange(location: 5, length: 0))
    }

    func testMarkupBuildersTrimPromptsAndPreserveExpectedSyntax() {
        XCTAssertEqual(EntryFormatting.bkz("  başlık  "), "(bkz: başlık)")
        XCTAssertEqual(EntryFormatting.hede("  yazar  "), "`yazar`")
        XCTAssertEqual(EntryFormatting.hidden("  içerik  "), "`:içerik`")
        XCTAssertEqual(
            EntryFormatting.spoiler("  sürpriz  "),
            "--- `spoiler` ---\nsürpriz\n--- `spoiler` ---"
        )
        XCTAssertEqual(EntryFormatting.link(" example.com "), "https://example.com")
        XCTAssertEqual(EntryFormatting.link("https://example.com/x"), "https://example.com/x")
    }
}
