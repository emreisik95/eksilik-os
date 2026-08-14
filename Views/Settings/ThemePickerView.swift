import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        List(AppTheme.allCases) { theme in
            Button {
                themeManager.setTheme(theme)
            } label: {
                HStack(spacing: 14) {
                    palettePreview(theme)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.body.weight(.semibold))
                            .foregroundColor(themeManager.current.labelColor)
                        Text(theme.summary)
                            .font(.caption)
                            .foregroundColor(themeManager.current.dateColor)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    if theme == themeManager.current {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(themeManager.current.cellPrimaryColor)
            .accessibilityValue(theme == themeManager.current ? "seçili" : "")
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.theme)
        .background(themeManager.current.backgroundColor)
        .scrollContentBackground(.hidden)
    }

    private func palettePreview(_ theme: AppTheme) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(theme.backgroundColor)
            Rectangle().fill(theme.cellPrimaryColor)
            Rectangle().fill(theme.accentColor)
        }
        .frame(width: 58, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.separatorColor.opacity(0.75), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}
