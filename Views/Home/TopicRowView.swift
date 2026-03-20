import SwiftUI

struct TopicRowView: View {
    let topic: Topic
    let isEven: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        HStack {
            Text(topic.title)
                .font(.system(size: CGFloat(preferences.selectedFontSize)))
                .foregroundColor(themeManager.current.labelColor)
                .lineLimit(2)

            Spacer()

            if !topic.entryCount.isEmpty {
                Text(topic.entryCount)
                    .font(.system(size: CGFloat(preferences.selectedFontSize - 4)))
                    .foregroundColor(themeManager.current.entryCountColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(themeManager.current.entryCountColor.opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 1)
    }
}
