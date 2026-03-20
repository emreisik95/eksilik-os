import Foundation
import WebKit

enum CookiePersistence {
    private static let key = "persistedCookies_v2"

    /// Save all eksisozluk cookies to UserDefaults using simple codable format
    static func save() {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://eksisozluk.com")!),
              !cookies.isEmpty else { return }

        let dicts: [[String: String]] = cookies.compactMap { cookie in
            var dict: [String: String] = [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
            ]
            if let expires = cookie.expiresDate {
                dict["expires"] = ISO8601DateFormatter().string(from: expires)
            }
            if cookie.isSecure { dict["secure"] = "1" }
            if cookie.isHTTPOnly { dict["httpOnly"] = "1" }
            return dict
        }

        if let data = try? JSONEncoder().encode(dicts) {
            UserDefaults.standard.set(data, forKey: key)
            print("🍪 Saved \(dicts.count) cookies")
        }
    }

    /// Restore cookies from UserDefaults to HTTPCookieStorage
    static func restore() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let dicts = try? JSONDecoder().decode([[String: String]].self, from: data) else { return }

        var count = 0
        for dict in dicts {
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: dict["name"] ?? "",
                .value: dict["value"] ?? "",
                .domain: dict["domain"] ?? ".eksisozluk.com",
                .path: dict["path"] ?? "/",
            ]
            if let expiresStr = dict["expires"],
               let date = ISO8601DateFormatter().date(from: expiresStr) {
                props[.expires] = date
            }
            if dict["secure"] == "1" { props[.secure] = "TRUE" }

            if let cookie = HTTPCookie(properties: props) {
                HTTPCookieStorage.shared.setCookie(cookie)
                count += 1
            }
        }
        print("🍪 Restored \(count) cookies")
    }

    /// Check if we have persisted auth cookies
    static var hasAuthCookies: Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://eksisozluk.com")!) else { return false }
        // eksisozluk uses these cookies for auth
        return cookies.contains(where: { $0.name == ".AspNetCore.Cookies" || $0.name == "a" })
    }

    /// Sync cookies from WKWebView to HTTPCookieStorage and persist
    @MainActor
    static func syncFromWebView() async {
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        save()
    }

    /// Inject cookies from HTTPCookieStorage into WKWebView and wait for completion
    @MainActor
    static func injectIntoWebView() async {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://eksisozluk.com")!) else { return }
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await store.setCookie(cookie)
        }
    }
}
