import XCTest
@testable import EksilikApp

final class AppIconPresentationPolicyTests: XCTestCase {
    func testOldschoolIsThePrimaryIconAndGeneratedAlternativesRemainUntranslated() {
        let choices = AppIconPresentationPolicy.choices

        XCTAssertEqual(choices.first?.title, "oldschool")
        XCTAssertNil(choices.first?.iconName)
        XCTAssertEqual(
            choices.map(\.title),
            ["oldschool", "light", "ornament", "noir", "aurora", "depth", "forest"]
        )
    }

    func testCurrentTitleResolvesEveryAlternateIconName() {
        for choice in AppIconPresentationPolicy.choices {
            XCTAssertEqual(
                AppIconPresentationPolicy.title(for: choice.iconName),
                choice.title
            )
        }
    }
}
