import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var preferences: UserPreferences
    @StateObject private var viewModel: EntryListViewModel
    let title: String
    @State private var showSearchAlert = false
    @State private var searchKeywords = ""
    @State private var showDownloadOptions = false
    @State private var galleryPresentation: ImageGalleryPresentation?
    @State private var showFilterSwipeOnboarding = false
    @AppStorage(EntryListChromePolicy.filterSwipeOnboardingStorageKey)
    private var hasSeenFilterSwipeOnboarding = false

    init(link: String, title: String) {
        _viewModel = StateObject(wrappedValue: EntryListViewModel(link: link))
        self.title = title
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                EntryListSkeletonView()
            } else if let error = viewModel.error, viewModel.entries.isEmpty {
                ErrorView(
                    message: error,
                    showRetry: !error.contains("reklams\u{0131}z")
                ) {
                    Task { await viewModel.loadEntries() }
                }
            } else if viewModel.entries.isEmpty && viewModel.activeFilter != .none {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("bu filtrede entry bulunamadı")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Button("tümüne dön") {
                        Task { await viewModel.applyFilter(.none) }
                    }
                    .foregroundColor(themeManager.current.accentColor)
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.entries.isEmpty {
                EmptyStateView(message: L10n.Entry.noEntries)
            } else {
                List {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRowView(
                            entry: entry,
                            isEven: index % 2 == 0,
                            onFavorite: { Task { await viewModel.toggleFavorite(for: entry) } },
                            onUpvote: { Task { await viewModel.vote(for: entry, rate: 1) } },
                            onDownvote: { Task { await viewModel.vote(for: entry, rate: -1) } },
                            onOpenImages: { imageURLs, index in
                                galleryPresentation = ImageGalleryPresentation(
                                    imageURLs: imageURLs,
                                    initialIndex: index
                                )
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(themeManager.current.backgroundColor)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .id(preferences.entryLayoutStyle.id)
                .animation(.easeInOut(duration: 0.2), value: preferences.entryLayoutStyle)
            }

            // Loading overlay when switching filters
            if viewModel.isLoading && !viewModel.entries.isEmpty {
                ProgressView()
                    .padding(6)
            }

            // Always visible: filter bar + pagination
            filterBar

            if viewModel.pagination.totalPages > 1 {
                PaginationView(
                    pagination: viewModel.pagination,
                    onPageChange: { page in Task { await viewModel.goToPage(page) } }
                )
            }
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.current.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                Text(viewModel.title.isEmpty ? title : viewModel.title)
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: UIScreen.main.bounds.width - 160)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDownloadOptions = true
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .accessibilityLabel("başlığı çevrimdışı indir")
            }
            if session.isLoggedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            Task { await viewModel.toggleTracking() }
                        } label: {
                            Image(systemName: viewModel.isTracked ? "bell.fill" : "bell")
                                .foregroundColor(viewModel.isTracked ? themeManager.current.accentColor : .gray)
                        }

                        NavigationLink(value: Route.composeEntry(topicLink: viewModel.topicLink)) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
        })
        .alert("başlıkta ara", isPresented: $showSearchAlert) {
            TextField("aranacak kelime...", text: $searchKeywords)
            Button("ara") {
                guard !searchKeywords.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                Task { await viewModel.applyFilter(.search(searchKeywords)) }
            }
            Button("vazgeç", role: .cancel) { }
        }
        .sheet(isPresented: $showDownloadOptions) {
            DownloadOptionsView(
                title: viewModel.title.isEmpty ? title : viewModel.title,
                request: viewModel.offlineRequest,
                totalPages: viewModel.offlineTotalPages
            )
        }
        .sheet(isPresented: $showFilterSwipeOnboarding, onDismiss: {
            hasSeenFilterSwipeOnboarding = true
        }) {
            EntryFilterSwipeOnboardingView {
                hasSeenFilterSwipeOnboarding = true
                showFilterSwipeOnboarding = false
            }
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $galleryPresentation) { presentation in
            ImageLightboxView(presentation: presentation)
        }
        .task {
            if viewModel.entries.isEmpty {
                await viewModel.loadEntries()
            }
            if EntryListChromePolicy.shouldPresentFilterSwipeOnboarding(
                hasSeen: hasSeenFilterSwipeOnboarding
            ) {
                showFilterSwipeOnboarding = true
            }
        }
        .refreshable { await viewModel.loadEntries() }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "tümü", icon: "list.bullet", filter: .none)
                filterChip(label: "bugün", icon: "sun.max", filter: .dailyNice)
                sukelaMenu
                filterChip(label: "ekşi şeyler", icon: "drop.fill", filter: .eksiseyler)
                filterChip(label: "linkler", icon: "link", filter: .links)
                filterChip(label: "görseller", icon: "photo", filter: .images)
                filterChip(label: "çaylaklar", icon: "leaf", filter: .caylak)

                if session.isLoggedIn {
                    Button {
                        Task {
                            let username = SessionManager.shared.username ?? ""
                            await viewModel.applyFilter(.author(username))
                        }
                    } label: {
                        filterChipLabel(
                            label: "benimkiler",
                            icon: "person.fill",
                            isActive: { if case .author = viewModel.activeFilter { return true }; return false }()
                        )
                    }
                }

                Button {
                    searchKeywords = ""
                    showSearchAlert = true
                } label: {
                    filterChipLabel(
                        label: "başlıkta ara",
                        icon: "magnifyingglass",
                        isActive: { if case .search = viewModel.activeFilter { return true }; return false }()
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 52)
        .background(themeManager.current.backgroundColor)
    }

    private var sukelaLabel: String {
        switch viewModel.activeFilter {
        case .nice: return "şükela 24 saat"
        case .niceWeek: return "şükela 1 hafta"
        case .niceMonth: return "şükela 1 ay"
        case .nice3Months: return "şükela 3 ay"
        case .niceAllTime: return "şükela tümü"
        default: return "şükela"
        }
    }

    private var sukelaMenu: some View {
        Menu {
            Button("son 24 saat") { Task { await viewModel.applyFilter(.nice) } }
            if session.isPaidMember {
                Button("son 1 hafta") { Task { await viewModel.applyFilter(.niceWeek) } }
                Button("son 1 ay") { Task { await viewModel.applyFilter(.niceMonth) } }
                Button("son 3 ay") { Task { await viewModel.applyFilter(.nice3Months) } }
            }
            Button("tümü") { Task { await viewModel.applyFilter(.niceAllTime) } }
        } label: {
            filterChipLabel(
                label: sukelaLabel,
                icon: "star.fill",
                isActive: [.nice, .niceWeek, .niceMonth, .nice3Months, .niceAllTime].contains(viewModel.activeFilter)
            )
        }
    }

    private func filterChip(label: String, icon: String, filter: EntryFilter) -> some View {
        Button {
            Task { await viewModel.applyFilter(filter) }
        } label: {
            filterChipLabel(label: label, icon: icon, isActive: viewModel.activeFilter == filter)
        }
    }

    @ViewBuilder
    private func filterChipLabel(label: String, icon: String = "", isActive: Bool) -> some View {
        Group {
            if preferences.useIconFilters && !icon.isEmpty {
                Image(systemName: icon)
                    .font(.body.weight(isActive ? .semibold : .regular))
            } else {
                Text(label)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .foregroundColor(isActive
            ? themeManager.current.backgroundColor
            : themeManager.current.labelColor)
        .padding(.horizontal, preferences.useIconFilters && !icon.isEmpty ? 12 : 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive
                    ? themeManager.current.accentColor
                    : themeManager.current.cellSecondaryColor)
        )
    }
}

private struct EntryFilterSwipeOnboardingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.left.and.right.circle.fill")
                .font(.system(size: 54))
                .foregroundColor(themeManager.current.accentColor)

            VStack(spacing: 8) {
                Text("filtreler arasında gezin")
                    .font(.title3.bold())
                    .foregroundColor(themeManager.current.labelColor)
                Text("Tümü, bugün, şükela ve diğer filtreleri görmek için filtre şeridini sağa veya sola kaydır.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Image(systemName: "hand.draw")
                    .foregroundColor(themeManager.current.accentColor)
                Text("İstediğin görünüme geçmek için filtreye dokun.")
                    .font(.footnote)
                    .foregroundColor(themeManager.current.labelColor)
                Spacer()
            }
            .padding(12)
            .background(
                themeManager.current.cellSecondaryColor,
                in: RoundedRectangle(cornerRadius: 12)
            )

            Button(action: onDismiss) {
                Text("anladım")
                    .font(.body.weight(.semibold))
                    .foregroundColor(themeManager.current.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        themeManager.current.accentColor,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
        }
        .padding(24)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
    }
}
