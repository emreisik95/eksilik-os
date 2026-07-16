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
            if let url = webView.url, LoginFlowPolicy.isSuccessfulReturnURL(url) {
                syncCookiesAndFinish(webView: webView)
                return
            }

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
                guard LoginFlowPolicy.hasAuthCookie(in: cookies) else { return }

                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                CookiePersistence.save()

                DispatchQueue.main.async {
                    guard !self.didFinishLogin else { return }
                    self.didFinishLogin = true

                    let script = """
                    (() => {
                      const link = document.querySelector('li.buddy a[href^="/biri/"]');
                      return link ? link.textContent.trim() : null;
                    })()
                    """
                    webView.evaluateJavaScript(script) { result, _ in
                        self.onLoginSuccess(result as? String)
                    }
                }
            }
        }
    }
}
