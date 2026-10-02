import XCTest
@testable import EksilikApp

final class ThemeShareCodeTests: XCTestCase {
    private func sampleTheme() -> CustomTheme {
        var palette = AppTheme.bosphorus.palette
        palette.link = ThemeColorToken(hex: 0xFFAA00)
        palette.appearance = .dark
        return CustomTheme(id: UUID(), name: "boğaz gecesi", baseTheme: .bosphorus, palette: palette)
    }

    func testExportedCodeRoundTripsAsANewTheme() throws {
        let theme = sampleTheme()

        let code = ThemeShareCode.encode(theme)
        let imported = try ThemeShareCode.decode(code).get()

        XCTAssertTrue(code.hasPrefix("eksilik-tema:"))
        XCTAssertNotEqual(imported.id, theme.id, "imports never overwrite an existing theme")
        XCTAssertEqual(imported.name, theme.name)
        XCTAssertEqual(imported.baseTheme, .bosphorus)
        XCTAssertEqual(imported.palette, theme.palette)
    }

    func testCodeStaysSmallEnoughToPasteInAMessage() {
        let code = ThemeShareCode.encode(sampleTheme())

        XCTAssertLessThan(code.count, 1_024)
        XCTAssertLessThanOrEqual(code.count, ThemeShareCode.maximumLength)
    }

    func testDecodingToleratesSurroundingWhitespaceAndLineBreaks() throws {
        let code = ThemeShareCode.encode(sampleTheme())
        let prefix = ThemeShareCode.prefix
        let payload = String(code.dropFirst(prefix.count))
        let middle = payload.index(payload.startIndex, offsetBy: payload.count / 2)
        let wrapped = "  \n\(prefix)\(payload[..<middle])\n \(payload[middle...])\n"

        XCTAssertEqual(try ThemeShareCode.decode(wrapped).get().palette, sampleTheme().palette)
    }

    func testDecodingRejectsMissingPrefix() {
        XCTAssertEqual(ThemeShareCode.decode("tema:abc").failure, .missingPrefix)
        XCTAssertEqual(ThemeShareCode.decode("").failure, .missingPrefix)
    }

    func testDecodingRejectsInvalidBase64() {
        XCTAssertEqual(ThemeShareCode.decode("eksilik-tema:@@@").failure, .invalidEncoding)
    }

    func testDecodingRejectsOversizedCodesBeforeParsing() {
        let code = ThemeShareCode.prefix + String(repeating: "A", count: ThemeShareCode.maximumLength)

        XCTAssertEqual(ThemeShareCode.decode(code).failure, .tooLong)
    }

    func testDecodingRejectsPayloadWithBadColor() throws {
        let json = try payloadJSON(mutating: { $0["palette"] = ["background": "#XYZXYZ"] })

        XCTAssertEqual(ThemeShareCode.decode(Self.code(for: json)).failure, .invalidPayload)
    }

    func testDecodingRejectsNonJSONPayload() {
        let code = ThemeShareCode.prefix + Data("merhaba".utf8).base64EncodedString()

        XCTAssertEqual(ThemeShareCode.decode(code).failure, .invalidPayload)
    }

    func testDecodingRejectsNewerVersions() throws {
        let json = try payloadJSON(mutating: { $0["version"] = ThemeShareCode.currentVersion + 1 })

        XCTAssertEqual(ThemeShareCode.decode(Self.code(for: json)).failure, .unsupportedVersion)
    }

    func testImportedNamesAreSanitized() throws {
        let json = try payloadJSON(mutating: { $0["name"] = "   " })

        XCTAssertEqual(try ThemeShareCode.decode(Self.code(for: json)).get().name, "adsız tema")
    }

    func testUnknownBaseThemeFallsBackToDarkInsteadOfFailing() throws {
        let json = try payloadJSON(mutating: { $0["base"] = 404 })

        XCTAssertEqual(try ThemeShareCode.decode(Self.code(for: json)).get().baseTheme, .dark)
    }

    func testEveryErrorHasLowercaseTurkishCopy() {
        let errors: [ThemeShareCode.DecodeError] = [
            .missingPrefix, .tooLong, .invalidEncoding, .invalidPayload, .unsupportedVersion,
        ]

        for error in errors {
            XCTAssertFalse(error.message.isEmpty)
            XCTAssertEqual(error.message, error.message.lowercased(with: Locale(identifier: "tr_TR")))
        }
    }

    private func payloadJSON(mutating mutate: (inout [String: Any]) -> Void) throws -> Data {
        let code = ThemeShareCode.encode(sampleTheme())
        let data = try XCTUnwrap(Data(base64Encoded: String(code.dropFirst(ThemeShareCode.prefix.count))))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        mutate(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    private static func code(for json: Data) -> String {
        ThemeShareCode.prefix + json.base64EncodedString()
    }
}

private extension Result {
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
