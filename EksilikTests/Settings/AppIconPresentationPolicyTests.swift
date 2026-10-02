import UIKit
import XCTest
@testable import EksilikApp

final class AppIconPresentationPolicyTests: XCTestCase {
    func testOldschoolIsThePrimaryIconFollowedByEveryDistinctAlternate() {
        let choices = AppIconPresentationPolicy.choices

        XCTAssertEqual(choices.first?.title, "oldschool")
        XCTAssertNil(choices.first?.iconName)
        XCTAssertEqual(choices.first?.imageName, "AppIcon")
        XCTAssertEqual(
            choices.map(\.title),
            [
                "oldschool", "kağıt", "sözlük", "noir", "terminal", "neon", "aurora", "boğaz",
                "orman", "limon", "kahve", "altın", "kil", "8-bit", "ornament",
            ]
        )
    }

    func testAlternatesAreNumerousUniqueAndPreviewTheirRegisteredIcon() {
        let alternates = AppIconPresentationPolicy.alternates
        let titles = AppIconPresentationPolicy.choices.map(\.title)
        let iconNames = alternates.compactMap(\.iconName)

        XCTAssertGreaterThanOrEqual(alternates.count, 12)
        XCTAssertEqual(alternates.count, AppIconPresentationPolicy.choices.count - 1)
        XCTAssertEqual(Set(titles).count, titles.count, "picker titles must be unique")
        XCTAssertEqual(Set(iconNames).count, iconNames.count, "alternate icon names must be unique")
        for choice in alternates {
            XCTAssertNotNil(choice.iconName)
            XCTAssertEqual(choice.imageName, "\(choice.iconName ?? "")@2x")
            XCTAssertEqual(choice.title, choice.title.lowercased(), "\(choice.title) should stay lowercase")
        }
    }

    func testCurrentTitleResolvesEveryAlternateIconName() {
        for choice in AppIconPresentationPolicy.choices {
            XCTAssertEqual(
                AppIconPresentationPolicy.title(for: choice.iconName),
                choice.title
            )
        }
        XCTAssertEqual(AppIconPresentationPolicy.title(for: "AlternateMissing"), "oldschool")
    }

    func testEveryAlternateShipsItsArtworkInTheAppBundle() {
        for choice in AppIconPresentationPolicy.alternates {
            let iconName = choice.iconName ?? ""
            for suffix in ["@2x", "@3x"] {
                XCTAssertNotNil(
                    Bundle.main.url(forResource: "\(iconName)\(suffix)", withExtension: "png"),
                    "\(iconName)\(suffix).png is missing from the app bundle"
                )
            }
            XCTAssertNotNil(UIImage(named: choice.imageName), "\(choice.imageName) preview should load")
        }
    }

    func testEveryAlternateIsRegisteredForIPhoneAndIPad() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "Info", withExtension: "plist"))
        let data = try Data(contentsOf: url)
        let raw = try PropertyListSerialization.propertyList(from: data, format: nil)
        let plist = try XCTUnwrap(raw as? [String: Any])

        for key in ["CFBundleIcons", "CFBundleIcons~ipad"] {
            let icons = try XCTUnwrap(plist[key] as? [String: Any], "\(key) is missing")
            let registered = try XCTUnwrap(
                icons["CFBundleAlternateIcons"] as? [String: [String: Any]],
                "\(key) has no alternate icons"
            )
            for choice in AppIconPresentationPolicy.alternates {
                let iconName = choice.iconName ?? ""
                XCTAssertEqual(
                    registered[iconName]?["CFBundleIconFiles"] as? [String],
                    [iconName],
                    "\(iconName) is not registered under \(key)"
                )
            }
        }
    }
}
