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

            // Relative HTML links are rendered as applewebdata URLs. Pass the
            // untouched URL to the shared policy so query delimiters are not lost.
            if URL.scheme?.lowercased() == "applewebdata" {
                onInternalLink?(link)
                return false
            }

            // eksisozluk.com links — treat as internal
            if let host = URL.host?.lowercased(),
               host == "eksisozluk.com" || host == "www.eksisozluk.com" {
                onInternalLink?(link)
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
