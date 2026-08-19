import Foundation
import WebKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class WebViewFetcher: NSObject {
    static let shared = WebViewFetcher()

    private var webView: WKWebView?
    private var bootstrapContinuations: [CheckedContinuation<Bool, Never>] = []
    private var isBootstrapping = false
    private var isReady = false
    private var mainFrameStatusCode: Int?
    private var mainFrameHeaders: [String: String] = [:]
#if canImport(UIKit)
    private var hostWindow: UIWindow?
#elseif canImport(AppKit)
    private var hostWindow: NSWindow?
#endif

    private override init() {
        super.init()
    }

    /// Loads eksisozluk.com in a hidden WKWebView to pass Cloudflare challenge.
    /// Returns true if session cookies were successfully obtained.
    func bootstrap() async -> Bool {
        if isReady, webView != nil {
            return true
        }

        return await withCheckedContinuation { continuation in
            bootstrapContinuations.append(continuation)
            guard !isBootstrapping else { return }
            isBootstrapping = true

            Task { @MainActor [weak self] in
                await self?.startBootstrap()
            }
        }
    }

    func fetch(_ request: URLRequest) async throws -> BrowserFetchResponse {
        guard await bootstrap() else {
            throw NetworkError.cloudflareBlocked
        }

        var response = try await execute(request)
        if response.isCloudflareChallenge {
            invalidateBrowserSession()
            guard await bootstrap() else {
                throw NetworkError.cloudflareBlocked
            }
            response = try await execute(request)
        }
        return response
    }

    private func startBootstrap() async {
        CookiePersistence.restore()
        await CookiePersistence.injectIntoWebView()
        print("🌐 Auth cookies present: \(CookiePersistence.hasAuthCookies)")

        mainFrameStatusCode = nil
        mainFrameHeaders = [:]

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            configuration: config
        )
        webView.navigationDelegate = self
        webView.customUserAgent = EksiRouter.defaultHeaders["User-Agent"]
        self.webView = webView

        guard attachToBrowserHost(webView) else {
            finishBootstrap(success: false)
            return
        }

        guard let url = URL(string: EksiRouter.baseURL + "/") else {
            finishBootstrap(success: false)
            return
        }
        webView.load(URLRequest(url: url))

        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self, weak webView] in
            guard let self, let webView, self.webView === webView else { return }
            self.finishBootstrap(success: false)
        }
    }

    private func execute(_ request: URLRequest) async throws -> BrowserFetchResponse {
        guard let webView else {
            throw BrowserFetchTransportError.invalidRequest
        }
        let payload = try BrowserFetchRequest(request: request)
        guard let value = try await webView.callAsyncJavaScript(
            BrowserFetchRequest.javaScript,
            arguments: ["request": payload.javaScriptValue],
            in: nil,
            contentWorld: .page
        ) else {
            throw BrowserFetchTransportError.invalidResponse
        }
        return try BrowserFetchResponse.decode(value)
    }

    private func invalidateBrowserSession() {
        isReady = false
        webView?.stopLoading()
        webView = nil
        removeBrowserHost()
    }

    private func finishBootstrap(success: Bool) {
        guard isBootstrapping else { return }
        isBootstrapping = false
        isReady = success
        if !success {
            webView?.stopLoading()
            webView = nil
            removeBrowserHost()
        }
        let continuations = bootstrapContinuations
        bootstrapContinuations.removeAll()
        print("🌐 Bootstrap: finish(success=\(success))")
        continuations.forEach { $0.resume(returning: success) }
    }

    private func attachToBrowserHost(_ webView: WKWebView) -> Bool {
#if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive })
                ?? scenes.first else {
            return false
        }

        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.accessibilityElementsHidden = true
        webView.accessibilityElementsHidden = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
        ])

        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = controller
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 1)
        window.alpha = 0.01
        window.isUserInteractionEnabled = false
        window.isHidden = false
        hostWindow = window
        return true
#elseif canImport(AppKit)
        let window = NSWindow(
            contentRect: webView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.alphaValue = 0.01
        window.ignoresMouseEvents = true
        window.contentView = webView
        window.orderFrontRegardless()
        hostWindow = window
        return true
#else
        return false
#endif
    }

    private func removeBrowserHost() {
#if canImport(UIKit)
        hostWindow?.isHidden = true
        hostWindow = nil
#elseif canImport(AppKit)
        hostWindow?.orderOut(nil)
        hostWindow = nil
#endif
    }
}

extension WebViewFetcher: WKNavigationDelegate {
    nonisolated func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(.allow)
        Task { @MainActor [weak self] in
            guard let self, self.webView === webView else { return }
            if navigationResponse.isForMainFrame,
               let response = navigationResponse.response as? HTTPURLResponse {
                let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                    guard let key = pair.key as? String else { return }
                    result[key] = String(describing: pair.value)
                }
                self.mainFrameStatusCode = response.statusCode
                self.mainFrameHeaders = headers
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            guard self.webView === webView else { return }
            print("🌐 didFinish url=\(webView.url?.absoluteString ?? "")")

            let title = (try? await webView.evaluateJavaScript("document.title") as? String) ?? ""
            let html = (
                try? await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String
            ) ?? ""
            guard self.webView === webView else { return }
            print("🌐 title='\(title)'")

            guard WebBootstrapPolicy.shouldComplete(
                statusCode: self.mainFrameStatusCode,
                headers: self.mainFrameHeaders,
                title: title,
                html: html
            ) else {
                print("🌐 Waiting for challenge completion (status=\(self.mainFrameStatusCode ?? 0))")
                return
            }

            await CookiePersistence.syncFromWebView()
            print("🌐 Cookies synced and persisted")

            self.finishBootstrap(success: true)
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor in
            guard self.webView === webView else { return }
            print("🌐 didFailProvisional: \(error.localizedDescription)")
            self.finishBootstrap(success: false)
        }
    }
}
