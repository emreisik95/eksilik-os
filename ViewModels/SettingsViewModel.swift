import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var fontOptions = ["Helvetica", "Helvetica-Light", "Georgia", "Menlo", "Avenir"]

    let session: SessionManager
    let preferences: UserPreferences

    init(session: SessionManager, preferences: UserPreferences) {
        self.session = session
        self.preferences = preferences
    }

    func logout() {
        session.logout()
    }
}
