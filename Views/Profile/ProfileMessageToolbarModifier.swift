import SwiftUI

struct ProfileMessageToolbarModifier: ViewModifier {
    let isRoot: Bool

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager

    func body(content: Content) -> some View {
        content.toolbar {
            if isRoot && session.isLoggedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: Route.messageList) {
                        Image(systemName: session.hasUnreadMessages ? "envelope.badge.fill" : "envelope")
                            .foregroundColor(messageColor)
                    }
                    .accessibilityLabel(L10n.Message.title)
                    .accessibilityValue(session.hasUnreadMessages ? "okunmamış mesaj var" : "")
                }
            }
        }
    }

    private var messageColor: Color {
        session.hasUnreadMessages
            ? themeManager.current.accentColor
            : themeManager.current.labelColor
    }
}
