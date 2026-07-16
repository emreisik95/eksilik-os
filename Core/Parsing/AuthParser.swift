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

    static func completion(for _: URL?, html _: String) -> Completion? {
        nil
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
