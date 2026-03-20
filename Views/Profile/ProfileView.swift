import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @State private var entryToDelete: UserProfile.ProfileEntry?
    /// When true, wraps in NavigationStack (tab root). When false, used as push destination.
    var isRoot: Bool = false

    init(username: String, isRoot: Bool = false) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(username: username))
        self.isRoot = isRoot
    }

    var body: some View {
        if isRoot {
            NavigationStack {
                content
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
        } else {
            content
        }
    }

    private var content: some View {
        ZStack {
            themeManager.current.backgroundColor.ignoresSafeArea()

            if viewModel.isLoading && viewModel.profile == nil {
                LoadingView()
            } else if let profile = viewModel.profile {
                profileContent(profile)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    Task { await viewModel.loadProfile() }
                }
            }
        }
        .navigationTitle(viewModel.profile?.nick ?? viewModel.username)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadProfile() }
        .confirmationDialog("entry'i sil", isPresented: Binding(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("sil", role: .destructive) {
                if let entry = entryToDelete {
                    Task { await viewModel.deleteEntry(id: entry.id) }
                    entryToDelete = nil
                }
            }
            Button(L10n.Entry.cancel, role: .cancel) { entryToDelete = nil }
        }
    }

    @ViewBuilder
    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                profileHeader(profile)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Divider().overlay(themeManager.current.separatorColor)

                // Tab picker
                tabPicker

                Divider().overlay(themeManager.current.separatorColor)

                // Entry list
                if profile.entries.isEmpty {
                    Text(L10n.Entry.noEntries)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(profile.entries) { entry in
                            profileEntryRow(entry)
                            Divider().overlay(themeManager.current.separatorColor)
                        }

                        // Load more
                        Button {
                            Task { await viewModel.loadMoreEntries() }
                        } label: {
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            } else {
                                Text("daha fazla göster")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.current.accentColor)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Username + bio on the left
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(profile.nick)
                            .font(.title2.bold())
                            .foregroundColor(themeManager.current.labelColor)
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(themeManager.current.accentColor)
                                .font(.subheadline)
                        }
                    }

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Avatar on the right
                if let avatarURL = profile.avatarURL, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(themeManager.current.cellPrimaryColor)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                }
            }

            // Badges
            if !profile.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(profile.badges, id: \.imageURL) { badge in
                            AsyncImage(url: URL(string: badge.imageURL)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Color.clear
                            }
                            .frame(width: 24, height: 24)
                        }
                    }
                }
            }

            // Stats row
            HStack(spacing: 12) {
                if profile.entryCount > 0 {
                    Text(L10n.Profile.entryCount(profile.entryCount))
                        .font(.caption)
                        .foregroundColor(themeManager.current.labelColor)
                }
                if profile.followerCount > 0 {
                    Text(L10n.Profile.followerCount(profile.followerCount))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if profile.followingCount > 0 {
                    Text(L10n.Profile.followingCount(profile.followingCount))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Join date
            if let joinDate = profile.joinDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(joinDate)
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(UserProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                    Button {
                        Task { await viewModel.selectTab(tab) }
                    } label: {
                        Text(tab.title)
                            .font(.subheadline.weight(viewModel.selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedTab == tab ? themeManager.current.accentColor : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }

                // Stats dropdown
                Menu {
                    ForEach(viewModel.statsOptions, id: \.1) { option in
                        Button(option.0) {
                            Task { await viewModel.loadStatsFilter(option.1) }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Profile.stats)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func profileEntryRow(_ entry: UserProfile.ProfileEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pinned indicator
            if entry.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                    Text("sabitlenmiş entry")
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }

            // Topic title
            if !entry.topicTitle.isEmpty {
                NavigationLink(value: Route.entryList(link: entry.topicLink, title: entry.topicTitle)) {
                    Text(entry.topicTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.current.accentColor)
                        .multilineTextAlignment(.leading)
                }
            }

            // Entry content
            EntryTextView(attributedText: entry.parsedContent)

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

            // Author + date
            HStack(alignment: .bottom) {
                Text(entry.author)
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.current.accentColor)
                Spacer()
                Text(entry.date)
                    .font(.caption2)
                    .foregroundColor(themeManager.current.dateColor)
            }

            // Action bar
            HStack(spacing: 20) {
                // Favorite
                Button {
                    Task { await viewModel.toggleFavorite(for: entry) }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: entry.isFavorited ? "star.fill" : "star")
                        Text("\(entry.favoriteCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(entry.isFavorited ? .yellow : .gray)
                }
                .buttonStyle(.plain)

                // Vote buttons (only for other users' entries)
                if session.isLoggedIn && entry.author != session.username {
                    Button {
                        Task { await viewModel.vote(for: entry, rate: 1) }
                    } label: {
                        Image(systemName: entry.voteState == .upvoted ? "chevron.up.circle.fill" : "chevron.up.circle")
                            .foregroundColor(entry.voteState == .upvoted ? themeManager.current.accentColor : .gray)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await viewModel.vote(for: entry, rate: -1) }
                    } label: {
                        Image(systemName: entry.voteState == .downvoted ? "chevron.down.circle.fill" : "chevron.down.circle")
                            .foregroundColor(entry.voteState == .downvoted ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                }

                // Delete (own entries only)
                if entry.author == session.username {
                    Button {
                        entryToDelete = entry
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

}
