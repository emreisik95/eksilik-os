import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedThemeRaw: Int = 0

    var current: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .dark
    }

    func setTheme(_ theme: AppTheme) {
        selectedThemeRaw = theme.rawValue
        objectWillChange.send()
    }
}
