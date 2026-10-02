import XCTest
@testable import EksilikApp

final class ThemePaletteCodingTests: XCTestCase {
    func testEveryBuiltInPaletteRoundTripsThroughJSON() throws {
        for theme in AppTheme.allCases {
            let data = try JSONEncoder().encode(theme.palette)
            let decoded = try JSONDecoder().decode(ThemePalette.self, from: data)
            XCTAssertEqual(decoded, theme.palette, "\(theme.name) palette round trip")
        }
    }

    func testTokensAreStoredAsReadableHexStrings() throws {
        let data = try JSONEncoder().encode(AppTheme.light.palette)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["background"] as? String, "#FFFFFF")
        XCTAssertEqual(object["accent"] as? String, "#4E7D1C")
        XCTAssertEqual(object["appearance"] as? String, "light")
        XCTAssertEqual(object.count, ThemeTokenKey.allCases.count + 1)
    }

    func testPaletteWithInvalidHexIsRejected() throws {
        var object = try paletteObject(AppTheme.dark.palette)
        object["link"] = "#12345"
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(ThemePalette.self, from: data))
    }

    func testPaletteWithMissingTokenIsRejected() throws {
        var object = try paletteObject(AppTheme.dark.palette)
        object.removeValue(forKey: "spoilerBackground")
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try JSONDecoder().decode(ThemePalette.self, from: data))
    }

    func testHexParsingAcceptsOnlySixHexDigits() {
        XCTAssertEqual(ThemeColorToken(hexString: "#1a2B3c")?.hex, 0x1A2B3C)
        XCTAssertEqual(ThemeColorToken(hexString: "1A2B3C")?.hex, 0x1A2B3C)
        XCTAssertEqual(ThemeColorToken(hexString: "  #000000 \n")?.hex, 0x000000)
        XCTAssertNil(ThemeColorToken(hexString: "#1A2B3"))
        XCTAssertNil(ThemeColorToken(hexString: "#1A2B3C4D"))
        XCTAssertNil(ThemeColorToken(hexString: "#GG0000"))
        XCTAssertNil(ThemeColorToken(hexString: "#+12345"))
        XCTAssertNil(ThemeColorToken(hexString: ""))
    }

    func testColorConversionRoundTripsSRGBTokens() {
        for hex: UInt32 in [0x000000, 0xFFFFFF, 0x66B43F, 0x0027B8, 0xF4729B] {
            let token = ThemeColorToken(hex: hex)
            XCTAssertEqual(ThemeColorToken(color: token.color), token, token.hexString)
        }
    }

    func testTokenCatalogUsesTheTurkishSettingsLabels() {
        XCTAssertEqual(
            ThemeTokenKey.allCases.map(\.title),
            [
                "arka plan", "hücre", "ikincil hücre", "vurgu", "entry metni",
                "link", "başlık", "tarih", "ayırıcı", "üst bar",
                "sekme", "entry sayısı", "spoiler",
            ]
        )
        XCTAssertTrue(ThemeTokenKey.allCases.allSatisfy { !$0.hint.isEmpty })
    }

    func testTokenSubscriptReadsAndWritesEveryToken() {
        for key in ThemeTokenKey.allCases {
            var palette = AppTheme.dark.palette
            let replacement = ThemeColorToken(hex: 0x123456)
            palette[key] = replacement

            XCTAssertEqual(palette[key], replacement, key.rawValue)
            let changed = ThemeTokenKey.allCases.filter { palette[$0] != AppTheme.dark.palette[$0] }
            XCTAssertEqual(changed, [key], "\(key.rawValue) should not touch other tokens")
        }
    }

    func testBuiltInChromeTokensMatchWhatTheAppAlreadyDraws() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(theme.palette.navBar, theme.palette.background, "\(theme.name) nav bar")
            XCTAssertEqual(theme.palette.tabBarTint, theme.palette.accent, "\(theme.name) tab tint")
        }
    }

    private func paletteObject(_ palette: ThemePalette) throws -> [String: Any] {
        let data = try JSONEncoder().encode(palette)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
