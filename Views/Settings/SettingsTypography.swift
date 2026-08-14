import SwiftUI

private struct SettingsFontModifier: ViewModifier {
    @EnvironmentObject private var preferences: UserPreferences

    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        let delta = CGFloat(preferences.selectedFontSize - 15)
        content.font(.system(
            size: max(9, baseSize + delta),
            weight: weight,
            design: design
        ))
    }
}

extension View {
    func settingsFont(
        baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(SettingsFontModifier(baseSize: baseSize, weight: weight, design: design))
    }
}
