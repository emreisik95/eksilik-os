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
    @State private var showLightbox = false
    @State private var lightboxIndex = 0
    @State private var lightboxImages: [String] = []

    private var secondaryTextColor: Color {
        themeManager.current.dateColor.opacity(0.65)
    }

    private var actionButtonColor: Color {
        themeManager.current.dateColor.opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Entry content
            VStack(alignment: .leading, spacing: 12) {
                EntryTextView(
                    attributedText: entry.parsedContent,
                    onInternalLink: { path in
                        let route = resolveInternalLink(path)
                        nav.push(route)
                    },
                    onImageLink: { imageURL in
                        print("📸 Opening lightbox for: \(imageURL)")
                        lightboxImages = [imageURL]
                        lightboxIndex = 0
                        showLightbox = true
                    }
                )

                // Inline images
                if !entry.imageURLs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(entry.imageURLs.enumerated()), id: \.element) { index, urlStr in
                                CookieImage(url: urlStr)
                                    .scaledToFill()
                                    .frame(width: 160, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        lightboxImages = entry.imageURLs
                                        lightboxIndex = index
                                        showLightbox = true
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Footer: Author info + Date/ID
            HStack(alignment: .center, spacing: 0) {
                // Author
                Button {
                    nav.push(Route.profile(username: entry.author.nick))
                } label: {
                    HStack(spacing: 8) {
                        if let avatarURL = entry.author.avatarURL, let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                        }
                        Text(entry.author.nick)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Date + Entry ID
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.date)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    Text("#\(entry.id)")
                        .font(.caption2)
                        .foregroundColor(secondaryTextColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Divider above actions
            Rectangle()
                .fill(themeManager.current.separatorColor.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Action buttons
            HStack(spacing: 0) {
                // Favorite
                Button(action: onFavorite) {
                    HStack(spacing: 5) {
                        Image(systemName: entry.isFavorited ? "star.fill" : "star")
                            .font(.system(size: 15))
                        Text("\(entry.favoriteCount)")
                            .font(.subheadline)
                    }
                    .foregroundColor(entry.isFavorited ? .yellow : actionButtonColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 50, minHeight: 40)

                // Upvote
                if session.isLoggedIn && entry.author.nick != session.username {
                    Button(action: onUpvote) {
                        Image(systemName: entry.voteState == .upvoted ? "chevron.up.circle.fill" : "chevron.up")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(entry.voteState == .upvoted ? themeManager.current.accentColor : actionButtonColor)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 40, minHeight: 40)

                    // Downvote
                    Button(action: onDownvote) {
                        Image(systemName: entry.voteState == .downvoted ? "chevron.down.circle.fill" : "chevron.down")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(entry.voteState == .downvoted ? .red : actionButtonColor)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 40, minHeight: 40)
                }

                Spacer()

                // Share
                Button {
                    shareItems([entry.shareURL])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(actionButtonColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 40, minHeight: 40)

                // More actions
                Button {
                    showActions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(actionButtonColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 40, minHeight: 40)
            }
            .padding(.horizontal, 12)

            // Entry separator
            Rectangle()
                .fill(themeManager.current.separatorColor.opacity(0.25))
                .frame(height: 6)
        }
        .background(themeManager.current.cellPrimaryColor)
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
        .fullScreenCover(isPresented: $showLightbox) {
            ImageLightboxView(
                imageURLs: lightboxImages,
                selectedIndex: $lightboxIndex,
                isPresented: $showLightbox
            )
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
