import SwiftUI
import UIKit
import SafariServices

struct EntryTextView: UIViewRepresentable {
    let attributedText: NSAttributedString?
    var onInternalLink: ((String) -> Void)?
    var onImageLink: ((String) -> Void)?
    @EnvironmentObject var themeManager: ThemeManager

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.delegate = context.coordinator
        textView.dataDetectorTypes = []

        if let attr = attributedText {
            textView.attributedText = attr
        }
        textView.tintColor = UIColor(themeManager.current.linkColor)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.onInternalLink = onInternalLink
        context.coordinator.onImageLink = onImageLink
        // Only update if content changed (avoid re-parsing)
        if let attr = attributedText, textView.attributedText != attr {
            textView.attributedText = attr
            textView.invalidateIntrinsicContentSize()
        }
        textView.tintColor = UIColor(themeManager.current.linkColor)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UITextViewDelegate {
        var onInternalLink: ((String) -> Void)?
        var onImageLink: ((String) -> Void)?

        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            let link = URL.absoluteString

            if ImageURLNormalizer.isImageURL(link),
               let normalized = ImageURLNormalizer.normalize(link)?.absoluteString {
                onImageLink?(normalized)
                return false
            }

            // Internal eksisozluk links (relative URLs rendered as applewebdata://)
            if link.contains("applewebdata://") {
                // Extract the path: applewebdata://UUID/baslik--id or applewebdata://UUID/entry/123
                let components = link.components(separatedBy: "/")
                // Skip scheme + empty + host, take the rest
                let pathParts = components.dropFirst(3) // drop "applewebdata:", "", "UUID"
                let path = pathParts.joined(separator: "/")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    .removingPercentEncoding ?? ""

                if !path.isEmpty {
                    print("🔗 Internal link: \(path)")
                    onInternalLink?(path)
                }
                return false
            }

            // eksisozluk.com links — treat as internal
            if link.contains("eksisozluk.com/") {
                let path = link.components(separatedBy: "eksisozluk.com/").last ?? ""
                if !path.isEmpty {
                    print("🔗 Eksi link: \(path)")
                    onInternalLink?(path)
                }
                return false
            }

            // Social/media links — prefer the installed app via universal links.
            if link.hasPrefix("http://") || link.hasPrefix("https://") {
                if ExternalLinkPolicy.prefersNativeApp(URL) {
                    UIApplication.shared.open(
                        URL,
                        options: [.universalLinksOnly: true]
                    ) { [weak self] opened in
                        guard !opened else { return }
                        DispatchQueue.main.async {
                            self?.presentInAppBrowser(URL)
                        }
                    }
                } else {
                    presentInAppBrowser(URL)
                }
                return false
            }

            return true
        }

        private func presentInAppBrowser(_ url: URL) {
            let safari = SFSafariViewController(url: url)
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
                return
            }
            root.present(safari, animated: true)
        }
    }
}

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
