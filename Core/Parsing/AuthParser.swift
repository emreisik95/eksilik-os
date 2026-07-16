import Foundation
import Kanna

struct AuthParser {
    struct AuthState {
        let isLoggedIn: Bool
        let username: String?
        let hasUnreadMessages: Bool
        let hasUnreadEvents: Bool
        let csrfToken: String?
        let isIndeterminate: Bool
    }

    static func parseAuthState(html: String) -> AuthState {
        guard let doc = HTMLParser.parse(html) else {
            return AuthState(
                isLoggedIn: false,
                username: nil,
                hasUnreadMessages: false,
                hasUnreadEvents: false,
                csrfToken: nil,
                isIndeterminate: true
            )
        }

        // Navbar presence makes auth state determinate. Class order can vary.
        let profileLink = doc.at_css("li.buddy a[href^='/biri/']")
            ?? doc.at_css("li.mobile-only.buddy a[href^='/biri/']")
        let loginLink = doc.at_css("#top-login-link")
        let isIndeterminate = profileLink == nil && loginLink == nil
        let isLoggedIn = profileLink != nil && loginLink == nil

        // Get username
        let username = profileLink?["title"]
            ?? profileLink?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? doc.at_css("li.not-mobile a[title]")?["title"]

        // Check unread messages
        var hasUnreadMessages = false
        for el in doc.css("li[class^=messages mobile-only] a svg") {
            if let className = el.className, className.contains("green") {
                hasUnreadMessages = true
            }
        }

        // Check unread events
        var hasUnreadEvents = false
        for el in doc.css("li[class^=tracked mobile-only] a svg") {
            if let className = el.className, className.contains("green") {
                hasUnreadEvents = true
            }
        }

        // CSRF token
        var csrfToken: String?
        for el in doc.css("input[name^=__RequestVerificationToken]") {
            csrfToken = el["value"]
            break
        }

        return AuthState(
            isLoggedIn: isLoggedIn,
            username: username,
            hasUnreadMessages: hasUnreadMessages,
            hasUnreadEvents: hasUnreadEvents,
            csrfToken: csrfToken,
            isIndeterminate: isIndeterminate
        )
    }

    static func parseCSRFToken(html: String) -> String? {
        guard let doc = HTMLParser.parse(html) else { return nil }
        return doc.at_css("input[name^=__RequestVerificationToken]")?["value"]
    }

    static func parseLoginUsername(html: String) -> String? {
        let state = parseAuthState(html: html)
        if let username = state.username?.trimmingCharacters(in: .whitespacesAndNewlines),
           !username.isEmpty {
            return username
        }

        guard let doc = HTMLParser.parse(html) else { return nil }
        let selectors = [
            "nav a[href^='/biri/']",
            "header a[href^='/biri/']",
            "a[href^='/biri/'][title]",
            "a[href^='/biri/']",
        ]

        for selector in selectors {
            guard let link = doc.at_css(selector),
                  let href = link["href"],
                  href.hasPrefix("/biri/") else { continue }

            if let title = link["title"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                return title
            }

            let text = link.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let genericLabels = ["hesabım", "profil", "profilim"]
            if !text.isEmpty && !genericLabels.contains(text.lowercased()) {
                return text
            }

            let slug = href
                .dropFirst("/biri/".count)
                .split(separator: "?", maxSplits: 1)
                .first
                .map(String.init) ?? ""
            if !slug.isEmpty {
                return slug.removingPercentEncoding ?? slug
            }
        }
        return nil
    }

    static func parseEntryFormFields(html: String) -> (token: String, title: String, id: String, returnURL: String)? {
        guard let doc = HTMLParser.parse(html) else { return nil }

        guard let token = doc.at_css("input[name^=__RequestVerificationToken]")?["value"],
              let title = doc.at_css("input[name^=Title]")?["value"],
              let id = doc.at_css("input[name^=Id]")?["value"],
              let returnURL = doc.at_css("input[name^=ReturnUrl]")?["value"] else {
            return nil
        }

        return (token: token, title: title, id: id, returnURL: returnURL)
    }
}

enum LoginFlowPolicy {
    enum Completion: Equatable {
        case authenticated(username: String?)
        case successfulReturn
    }

    private static let authCookieNames: Set<String> = [".AspNetCore.Cookies", "a"]

    static func completion(for url: URL?, html: String) -> Completion? {
        let state = AuthParser.parseAuthState(html: html)
        let loginUsername = AuthParser.parseLoginUsername(html: html)
        if state.isLoggedIn {
            return .authenticated(username: loginUsername ?? state.username)
        }

        if let loginUsername {
            return .authenticated(username: loginUsername)
        }

        if html.localizedCaseInsensitiveContains("giriş yapmış görünüyorsunuz") {
            return .authenticated(username: nil)
        }

        if let url, isSuccessfulReturnURL(url) {
            return .successfulReturn
        }

        return nil
    }

    static func shouldRecoverUsername(
        for completion: Completion,
        currentURL: URL?,
        hasAuthCookie: Bool,
        hasAttemptedRecovery: Bool
    ) -> Bool {
        guard hasAuthCookie,
              !hasAttemptedRecovery,
              let currentURL,
              !isSuccessfulReturnURL(currentURL) else {
            return false
        }

        switch completion {
        case .authenticated(let username):
            guard let username else { return true }
            return username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .successfulReturn:
            return true
        }
    }

    static func isSuccessfulReturnURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(),
              host == "eksisozluk.com" || host == "www.eksisozluk.com" else {
            return false
        }
        return url.path.isEmpty || url.path == "/"
    }

    static func hasAuthCookie(in cookies: [HTTPCookie]) -> Bool {
        cookies.contains { authCookieNames.contains($0.name) && !$0.value.isEmpty }
    }
}
