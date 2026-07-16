import SwiftUI
import UIKit

struct OfflineTopicView: View {
    let topicID: String
    let title: String

    @StateObject private var viewModel = OfflineTopicReaderViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @State private var galleryURLs: [URL] = []
    @State private var galleryIndex = 0
    @State private var showGallery = false
    @State private var showReadOnboarding = false
    @AppStorage("hasSeenOfflineReadSwipeOnboarding") private var hasSeenReadOnboarding = false

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasDownloadedEntries {
                EntryListSkeletonView()
            } else if let error = viewModel.error, !viewModel.hasDownloadedEntries {
                ErrorView(message: error) {
                    Task { await load() }
                }
            } else if !viewModel.hasDownloadedEntries {
                EmptyStateView(message: L10n.Entry.noEntries)
            } else if viewModel.visibleEntries.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(themeManager.current.accentColor)
                    Text("okunmamış entry kalmadı")
                        .font(.headline)
                        .foregroundColor(themeManager.current.labelColor)
                    Button("okunanları göster") {
                        Task { await viewModel.toggleHidingReadEntries() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.current.accentColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.visibleEntries.enumerated()), id: \.element.id) { index, rendered in
                        offlineEntry(rendered, isRead: viewModel.isRead(rendered.id))
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                preferences.entryLayoutStyle.family == .linkedIn
                                    ? themeManager.current.backgroundColor
                                    : (index.isMultiple(of: 2)
                                        ? themeManager.current.cellPrimaryColor
                                        : themeManager.current.cellSecondaryColor)
                            )
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                readToggleButton(rendered)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                readToggleButton(rendered)
                            }
                    }
                }
                .listStyle(.plain)
                .id(preferences.entryLayoutStyle.id)
                .animation(.easeInOut(duration: 0.2), value: preferences.entryLayoutStyle)
            }
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.toggleHidingReadEntries() }
                } label: {
                    Image(systemName: viewModel.readState.hidesReadEntries ? "eye.slash.fill" : "eye.slash")
                }
                .disabled(!viewModel.hasDownloadedEntries)
                .accessibilityLabel(
                    viewModel.readState.hidesReadEntries
                        ? "okunan entry'leri göster"
                        : "okunan entry'leri gizle"
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.current.accentColor)
                    .accessibilityLabel("çevrimdışı")
            }
        }
        .task {
            await load()
            if viewModel.hasDownloadedEntries && !hasSeenReadOnboarding {
                showReadOnboarding = true
            }
        }
        .sheet(isPresented: $showReadOnboarding, onDismiss: {
            hasSeenReadOnboarding = true
        }) {
            OfflineReadOnboardingView {
                hasSeenReadOnboarding = true
                showReadOnboarding = false
            }
            .presentationDetents([.height(390)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showGallery) {
            OfflineImageLightboxView(
                urls: galleryURLs,
                selectedIndex: $galleryIndex,
                isPresented: $showGallery
            )
        }
    }

    private func load() async {
        await viewModel.load(
            topicID: topicID,
            theme: themeManager.current,
            preferences: preferences
        )
    }

    @ViewBuilder
    private func offlineEntry(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        if preferences.entryLayoutStyle.family == .linkedIn {
            offlineEntryContents(rendered, isRead: isRead)
                .background(themeManager.current.cellPrimaryColor)
                .clipShape(RoundedRectangle(
                    cornerRadius: CGFloat(preferences.entryLayoutStyle.presentation.cornerRadius),
                    style: .continuous
                ))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: CGFloat(preferences.entryLayoutStyle.presentation.cornerRadius),
                        style: .continuous
                    )
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        } else {
            offlineEntryContents(rendered, isRead: isRead)
        }
    }

    @ViewBuilder
    private func offlineEntryContents(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        Group {
            switch preferences.entryLayoutStyle.family {
            case .classic:
                offlineClassicLayout(rendered, isRead: isRead)
            case .xFeed:
                offlineXLayout(rendered, isRead: isRead)
            case .instagram:
                offlineInstagramLayout(rendered, isRead: isRead)
            case .linkedIn:
                offlineLinkedInLayout(rendered, isRead: isRead)
            case .reddit:
                offlineRedditLayout(rendered, isRead: isRead)
            case .reader:
                offlineReaderLayout(rendered, isRead: isRead)
            case .terminal:
                offlineTerminalLayout(rendered, isRead: isRead)
            case .minimal:
                offlineMinimalLayout(rendered, isRead: isRead)
            }
        }
        .opacity(isRead ? 0.58 : 1)
        .animation(.easeOut(duration: 0.2), value: isRead)
    }

    private func offlineClassicLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            offlineBody(rendered)
            offlineStandardMetadata(rendered, isRead: isRead)
        }
        .padding(16)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 6)
        }
    }

    private func offlineXLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            offlineAvatar(rendered, size: 42)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    offlineAuthorName(rendered, isRead: isRead, font: .subheadline.weight(.bold))
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(themeManager.current.accentColor)
                    Text("· \(rendered.entry.date)")
                        .font(.caption)
                        .foregroundColor(themeManager.current.dateColor)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(themeManager.current.dateColor.opacity(0.7))
                }
                offlineBody(rendered)
                offlineSocialLine(rendered)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 2)
        }
    }

    private func offlineInstagramLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                offlineAvatar(rendered, size: 36)
                    .overlay(Circle().stroke(themeManager.current.accentColor, lineWidth: 2))
                offlineAuthorName(rendered, isRead: isRead, font: .subheadline.weight(.bold))
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(themeManager.current.dateColor)
            }
            offlineBody(rendered)
            offlineSocialLine(rendered)
            Text("\(rendered.entry.date) · #\(rendered.entry.id)")
                .font(.caption2)
                .foregroundColor(themeManager.current.dateColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 6)
        }
    }

    private func offlineLinkedInLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    offlineAvatar(rendered, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        offlineAuthorName(rendered, isRead: isRead, font: .subheadline.weight(.bold))
                        Text("sözlük yazarı · \(rendered.entry.date)")
                        Text("#\(rendered.entry.id)")
                    }
                    .font(.caption2)
                    .foregroundColor(themeManager.current.dateColor)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeManager.current.dateColor)
                }
                offlineBody(rendered)
            }
            .padding(16)

            offlineMetadataDivider

            HStack {
                Label("\(rendered.entry.favoriteCount)", systemImage: "star")
                Spacer()
                Label("indirildi", systemImage: "checkmark.circle.fill")
                Spacer()
                Label(isRead ? "okundu" : "okunmadı", systemImage: isRead ? "eye.fill" : "eye")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(themeManager.current.dateColor)
            .frame(minHeight: 48)
            .padding(.horizontal, 16)
        }
    }

    private func offlineRedditLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.up")
                Text("\(rendered.entry.favoriteCount)")
                    .font(.caption.weight(.bold))
                Image(systemName: "arrow.down")
            }
            .foregroundColor(themeManager.current.accentColor)
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 10) {
                Text("r/ekşisözlük · \(rendered.entry.authorNick) · \(rendered.entry.date)")
                    .font(.caption2)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(1)
                offlineBody(rendered)
                HStack(spacing: 16) {
                    Label("entry", systemImage: "text.bubble")
                    Label("indirildi", systemImage: "arrow.down.circle")
                    if isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.current.dateColor)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 4)
        }
    }

    private func offlineReaderLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("ENTRY \(rendered.entry.id)")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.3)
                Spacer()
                Image(systemName: isRead ? "bookmark.fill" : "bookmark")
            }
            .foregroundColor(themeManager.current.dateColor)
            offlineBody(rendered)
            HStack(spacing: 10) {
                Rectangle()
                    .fill(themeManager.current.accentColor)
                    .frame(width: 28, height: 2)
                offlineAuthorName(rendered, isRead: isRead, font: .caption.weight(.semibold))
                Text("· \(rendered.entry.date)")
                    .font(.caption)
                    .foregroundColor(themeManager.current.dateColor)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 8)
        }
    }

    private func offlineTerminalLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("> \(rendered.entry.authorNick)@eksi \(rendered.entry.date) #\(rendered.entry.id)")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(themeManager.current.accentColor)
                .lineLimit(1)
            offlineBody(rendered)
            Text("[★ \(rendered.entry.favoriteCount)]  [downloaded]  \(isRead ? "[read]" : "[unread]")")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(themeManager.current.dateColor)
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(themeManager.current.accentColor)
                .frame(width: 3)
        }
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 1)
        }
    }

    private func offlineMinimalLayout(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            offlineBody(rendered)
            HStack(spacing: 6) {
                offlineAuthorName(rendered, isRead: isRead, font: .caption.weight(.semibold))
                Text("· \(rendered.entry.date)")
                    .font(.caption2)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(1)
                Spacer()
                Label("\(rendered.entry.favoriteCount)", systemImage: "star")
                    .font(.caption)
                    .foregroundColor(themeManager.current.dateColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            offlineSeparator(height: 1)
        }
    }

    private func offlineBody(_ rendered: OfflineRenderedEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            EntryTextView(attributedText: rendered.attributedContent)
            offlineImages(rendered)
        }
    }

    @ViewBuilder
    private func offlineImages(_ rendered: OfflineRenderedEntry) -> some View {
        if !rendered.localImageURLs.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(rendered.localImageURLs.enumerated()), id: \.element) { index, url in
                        LocalFileImage(url: url, contentMode: .fill)
                            .frame(width: offlineImageSize.width, height: offlineImageSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                galleryURLs = rendered.localImageURLs
                                galleryIndex = index
                                showGallery = true
                            }
                    }
                }
            }
        }
    }

    private var offlineImageSize: CGSize {
        switch preferences.entryLayoutStyle.family {
        case .xFeed, .minimal, .terminal: return CGSize(width: 140, height: 100)
        case .instagram, .reader: return CGSize(width: 196, height: 146)
        case .linkedIn: return CGSize(width: 184, height: 132)
        default: return CGSize(width: 160, height: 120)
        }
    }

    private func offlineStandardMetadata(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        HStack(spacing: 10) {
            offlineAuthor(rendered, isRead: isRead)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(rendered.entry.date)
                Text("#\(rendered.entry.id)")
            }
            .font(.caption2)
            .foregroundColor(themeManager.current.dateColor)
        }
    }

    private func offlineInlineMetadata(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        HStack(spacing: 8) {
            offlineAuthor(rendered, isRead: isRead)
            Spacer(minLength: 8)
            Text("\(rendered.entry.date) · #\(rendered.entry.id)")
                .font(.caption2)
                .foregroundColor(themeManager.current.dateColor)
                .lineLimit(1)
        }
    }

    private func offlineDateHeader(_ rendered: OfflineRenderedEntry) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
            Text(rendered.entry.date)
            Text("#\(rendered.entry.id)")
            Spacer()
        }
        .font(.caption)
        .foregroundColor(themeManager.current.dateColor)
    }

    private func offlineAuthor(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        HStack(spacing: 8) {
            offlineAvatar(rendered, size: offlineAvatarSize)
            offlineAuthorName(rendered, isRead: isRead, font: .subheadline.weight(.medium))
        }
    }

    private var offlineAvatarSize: CGFloat {
        preferences.entryLayoutStyle.family == .instagram || preferences.entryLayoutStyle.family == .linkedIn
            ? 28
            : 24
    }

    @ViewBuilder
    private func offlineAvatar(_ rendered: OfflineRenderedEntry, size: CGFloat) -> some View {
        if let avatar = rendered.localAvatarURL {
            LocalFileImage(url: avatar, contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(themeManager.current.accentColor.opacity(0.14))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42))
                        .foregroundColor(themeManager.current.accentColor)
                }
        }
    }

    private func offlineAuthorName(
        _ rendered: OfflineRenderedEntry,
        isRead: Bool,
        font: Font
    ) -> some View {
        HStack(spacing: 5) {
            Text(rendered.entry.authorNick)
                .font(font)
                .foregroundColor(themeManager.current.accentColor)
                .lineLimit(1)
            if isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(themeManager.current.accentColor)
                    .accessibilityLabel("okundu")
            }
        }
    }

    private func offlineSocialLine(_ rendered: OfflineRenderedEntry) -> some View {
        HStack(spacing: 22) {
            Label("\(rendered.entry.favoriteCount)", systemImage: "star")
            Image(systemName: "chevron.up")
            Image(systemName: "chevron.down")
            Spacer()
            Image(systemName: "arrow.down.circle")
            Image(systemName: "ellipsis")
        }
        .font(.caption)
        .foregroundColor(themeManager.current.dateColor.opacity(0.75))
        .frame(minHeight: 44)
    }

    private func offlineSeparator(height: CGFloat) -> some View {
        Rectangle()
            .fill(themeManager.current.separatorColor.opacity(0.25))
            .frame(height: height)
    }

    private var offlineMetadataDivider: some View {
        Rectangle()
            .fill(themeManager.current.separatorColor.opacity(0.14))
            .frame(height: 1)
    }

    private func readToggleButton(_ rendered: OfflineRenderedEntry) -> some View {
        let isRead = viewModel.isRead(rendered.id)
        return Button {
            Task { await viewModel.toggleRead(entryID: rendered.id) }
        } label: {
            Label(
                isRead ? "okunmadı" : "okundu",
                systemImage: isRead ? "arrow.uturn.backward.circle" : "checkmark.circle"
            )
        }
        .tint(isRead ? themeManager.current.accentColor : .green)
    }
}

private struct OfflineReadOnboardingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.left.and.right.circle.fill")
                .font(.system(size: 54))
                .foregroundColor(themeManager.current.accentColor)

            VStack(spacing: 8) {
                Text("okuduklarını ayır")
                    .font(.title3.bold())
                    .foregroundColor(themeManager.current.labelColor)
                Text("Bir entry'yi sağa veya sola kaydırarak okundu ya da okunmadı olarak işaretleyebilirsin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Image(systemName: "eye.slash")
                    .foregroundColor(themeManager.current.accentColor)
                Text("Üstteki göz düğmesi okunan entry'leri gizler.")
                    .font(.footnote)
                    .foregroundColor(themeManager.current.labelColor)
                Spacer()
            }
            .padding(12)
            .background(themeManager.current.cellSecondaryColor, in: RoundedRectangle(cornerRadius: 12))

            Button(action: onDismiss) {
                Text("anladım")
                    .font(.body.weight(.semibold))
                    .foregroundColor(themeManager.current.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(themeManager.current.accentColor, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
    }
}

private struct LocalFileImage: View {
    let url: URL
    let contentMode: ContentMode

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
        }
        .clipped()
    }
}

private struct OfflineImageLightboxView: View {
    let urls: [URL]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $selectedIndex) {
                ForEach(Array(urls.enumerated()), id: \.element) { index, url in
                    LocalFileImage(url: url, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.65), in: Circle())
                    }
                    .accessibilityLabel("kapat")
                }
                .padding(16)
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}
