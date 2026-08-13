import XCTest
@testable import EksilikApp

final class FormURLEncoderTests: XCTestCase {
    func testEncodesReservedCharactersWithoutSplittingFormFields() {
        XCTAssertEqual(
            FormURLEncoder.encode([
                "Message": "a&b = c+d",
                "To": "sherlockun besinci sezonu",
            ]),
            "Message=a%26b%20%3D%20c%2Bd&To=sherlockun%20besinci%20sezonu"
        )
    }

    func testUsesUTF8PercentEncodingAndStableKeyOrder() {
        XCTAssertEqual(
            FormURLEncoder.encode(["z": "şükela", "a": "ı"]),
            "a=%C4%B1&z=%C5%9F%C3%BCkela"
        )
    }
}
