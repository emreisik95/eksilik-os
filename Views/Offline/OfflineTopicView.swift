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
                                preferences.entryLayoutStyle.presentation.container == .card
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
        if preferences.entryLayoutStyle.presentation.container == .card {
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

    private func offlineEntryContents(_ rendered: OfflineRenderedEntry, isRead: Bool) -> some View {
        let presentation = preferences.entryLayoutStyle.presentation

        return VStack(alignment: .leading, spacing: CGFloat(presentation.contentSpacing)) {
            if presentation.metadataPlacement == .authorHeader {
                offlineStandardMetadata(rendered, isRead: isRead)
                offlineMetadataDivider
            } else if presentation.metadataPlacement == .metadataHeader {
                offlineDateHeader(rendered)
                offlineMetadataDivider
            }

            EntryTextView(attributedText: rendered.attributedContent)

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

            switch presentation.metadataPlacement {
            case .footer:
                offlineStandardMetadata(rendered, isRead: isRead)
            case .inlineFooter:
                offlineInlineMetadata(rendered, isRead: isRead)
            case .authorHeader:
                offlineDateHeader(rendered)
            case .metadataHeader:
                offlineAuthor(rendered, isRead: isRead)
            }
        }
        .padding(.horizontal, CGFloat(presentation.horizontalPadding))
        .padding(.vertical, CGFloat(presentation.verticalPadding))
        .opacity(isRead ? 0.58 : 1)
        .animation(.easeOut(duration: 0.2), value: isRead)
    }

    private var offlineImageSize: CGSize {
        switch preferences.entryLayoutStyle {
        case .compact, .minimal: return CGSize(width: 132, height: 96)
        case .comfortable, .focus: return CGSize(width: 184, height: 132)
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
        HStack(spacing: preferences.entryLayoutStyle.presentation.showsAvatar ? 8 : 0) {
            if preferences.entryLayoutStyle.presentation.showsAvatar,
               let avatar = rendered.localAvatarURL {
                LocalFileImage(url: avatar, contentMode: .fill)
                    .frame(width: offlineAvatarSize, height: offlineAvatarSize)
                    .clipShape(Circle())
            }
            Text(rendered.entry.authorNick)
                .font(preferences.entryLayoutStyle == .authorFirst
                    ? .body.weight(.semibold)
                    : .subheadline.weight(.medium))
                .foregroundColor(themeManager.current.accentColor)
            if isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(themeManager.current.accentColor)
                    .accessibilityLabel("okundu")
            }
        }
    }

    private var offlineAvatarSize: CGFloat {
        preferences.entryLayoutStyle == .comfortable || preferences.entryLayoutStyle == .authorFirst
            ? 28
            : 24
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
