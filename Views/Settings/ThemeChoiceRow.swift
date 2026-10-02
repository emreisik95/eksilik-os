import SwiftUI

/// A theme in the picker: a swatch of its main colors, its name and a selection mark.
struct ThemeChoiceRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let palette: ThemePalette
    let name: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        let metrics = SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
        let scale = CGFloat(metrics.scale)

        HStack(spacing: 14 * scale) {
            ThemeSwatch(palette: palette)
                .frame(width: 58 * scale, height: 42 * scale)

            VStack(alignment: .leading, spacing: 3 * scale) {
                Text(name)
                    .settingsFont(baseSize: 16, weight: .semibold)
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(1)
                Text(subtitle)
                    .settingsFont(baseSize: 12)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(2)
            }

            Spacer(minLength: 8 * scale)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.current.accentColor)
            }
        }
        .padding(.horizontal, CGFloat(metrics.horizontalPadding))
        .padding(.vertical, 10 * scale)
        .frame(minHeight: CGFloat(metrics.rowMinimumHeight))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(subtitle)")
        .accessibilityValue(isSelected ? "seçili" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Background, cell and accent side by side, the three colors that define a theme at a glance.
struct ThemeSwatch: View {
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(palette.backgroundColor)
            Rectangle().fill(palette.cellPrimaryColor)
            Rectangle().fill(palette.accentColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.separatorColor.opacity(0.75), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
