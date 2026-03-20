import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        List(AppTheme.allCases) { theme in
            Button {
                themeManager.setTheme(theme)
            } label: {
                HStack {
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 24, height: 24)
                    Text(theme.name)
                        .foregroundColor(themeManager.current.labelColor)
                    Spacer()
                    if theme == themeManager.current {
                        Image(systemName: "checkmark")
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
            }
            .listRowBackground(themeManager.current.cellPrimaryColor)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.theme)
        .background(themeManager.current.backgroundColor)
        .scrollContentBackground(.hidden)
    }
}
