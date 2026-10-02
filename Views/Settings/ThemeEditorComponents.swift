import SwiftUI

/// A titled row inside a theme editor card, with the control on the trailing side.
struct ThemeEditorFieldRow<Accessory: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let title: String
    let systemImage: String?
    let accessory: Accessory

    init(title: String, systemImage: String? = nil, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.systemImage = systemImage
        self.accessory = accessory()
    }

    var body: some View {
        let metrics = SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
        let scale = CGFloat(metrics.scale)

        HStack(spacing: 12 * scale) {
            if let systemImage {
                SettingsRowIcon(systemImage: systemImage)
            }
            Text(title)
                .settingsFont(baseSize: 16, weight: systemImage == nil ? .regular : .medium)
                .foregroundColor(systemImage == nil
                    ? themeManager.current.labelColor
                    : themeManager.current.accentColor)
                .lineLimit(2)
                .layoutPriority(1)
            Spacer(minLength: 8 * scale)
            accessory
        }
        .padding(.horizontal, CGFloat(metrics.horizontalPadding))
        .padding(.vertical, 8 * scale)
        .frame(minHeight: CGFloat(metrics.rowMinimumHeight) * 0.85)
    }
}

/// One WCAG pair: an "Aa" sample in the pair's colors, the ratio and whether it passes.
struct ThemeContrastRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let check: ThemeContrastCheck
    let palette: ThemePalette
    let onSelect: () -> Void

    private var statusColor: Color {
        check.isBelowMinimum ? Color(uiColor: .systemOrange) : themeManager.current.dateColor
    }

    var body: some View {
        let metrics = SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
        let scale = CGFloat(metrics.scale)

        Button(action: onSelect) {
            HStack(spacing: 12 * scale) {
                Text("Aa")
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .foregroundColor(palette[check.foreground].color)
                    .frame(width: 40 * scale, height: 32 * scale)
                    .background(
                        palette[check.background].color,
                        in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                            .stroke(themeManager.current.separatorColor.opacity(0.4), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 2 * scale) {
                    Text(check.title)
                        .settingsFont(baseSize: 15)
                        .foregroundColor(themeManager.current.labelColor)
                    Text(check.isBelowMinimum ? "okunması zor olabilir" : "yeterli")
                        .settingsFont(baseSize: 12)
                        .foregroundColor(statusColor)
                }

                Spacer(minLength: 8 * scale)

                Label(check.formattedRatio, systemImage: check.isBelowMinimum
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.circle")
                    .settingsFont(baseSize: 14, weight: .semibold, design: .monospaced)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, CGFloat(metrics.horizontalPadding))
            .padding(.vertical, 10 * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(check.title) kontrastı \(check.formattedRatio)")
        .accessibilityValue(check.isBelowMinimum ? "düşük" : "yeterli")
        .accessibilityHint("iki rengi aşağıda işaretler")
    }
}
