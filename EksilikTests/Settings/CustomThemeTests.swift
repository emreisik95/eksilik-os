import XCTest
@testable import EksilikApp

final class CustomThemeTests: XCTestCase {
    private var suiteName = ""
    private var defaults = UserDefaults.standard

    override func setUpWithError() throws {
        suiteName = "CustomThemeTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Migration from the legacy Int selection

    func testFreshInstallStartsOnDark() {
        let manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.selection, .builtIn(.dark))
        XCTAssertEqual(manager.current, AppTheme.dark.palette)
        XCTAssertEqual(manager.currentName, "dark")
        XCTAssertTrue(manager.customThemes.isEmpty)
    }

    func testLegacyIntegerSelectionKeepsTheSameBuiltInTheme() {
        defaults.set(7, forKey: "selectedTheme")

        let manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.selection, .builtIn(.burgundy))
        XCTAssertEqual(manager.current, AppTheme.burgundy.palette)
        XCTAssertEqual(ThemeManager.activePalette(defaults: defaults), AppTheme.burgundy.palette)
    }

    func testUnknownLegacyIntegerFallsBackToDark() {
        defaults.set(99, forKey: "selectedTheme")

        XCTAssertEqual(ThemeManager(defaults: defaults).selection, .builtIn(.dark))
    }

    func testSelectingBuiltInStillWritesTheLegacyIntegerKey() {
        let manager = ThemeManager(defaults: defaults)

        manager.setTheme(.solarLight)

        XCTAssertEqual(defaults.integer(forKey: "selectedTheme"), AppTheme.solarLight.rawValue)
        XCTAssertNil(defaults.string(forKey: "selectedCustomTheme"))
        XCTAssertEqual(ThemeManager(defaults: defaults).selection, .builtIn(.solarLight))
    }

    func testStaleCustomSelectionFallsBackToTheStoredBuiltIn() {
        defaults.set(AppTheme.ice.rawValue, forKey: "selectedTheme")
        defaults.set(UUID().uuidString, forKey: "selectedCustomTheme")

        let manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.selection, .builtIn(.ice))
        XCTAssertEqual(manager.current, AppTheme.ice.palette)
    }

    // MARK: - CRUD and persistence

    func testSavedCustomThemePersistsAndCanBeSelected() {
        let manager = ThemeManager(defaults: defaults)
        var theme = manager.makeDraft(from: .light)
        theme.name = "gece okuması"
        theme.palette.background = ThemeColorToken(hex: 0x101820)

        manager.saveCustomTheme(theme)
        manager.select(.custom(theme.id))

        let restored = ThemeManager(defaults: defaults)
        XCTAssertEqual(restored.customThemes, [theme])
        XCTAssertEqual(restored.selection, .custom(theme.id))
        XCTAssertEqual(restored.current, theme.palette)
        XCTAssertEqual(restored.currentName, "gece okuması")
        XCTAssertEqual(ThemeManager.activePalette(defaults: defaults), theme.palette)
    }

    func testSelectingCustomThemeKeepsItsBaseInTheLegacyKeyForDowngrades() {
        let manager = ThemeManager(defaults: defaults)
        let theme = manager.makeDraft(from: .notebook)
        manager.saveCustomTheme(theme)

        manager.select(.custom(theme.id))

        XCTAssertEqual(defaults.integer(forKey: "selectedTheme"), AppTheme.notebook.rawValue)
    }

    func testSavingAnExistingThemeUpdatesItInPlace() {
        let manager = ThemeManager(defaults: defaults)
        let first = manager.makeDraft(from: .dark)
        let second = manager.makeDraft(from: .light)
        manager.saveCustomTheme(first)
        manager.saveCustomTheme(second)
        manager.select(.custom(first.id))

        var edited = first
        edited.palette.link = ThemeColorToken(hex: 0xFF8800)
        manager.saveCustomTheme(edited)

        XCTAssertEqual(manager.customThemes.map(\.id), [first.id, second.id])
        XCTAssertEqual(manager.customThemes.first?.palette.link, ThemeColorToken(hex: 0xFF8800))
        XCTAssertEqual(manager.current.link, ThemeColorToken(hex: 0xFF8800))
    }

    func testDuplicateCreatesAnIndependentCopy() throws {
        let manager = ThemeManager(defaults: defaults)
        var original = manager.makeDraft(from: .coffee)
        original.name = "kahve"
        manager.saveCustomTheme(original)

        let copy = try XCTUnwrap(manager.duplicateCustomTheme(id: original.id))

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.name, "kahve kopyası")
        XCTAssertEqual(copy.palette, original.palette)
        XCTAssertEqual(copy.baseTheme, .coffee)
        XCTAssertEqual(manager.customThemes.map(\.id), [original.id, copy.id])
    }

    func testRenameTrimsAndRejectsBlankNames() {
        let manager = ThemeManager(defaults: defaults)
        let theme = manager.makeDraft(from: .dark)
        manager.saveCustomTheme(theme)

        manager.renameCustomTheme(id: theme.id, to: "  mürekkep  ")
        XCTAssertEqual(manager.customThemes.first?.name, "mürekkep")

        manager.renameCustomTheme(id: theme.id, to: "   ")
        XCTAssertEqual(manager.customThemes.first?.name, "mürekkep")
        XCTAssertEqual(ThemeManager(defaults: defaults).customThemes.first?.name, "mürekkep")
    }

    func testDeletingTheSelectedThemeFallsBackToItsBase() {
        let manager = ThemeManager(defaults: defaults)
        let theme = manager.makeDraft(from: .lilac)
        manager.saveCustomTheme(theme)
        manager.select(.custom(theme.id))

        manager.deleteCustomTheme(id: theme.id)

        XCTAssertTrue(manager.customThemes.isEmpty)
        XCTAssertEqual(manager.selection, .builtIn(.lilac))
        XCTAssertEqual(manager.current, AppTheme.lilac.palette)
        XCTAssertEqual(ThemeManager(defaults: defaults).selection, .builtIn(.lilac))
    }

    func testDeletingAnotherThemeKeepsTheSelection() {
        let manager = ThemeManager(defaults: defaults)
        let kept = manager.makeDraft(from: .dark)
        let removed = manager.makeDraft(from: .light)
        manager.saveCustomTheme(kept)
        manager.saveCustomTheme(removed)
        manager.select(.custom(kept.id))

        manager.deleteCustomTheme(id: removed.id)

        XCTAssertEqual(manager.selection, .custom(kept.id))
        XCTAssertEqual(manager.customThemes, [kept])
    }

    func testCorruptStoredThemesAreSkippedInsteadOfWipingTheRest() throws {
        let manager = ThemeManager(defaults: defaults)
        let theme = manager.makeDraft(from: .ice)
        manager.saveCustomTheme(theme)

        let stored = try XCTUnwrap(defaults.data(forKey: "customThemes"))
        var array = try XCTUnwrap(JSONSerialization.jsonObject(with: stored) as? [Any])
        array.append(["id": "not-a-uuid", "name": 42])
        defaults.set(try JSONSerialization.data(withJSONObject: array), forKey: "customThemes")

        XCTAssertEqual(ThemeManager(defaults: defaults).customThemes, [theme])
    }

    func testDraftStartsFromTheChosenBuiltIn() {
        let manager = ThemeManager(defaults: defaults)

        let draft = manager.makeDraft(from: .terminal)

        XCTAssertEqual(draft.baseTheme, .terminal)
        XCTAssertEqual(draft.palette, AppTheme.terminal.palette)
        XCTAssertFalse(draft.name.isEmpty)
        XCTAssertTrue(manager.customThemes.isEmpty, "drafts are not saved until the user saves")
    }

    func testCustomThemeNamesAreSanitized() {
        XCTAssertEqual(CustomTheme.sanitizedName("  gece  "), "gece")
        XCTAssertEqual(CustomTheme.sanitizedName(""), "adsız tema")
        XCTAssertEqual(CustomTheme.sanitizedName(String(repeating: "a", count: 80)).count, 32)
    }

    func testPreviewManagerNeverWritesToDefaults() {
        let standard = UserDefaults.standard
        let storedSelection = standard.object(forKey: "selectedTheme") as? Int
        let storedThemes = standard.data(forKey: "customThemes")

        let preview = ThemeManager(previewPalette: AppTheme.oled.palette)
        XCTAssertEqual(preview.current, AppTheme.oled.palette)

        preview.applyPreview(AppTheme.ice.palette)
        XCTAssertEqual(preview.current, AppTheme.ice.palette)

        preview.setTheme(.light)
        preview.saveCustomTheme(preview.makeDraft(from: .dark))
        XCTAssertEqual(preview.current, AppTheme.light.palette)
        XCTAssertEqual(preview.customThemes.count, 1)
        XCTAssertEqual(standard.object(forKey: "selectedTheme") as? Int, storedSelection)
        XCTAssertEqual(standard.data(forKey: "customThemes"), storedThemes)
    }
}
