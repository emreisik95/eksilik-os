import SwiftUI

final class UserPreferences: ObservableObject {
    @AppStorage("selectedFont") var selectedFont: String = "Helvetica"
    @AppStorage("selectedFontSize") var selectedFontSize: Int = 15
    @AppStorage("openLinksInSafari") var openLinksInSafari: Bool = true
    @AppStorage("hideEntriesEnabled") var hideEntriesEnabled: Bool = false
}
