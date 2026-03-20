import SwiftUI
import UIKit

struct EntryRowView: View {
    let entry: Entry
    let isEven: Bool
    let onFavorite: () -> Void
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var nav: NavigationCoordinator
    @State private var showActions = false
    @State private var pendingRoute: Route?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Entry content with internal link handling
            EntryTextView(attributedText: entry.parsedContent, onInternalLink: { path in
                let route = resolveInternalLink(path)
                nav.push(route)
            })

            // Inline images
            if !entry.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.imageURLs, id: \.self) { urlStr in
                            if let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 160, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }

            // Author + date row
            HStack(alignment: .bottom) {
                Button {
                    nav.push(Route.profile(username: entry.author.nick))
                } label: {
                    HStack(spacing: 6) {
                        if let avatarURL = entry.author.avatarURL, let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        }
                        Text(entry.author.nick)
                            .font(.caption.weight(.medium))
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.date)
                        .font(.caption2)
                        .foregroundColor(themeManager.current.dateColor)
                    Text("#\(entry.id)")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }

            // Action bar
            HStack(spacing: 20) {
                Button(action: onFavorite) {
                    HStack(spacing: 3) {
                        Image(systemName: entry.isFavorited ? "star.fill" : "star")
                        Text("\(entry.favoriteCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(entry.isFavorited ? .yellow : .gray)
                }
                .buttonStyle(.plain)

                if session.isLoggedIn && entry.author.nick != session.username {
                    Button(action: onUpvote) {
                        Image(systemName: entry.voteState == .upvoted ? "chevron.up.circle.fill" : "chevron.up.circle")
                            .foregroundColor(entry.voteState == .upvoted ? themeManager.current.accentColor : .gray)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDownvote) {
                        Image(systemName: entry.voteState == .downvoted ? "chevron.down.circle.fill" : "chevron.down.circle")
                            .foregroundColor(entry.voteState == .downvoted ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    shareItems([entry.shareURL])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Button {
                    showActions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
        .confirmationDialog("", isPresented: $showActions) {
            // Share
            Button(L10n.Entry.shareLink) {
                shareItems([entry.shareURL])
            }
            Button(L10n.Entry.shareScreenshot) {
                shareEntryScreenshot()
            }
            Button(L10n.Entry.copyEntry) {
                UIPasteboard.general.string = entry.contentHTML.strippingHTML
            }

            // Actions requiring login
            if session.isLoggedIn {
                Button(L10n.Entry.sendMessage) {
                    pendingRoute = .composeMessage(to: entry.author.nick, subject: "#\(entry.id)")
                }
                Button(L10n.Entry.blockAuthor, role: .destructive) {
                    if let url = URL(string: "https://eksisozluk.com/entry/\(entry.id)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            Button(L10n.Entry.modlog) {
                if let url = URL(string: "https://eksisozluk.com/entry/\(entry.id)/modlog") {
                    UIApplication.shared.open(url)
                }
            }

            Button(L10n.Entry.cancel, role: .cancel) {}
        }
        .onChange(of: pendingRoute) { route in
            if let route {
                nav.push(route)
                pendingRoute = nil
            }
        }
    }

    private func resolveInternalLink(_ path: String) -> Route {
        // ?q=baslik+adi → bkz link to a topic
        if path.hasPrefix("?q=") {
            let query = String(path.dropFirst(3))
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? String(path.dropFirst(3))
            // Use percent-encoded topic name as path (eksisozluk format)
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
            return .entryList(link: encoded, title: query)
        }
        // biri/username → profile
        if path.hasPrefix("biri/") {
            let username = String(path.dropFirst(5)).removingPercentEncoding ?? String(path.dropFirst(5))
            return .profile(username: username)
        }
        // entry/12345 → entry by ID
        if path.hasPrefix("entry/") {
            let id = String(path.dropFirst(6))
            return .entryById(id: id)
        }
        // baslik-adi--12345 → topic
        return .entryList(link: path, title: "")
    }

    private func shareItems(_ items: [Any]) {
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            if let popover = av.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            root.present(av, animated: true)
        }
    }

    private func shareEntryScreenshot() {
        let renderer = EntryScreenshotRenderer(entry: entry, theme: themeManager.current)
        if let image = renderer.render() {
            shareItems([image])
        }
    }
}

// MARK: - Screenshot Renderer

private struct EntryScreenshotRenderer {
    let entry: Entry
    let theme: AppTheme

    func render() -> UIImage? {
        let width: CGFloat = 375
        let contentView = VStack(alignment: .leading, spacing: 12) {
            Text(entry.contentHTML.strippingHTML)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: UIColor(theme.entryTextColor)))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(entry.author.nick)
                    .font(.caption.bold())
                    .foregroundColor(theme.accentColor)
                Spacer()
                Text(entry.date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(L10n.Entry.watermark(id: entry.id))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(theme.cellPrimaryColor)
        .frame(width: width)

        let controller = UIHostingController(rootView: contentView)
        let size = controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor(theme.cellPrimaryColor)
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - HTML Stripping

extension String {
    var strippingHTML: String {
        guard let data = data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else {
            return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        return attributed.string
    }
}
