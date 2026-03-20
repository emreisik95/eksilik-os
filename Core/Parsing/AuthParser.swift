import Foundation
import Kanna

struct AuthParser {
    struct AuthState {
        let isLoggedIn: Bool
        let username: String?
        let hasUnreadMessages: Bool
        let hasUnreadEvents: Bool
        let csrfToken: String?
    }

    static func parseAuthState(html: String) -> AuthState {
        guard let doc = HTMLParser.parse(html) else {
            return AuthState(isLoggedIn: false, username: nil, hasUnreadMessages: false, hasUnreadEvents: false, csrfToken: nil)
        }

        // Check login via buddy link presence
        var isLoggedIn = false
        for el in doc.css("li[class^=buddy mobile-only] a") {
            if el["href"] != nil {
                isLoggedIn = true
                break
            }
        }

        // If login link is visible, user is NOT logged in
        for el in doc.css("a[id^=top-login-link]") {
            if let text = el.text, !text.isEmpty {
                isLoggedIn = false
                break
            }
        }

        // Get username
        var username: String?
        for el in doc.css("li[class^=not-mobile] a") {
            username = el["title"]
            break
        }

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
            csrfToken: csrfToken
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
