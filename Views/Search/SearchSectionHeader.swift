import SwiftUI

struct SearchSectionHeader: View {
    let title: String
    let count: Int

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.current.labelColor)
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.accentColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(themeManager.current.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}
