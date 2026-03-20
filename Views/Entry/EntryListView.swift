import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @StateObject private var viewModel: EntryListViewModel
    let title: String
    @State private var showSearchAlert = false
    @State private var searchKeywords = ""
    @AppStorage("hasSeenFilterHint") private var hasSeenFilterHint = false

    init(link: String, title: String) {
        _viewModel = StateObject(wrappedValue: EntryListViewModel(link: link))
        self.title = title
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                List {
                    ForEach(0..<5, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.current.cellSecondaryColor)
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.current.cellSecondaryColor)
                                .frame(height: 12)
                                .frame(maxWidth: 250)
                            HStack {
                                Circle()
                                    .fill(themeManager.current.cellSecondaryColor)
                                    .frame(width: 20, height: 20)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.current.cellSecondaryColor)
                                    .frame(width: 80, height: 10)
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.current.cellSecondaryColor)
                                    .frame(width: 100, height: 10)
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(themeManager.current.cellPrimaryColor)
                    }
                }
                .listStyle(.plain)
                .redacted(reason: .placeholder)
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
                            onDownvote: { Task { await viewModel.vote(for: entry, rate: -1) } }
                        )
                        .listRowBackground(
                            index % 2 == 0
                            ? themeManager.current.cellPrimaryColor
                            : themeManager.current.cellSecondaryColor
                        )
                        .listRowSeparatorTint(themeManager.current.separatorColor)
                    }
                }
                .listStyle(.plain)
            }

            // Loading overlay when switching filters
            if viewModel.isLoading && !viewModel.entries.isEmpty {
                ProgressView()
                    .padding(6)
            }

            // Always visible: filter bar + pagination
            filterBar
                .overlay(alignment: .trailing) {
                    if !hasSeenFilterHint {
                        HStack(spacing: 4) {
                            Text("kaydır")
                                .font(.caption2)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundColor(themeManager.current.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.current.backgroundColor.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.trailing, 4)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { hasSeenFilterHint = true }
                            }
                        }
                    }
                }

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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.title.isEmpty ? title : viewModel.title)
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if session.isLoggedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: Route.composeEntry(topicLink: viewModel.topicLink)) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .alert("başlıkta ara", isPresented: $showSearchAlert) {
            TextField("aranacak kelime...", text: $searchKeywords)
            Button("ara") {
                guard !searchKeywords.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                Task { await viewModel.applyFilter(.search(searchKeywords)) }
            }
            Button("vazgeç", role: .cancel) { }
        }
        .task { await viewModel.loadEntries() }
        .refreshable { await viewModel.loadEntries() }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "tümü", filter: .none)
                filterChip(label: "bugün", filter: .dailyNice)
                sukelaMenu
                filterChip(label: "ekşi şeyler", filter: .eksiseyler)
                filterChip(label: "linkler", filter: .links)
                filterChip(label: "görseller", filter: .images)
                filterChip(label: "çaylaklar", filter: .caylak)

                if session.isLoggedIn {
                    Button {
                        Task {
                            let username = await SessionManager.shared.username ?? ""
                            await viewModel.applyFilter(.author(username))
                        }
                    } label: {
                        filterChipLabel(
                            label: "benimkiler",
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
                        isActive: { if case .search = viewModel.activeFilter { return true }; return false }()
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(themeManager.current.backgroundColor)
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
                label: "şükela",
                isActive: [.nice, .niceWeek, .niceMonth, .nice3Months, .niceAllTime].contains(viewModel.activeFilter)
            )
        }
    }

    private func filterChip(label: String, filter: EntryFilter) -> some View {
        Button {
            Task { await viewModel.applyFilter(filter) }
        } label: {
            filterChipLabel(label: label, isActive: viewModel.activeFilter == filter)
        }
    }

    private func filterChipLabel(label: String, isActive: Bool) -> some View {
        Text(label)
            .font(.subheadline.weight(isActive ? .semibold : .regular))
            .foregroundColor(isActive
                ? themeManager.current.backgroundColor
                : themeManager.current.labelColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive
                        ? themeManager.current.accentColor
                        : themeManager.current.cellSecondaryColor)
            )
    }
}
