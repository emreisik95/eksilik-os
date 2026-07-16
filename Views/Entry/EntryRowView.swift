import SwiftUI
import UIKit

struct EntryRowView: View {
    let entry: Entry
    let isEven: Bool
    let onFavorite: () -> Void
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onOpenImages: ([String], Int) -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var preferences: UserPreferences
    @State private var showActions = false
    @State private var pendingRoute: Route?

    private var style: EntryLayoutStyle { preferences.entryLayoutStyle }
    private var presentation: EntryLayoutPresentation { style.presentation }

    private var secondaryTextColor: Color {
        themeManager.current.dateColor.opacity(0.65)
    }

    private var actionButtonColor: Color {
        themeManager.current.dateColor.opacity(0.5)
    }

    var body: some View {
        rowContainer
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
            .task(id: entry.id) {
                await ImagePipeline.shared.prefetch(entry.imageURLs + [entry.author.avatarURL].compactMap { $0 })
            }
    }

    @ViewBuilder
    private var rowContainer: some View {
        if presentation.container == .card {
            rowContents
                .background(themeManager.current.cellPrimaryColor)
                .clipShape(RoundedRectangle(
                    cornerRadius: CGFloat(presentation.cornerRadius),
                    style: .continuous
                ))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: CGFloat(presentation.cornerRadius),
                        style: .continuous
                    )
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.current.backgroundColor)
        } else {
            rowContents
                .background(rowBackgroundColor)
        }
    }

    private var rowContents: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: CGFloat(presentation.contentSpacing)) {
                metadataBeforeContent
                entryContent
                metadataAfterContent
            }
            .padding(.horizontal, CGFloat(presentation.horizontalPadding))
            .padding(.vertical, CGFloat(presentation.verticalPadding))

            if presentation.actionStyle != .quiet {
                actionDivider
            }

            actionBar

            if presentation.container == .fullWidth && presentation.separatorHeight > 0 {
                Rectangle()
                    .fill(themeManager.current.separatorColor.opacity(0.25))
                    .frame(height: CGFloat(presentation.separatorHeight))
            }
        }
    }

    private var rowBackgroundColor: Color {
        if (style == .compact || style == .minimal) && !isEven {
            return themeManager.current.cellSecondaryColor
        }
        return themeManager.current.cellPrimaryColor
    }

    private var entryContent: some View {
        VStack(alignment: .leading, spacing: max(8, CGFloat(presentation.contentSpacing) - 4)) {
            EntryTextView(
                attributedText: entry.parsedContent,
                onInternalLink: { path in
                    nav.push(resolveInternalLink(path))
                },
                onImageLink: { imageURL in
                    onOpenImages([imageURL], 0)
                }
            )

            if !entry.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(entry.imageURLs.enumerated()), id: \.element) { index, urlStr in
                            CachedRemoteImage(url: urlStr)
                                .frame(width: imageSize.width, height: imageSize.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onOpenImages(entry.imageURLs, index)
                                }
                        }
                    }
                }
            }
        }
    }

    private var imageSize: CGSize {
        switch style {
        case .compact, .minimal: return CGSize(width: 132, height: 96)
        case .comfortable, .focus: return CGSize(width: 184, height: 132)
        default: return CGSize(width: 160, height: 120)
        }
    }

    @ViewBuilder
    private var metadataBeforeContent: some View {
        switch presentation.metadataPlacement {
        case .authorHeader:
            standardMetadataRow
            metadataDivider
        case .metadataHeader:
            dateHeader
            metadataDivider
        case .footer, .inlineFooter:
            EmptyView()
        }
    }

    @ViewBuilder
    private var metadataAfterContent: some View {
        switch presentation.metadataPlacement {
        case .footer:
            standardMetadataRow
        case .inlineFooter:
            inlineMetadataRow
        case .authorHeader:
            dateHeader
        case .metadataHeader:
            authorButton
        }
    }

    private var standardMetadataRow: some View {
        HStack(alignment: .center, spacing: 10) {
            authorButton
            Spacer(minLength: 12)
            dateBlock
        }
    }

    private var inlineMetadataRow: some View {
        HStack(spacing: 8) {
            authorButton
            Spacer(minLength: 8)
            Text("\(entry.date) · #\(entry.id)")
                .font(.caption2)
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
    }

    private var dateHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
            Text(entry.date)
            Text("#\(entry.id)")
            Spacer()
        }
        .font(.caption)
        .foregroundColor(secondaryTextColor)
    }

    private var dateBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(entry.date)
                .font(.caption)
            Text("#\(entry.id)")
                .font(.caption2)
                .opacity(0.7)
        }
        .foregroundColor(secondaryTextColor)
    }

    private var authorButton: some View {
        Button {
            nav.push(Route.profile(username: entry.author.nick))
        } label: {
            HStack(spacing: presentation.showsAvatar ? 8 : 0) {
                if presentation.showsAvatar, let avatarURL = entry.author.avatarURL {
                    CachedRemoteImage(url: avatarURL)
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                }
                Text(entry.author.nick)
                    .font(authorFont)
                    .foregroundColor(themeManager.current.accentColor)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 32)
    }

    private var avatarSize: CGFloat {
        style == .comfortable || style == .authorFirst ? 28 : 24
    }

    private var authorFont: Font {
        style == .authorFirst ? .body.weight(.semibold) : .subheadline.weight(.medium)
    }

    private var metadataDivider: some View {
        Rectangle()
            .fill(themeManager.current.separatorColor.opacity(0.14))
            .frame(height: 1)
    }

    private var actionDivider: some View {
        Rectangle()
            .fill(themeManager.current.separatorColor.opacity(0.15))
            .frame(height: 1)
            .padding(.horizontal, CGFloat(presentation.horizontalPadding))
    }

    private var actionBar: some View {
        HStack(spacing: presentation.actionStyle == .standard ? 0 : 4) {
            Button(action: onFavorite) {
                HStack(spacing: 5) {
                    Image(systemName: entry.isFavorited ? "star.fill" : "star")
                        .font(.system(size: actionIconSize))
                    Text("\(entry.favoriteCount)")
                        .font(.subheadline)
                }
                .foregroundColor(entry.isFavorited ? .yellow : actionButtonColor)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 52, minHeight: actionHeight)

            if session.isLoggedIn && entry.author.nick != session.username {
                Button(action: onUpvote) {
                    Image(systemName: entry.voteState == .upvoted
                        ? "chevron.up.circle.fill"
                        : "chevron.up")
                        .font(.system(size: actionIconSize, weight: .medium))
                        .foregroundColor(entry.voteState == .upvoted
                            ? themeManager.current.accentColor
                            : actionButtonColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 48, minHeight: actionHeight)

                Button(action: onDownvote) {
                    Image(systemName: entry.voteState == .downvoted
                        ? "chevron.down.circle.fill"
                        : "chevron.down")
                        .font(.system(size: actionIconSize, weight: .medium))
                        .foregroundColor(entry.voteState == .downvoted ? .red : actionButtonColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 48, minHeight: actionHeight)
            }

            Spacer()

            Button {
                shareItems([entry.shareURL])
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: actionIconSize))
                    .foregroundColor(actionButtonColor)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 48, minHeight: actionHeight)

            Button {
                showActions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: actionIconSize))
                    .foregroundColor(actionButtonColor)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 48, minHeight: actionHeight)
        }
        .padding(.horizontal, presentation.actionStyle == .quiet
            ? CGFloat(presentation.horizontalPadding)
            : 10)
        .background(
            presentation.actionStyle == .quiet
                ? themeManager.current.cellSecondaryColor.opacity(0.72)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, presentation.actionStyle == .quiet ? 12 : 0)
        .padding(.bottom, presentation.actionStyle == .quiet ? 12 : 0)
    }

    private var actionHeight: CGFloat {
        presentation.actionStyle == .quiet ? 50 : 46
    }

    private var actionIconSize: CGFloat {
        presentation.actionStyle == .compact ? 16 : 17
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
