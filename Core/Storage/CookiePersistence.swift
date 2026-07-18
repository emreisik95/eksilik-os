import Foundation
import WebKit

enum CookiePersistence {
    private static let key = "persistedCookies_v2"

    /// Save all eksisozluk cookies to UserDefaults using simple codable format
    static func save() {
        guard let siteURL = URL(string: "https://eksisozluk.com"),
              let cookies = HTTPCookieStorage.shared.cookies(for: siteURL),
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
            KeychainHelper.save(key: key, value: data.base64EncodedString())
            UserDefaults.standard.removeObject(forKey: key)
            print("🍪 Saved \(dicts.count) cookies")
        }
    }

    /// Restore cookies from Keychain to HTTPCookieStorage, migrating legacy defaults once.
    static func restore() {
        guard let data = persistedData(),
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

    static func clear() {
        KeychainHelper.delete(key: key)
        UserDefaults.standard.removeObject(forKey: key)
        (HTTPCookieStorage.shared.cookies ?? [])
            .filter(isEksiCookie)
            .forEach(HTTPCookieStorage.shared.deleteCookie)
    }

    @MainActor
    static func clearWebViewCookies() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await store.allCookies()
        for cookie in cookies where isEksiCookie(cookie) {
            await store.delete(cookie)
        }
    }

    /// Check if we have persisted auth cookies
    static var hasAuthCookies: Bool {
        guard let siteURL = URL(string: "https://eksisozluk.com"),
              let cookies = HTTPCookieStorage.shared.cookies(for: siteURL) else { return false }
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
        guard let siteURL = URL(string: "https://eksisozluk.com"),
              let cookies = HTTPCookieStorage.shared.cookies(for: siteURL) else { return }
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await store.setCookie(cookie)
        }
    }

    private static func persistedData() -> Data? {
        if let encoded = KeychainHelper.get(key: key),
           let data = Data(base64Encoded: encoded) {
            return data
        }

        guard let legacyData = UserDefaults.standard.data(forKey: key) else { return nil }
        KeychainHelper.save(key: key, value: legacyData.base64EncodedString())
        UserDefaults.standard.removeObject(forKey: key)
        return legacyData
    }

    private static func isEksiCookie(_ cookie: HTTPCookie) -> Bool {
        cookie.domain.lowercased().hasSuffix("eksisozluk.com")
    }
}
