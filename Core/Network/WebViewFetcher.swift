import Foundation
import WebKit

@MainActor
final class WebViewFetcher: NSObject {
    static let shared = WebViewFetcher()

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<Bool, Never>?

    private override init() {
        super.init()
    }

    /// Loads eksisozluk.com in a hidden WKWebView to pass Cloudflare challenge.
    /// Returns true if session cookies were successfully obtained.
    func bootstrap() async -> Bool {
        // Restore persisted cookies before bootstrap
        CookiePersistence.restore()
        // Inject into WKWebView and wait for completion
        await CookiePersistence.injectIntoWebView()
        print("🌐 Auth cookies present: \(CookiePersistence.hasAuthCookies)")

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            let config = WKWebViewConfiguration()
            config.websiteDataStore = .default()
            let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), configuration: config)
            wv.navigationDelegate = self
            wv.customUserAgent = EksiRouter.defaultHeaders["User-Agent"]
            self.webView = wv

            print("🌐 Bootstrap: loading eksisozluk.com...")
            wv.load(URLRequest(url: URL(string: "https://eksisozluk.com/")!))

            // Timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
                self?.finish(success: false)
            }
        }
    }

    private func finish(success: Bool) {
        guard let continuation else { return }
        self.continuation = nil
        webView?.stopLoading()
        webView = nil
        print("🌐 Bootstrap: finish(success=\(success))")
        continuation.resume(returning: success)
    }
}

extension WebViewFetcher: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            print("🌐 didFinish url=\(webView.url?.absoluteString ?? "")")

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            let title = (try? await webView.evaluateJavaScript("document.title") as? String) ?? ""
            print("🌐 title='\(title)'")

            if title.lowercased().contains("moment") || title.lowercased().contains("checking") || title.isEmpty {
                return
            }

            await CookiePersistence.syncFromWebView()
            print("🌐 Cookies synced and persisted")

            self.finish(success: true)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            print("🌐 didFailProvisional: \(error.localizedDescription)")
            self.finish(success: false)
        }
    }
}
