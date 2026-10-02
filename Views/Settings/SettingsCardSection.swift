import SwiftUI

/// The rounded, titled card the main settings screen uses for its sections, shared by the theme
/// and font screens so they read as part of the same place.
struct SettingsCardSection<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let title: String
    let systemImage: String
    var footer: String?
    @ViewBuilder let content: Content

    private var metrics: SettingsLayoutMetrics {
        SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
    }

    private var scale: CGFloat { CGFloat(metrics.scale) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            Label(title, systemImage: systemImage)
                .settingsFont(baseSize: 15, weight: .bold)
                .foregroundColor(themeManager.current.labelColor)
                .padding(.horizontal, 4 * scale)

            VStack(spacing: 0) {
                content
            }
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: CGFloat(metrics.cornerRadius), style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CGFloat(metrics.cornerRadius), style: .continuous)
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
            }

            if let footer {
                Text(footer)
                    .settingsFont(baseSize: 12)
                    .foregroundColor(themeManager.current.dateColor)
                    .padding(.horizontal, 4 * scale)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Hairline between rows inside a `SettingsCardSection`, inset like the main settings list.
struct SettingsCardDivider: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        let metrics = SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
        Divider()
            .overlay(themeManager.current.separatorColor.opacity(0.22))
            .padding(.leading, CGFloat(metrics.horizontalPadding))
    }
}
