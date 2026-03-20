import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var isLoggedIn: Bool = false
    @Published var username: String?
    @Published var hasUnreadMessages: Bool = false
    @Published var hasUnreadEvents: Bool = false
    @Published private(set) var csrfToken: String?
    @Published var isPaidMember: Bool = false

    private init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        username = UserDefaults.standard.string(forKey: "username")
        isPaidMember = UserDefaults.standard.bool(forKey: "isPaidMember")
    }

    func updateFromHTML(_ html: String) {
        let state = AuthParser.parseAuthState(html: html)

        if isLoggedIn && !state.isLoggedIn {
            logout()
            return
        }

        isLoggedIn = state.isLoggedIn
        username = state.username
        hasUnreadMessages = state.hasUnreadMessages
        hasUnreadEvents = state.hasUnreadEvents
        csrfToken = state.csrfToken

        // Detect paid membership: free users see subscription prompts
        if state.isLoggedIn {
            isPaidMember = !html.contains("open-subscription-popup") && !html.contains("reklamsız üyeliğe")
        } else {
            isPaidMember = false
        }

        UserDefaults.standard.set(state.isLoggedIn, forKey: "isLoggedIn")
        UserDefaults.standard.set(isPaidMember, forKey: "isPaidMember")
        if let name = state.username {
            UserDefaults.standard.set(name, forKey: "username")
        }
    }

    func onLoginSuccess(username: String? = nil) {
        isLoggedIn = true
        if let name = username, !name.isEmpty {
            self.username = name
            UserDefaults.standard.set(name, forKey: "username")
        }
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }

    func logout() {
        Task {
            _ = try? await HTTPClient.shared.fetchHTML(for: .logout)
        }
        isLoggedIn = false
        username = nil
        hasUnreadMessages = false
        hasUnreadEvents = false
        csrfToken = nil
        isPaidMember = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isPaidMember")
        UserDefaults.standard.removeObject(forKey: "username")
    }
}
