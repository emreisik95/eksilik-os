import SwiftUI
import WebKit

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LoginWebView(onLoginSuccess: { username in
            session.onLoginSuccess(username: username)
            dismiss()
        })
        .navigationTitle(L10n.Auth.login)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoginWebView: UIViewRepresentable {
    let onLoginSuccess: (_ username: String?) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://eksisozluk.com/giris")!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoginSuccess: onLoginSuccess)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onLoginSuccess: (_ username: String?) -> Void

        init(onLoginSuccess: @escaping (_ username: String?) -> Void) {
            self.onLoginSuccess = onLoginSuccess
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString,
               url == "https://eksisozluk.com/" || url == "https://eksisozluk.com" {
                syncCookiesAndFinish(webView: webView)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Check if the login page says user is already logged in
            webView.evaluateJavaScript("document.body.innerText") { result, _ in
                guard let text = result as? String else { return }
                if text.contains("giriş yapmış görünüyorsunuz") {
                    self.syncCookiesAndFinish(webView: webView)
                }
            }
        }

        private func syncCookiesAndFinish(webView: WKWebView) {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                CookiePersistence.save()
                // Extract username from page HTML
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("document.body.innerText") { result, _ in
                        var username: String?
                        if let text = result as? String,
                           let range = text.range(of: "'", options: .literal),
                           let endRange = text.range(of: "'", options: .literal, range: range.upperBound..<text.endIndex) {
                            username = String(text[range.upperBound..<endRange.lowerBound])
                        }
                        self.onLoginSuccess(username)
                    }
                }
            }
        }
    }
}
