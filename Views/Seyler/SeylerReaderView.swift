import SwiftUI
import WebKit

struct SeylerReaderView: View {
    let url: URL

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isLoading = true

    var body: some View {
        ZStack {
            SeylerWebView(url: url, isLoading: $isLoading)

            if isLoading {
                ProgressView()
                    .tint(themeManager.current.accentColor)
                    .padding(18)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .background(themeManager.current.backgroundColor)
    }
}

private struct SeylerWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = [
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)",
            "AppleWebKit/605.1.15 Mobile/15E148",
        ].joined(separator: " ")
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding private var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            isLoading = false
        }
    }
}
