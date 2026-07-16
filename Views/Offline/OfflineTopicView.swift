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

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                EntryListSkeletonView()
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    Task { await load() }
                }
            } else if viewModel.entries.isEmpty {
                EmptyStateView(message: L10n.Entry.noEntries)
            } else {
                List {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, rendered in
                        offlineEntry(rendered)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                index.isMultiple(of: 2)
                                    ? themeManager.current.cellPrimaryColor
                                    : themeManager.current.cellSecondaryColor
                            )
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
                Label("çevrimdışı", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(themeManager.current.accentColor)
            }
        }
        .task { await load() }
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

    private func offlineEntry(_ rendered: OfflineRenderedEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EntryTextView(attributedText: rendered.attributedContent)

            if !rendered.localImageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(rendered.localImageURLs.enumerated()), id: \.element) { index, url in
                            LocalFileImage(url: url, contentMode: .fill)
                                .frame(width: 160, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
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

            HStack(spacing: 8) {
                if let avatar = rendered.localAvatarURL {
                    LocalFileImage(url: avatar, contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }
                Text(rendered.entry.authorNick)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.current.accentColor)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rendered.entry.date)
                    Text("#\(rendered.entry.id)")
                }
                .font(.caption2)
                .foregroundColor(themeManager.current.dateColor)
            }
        }
        .padding(16)
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
