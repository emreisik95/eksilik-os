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
        webView.customUserAgent = EksiRouter.defaultHeaders["User-Agent"]

        Task { @MainActor in
            CookiePersistence.restore()
            await CookiePersistence.injectIntoWebView()
            if let url = URL(string: EksiRouter.baseURL + EksiEndpoint.login.path) {
                webView.load(URLRequest(url: url))
            }
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoginSuccess: onLoginSuccess)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onLoginSuccess: (_ username: String?) -> Void
        private var didFinishLogin = false

        init(onLoginSuccess: @escaping (_ username: String?) -> Void) {
            self.onLoginSuccess = onLoginSuccess
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let currentURL = webView.url
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
                guard let html = result as? String,
                      let completion = LoginFlowPolicy.completion(for: currentURL, html: html) else {
                    return
                }

                switch completion {
                case .authenticated(let username):
                    self.syncCookiesAndFinish(webView: webView, username: username)
                case .successfulReturn:
                    self.syncCookiesAndFinish(webView: webView, username: nil)
                }
            }
        }

        private func syncCookiesAndFinish(webView: WKWebView, username: String?) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                guard LoginFlowPolicy.hasAuthCookie(in: cookies) else { return }

                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                CookiePersistence.save()

                DispatchQueue.main.async {
                    guard !self.didFinishLogin else { return }
                    self.didFinishLogin = true
                    self.onLoginSuccess(username)
                }
            }
        }
    }
}
