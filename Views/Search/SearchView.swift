import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                searchHeader
                Divider().overlay(themeManager.current.separatorColor)
                stateContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(L10n.Search.title)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
            .task { await viewModel.loadChannels() }
            .onChange(of: viewModel.query) { _ in viewModel.search() }
        }
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSearchFocused ? themeManager.current.accentColor : .secondary)

                    TextField(L10n.Search.prompt, text: $viewModel.query)
                        .focused($isSearchFocused)
                        .font(.body)
                        .foregroundColor(themeManager.current.labelColor)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { openResolvedQuery() }

                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 19))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("aramayı temizle")
                    }
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 54)
                .background(themeManager.current.cellPrimaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSearchFocused ? themeManager.current.accentColor : themeManager.current.separatorColor.opacity(0.45),
                            lineWidth: isSearchFocused ? 1.5 : 1
                        )
                }

                if isSearchFocused {
                    Button("vazgeç") {
                        isSearchFocused = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.current.accentColor)
                    .frame(minHeight: 44)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }

            Text("başlık adı, @yazar veya #entry numarası yaz")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .animation(.easeInOut(duration: 0.18), value: isSearchFocused)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.presentationState {
        case .discovery:
            if viewModel.isLoadingChannels && viewModel.channels.isEmpty {
                SearchResultsSkeletonView()
            } else {
                discoveryContent
            }
        case .needsMoreCharacters:
            searchMessage(
                icon: "text.cursor",
                title: "bir harf daha yaz",
                detail: "arama sonuçları en az iki karakterden sonra görünür"
            )
        case .loading:
            SearchResultsSkeletonView()
        case .results:
            resultsContent
        case .empty:
            searchMessage(
                icon: "magnifyingglass",
                title: "sonuç bulamadık",
                detail: "farklı bir yazım dene veya @ ve # işaretlerini kullanmadan ara"
            )
        case .failure:
            searchMessage(
                icon: "wifi.exclamationmark",
                title: "arama tamamlanamadı",
                detail: "bağlantıyı kontrol edip yeniden deneyebilirsin",
                actionTitle: L10n.Common.retry,
                action: viewModel.search
            )
        }
    }

    private var discoveryContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                discoveryCard

                if !viewModel.channels.isEmpty {
                    sectionHeader(title: "kanalları keşfet", count: viewModel.channels.count)

                    ForEach(viewModel.channels) { channel in
                        channelRow(channel)
                    }
                } else if viewModel.channelError != nil {
                    compactRetryCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var discoveryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(themeManager.current.accentColor)
                .frame(width: 52, height: 52)
                .background(themeManager.current.accentColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 5) {
                Text("sözlükte ne arıyorsun?")
                    .font(.title3.bold())
                    .foregroundColor(themeManager.current.labelColor)
                Text("başlıklara git, yazar profillerini aç veya doğrudan bir entry bul")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                searchHint("başlık adı", icon: "text.book.closed")
                searchHint("@yazar", icon: "person")
                searchHint("#123", icon: "number")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.current.cellPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func searchHint(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundColor(themeManager.current.labelColor)
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
            .background(themeManager.current.backgroundColor.opacity(0.7))
            .clipShape(Capsule())
    }

    private var resultsContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if !viewModel.titles.isEmpty {
                    sectionHeader(title: L10n.Search.topics, count: viewModel.titles.count)

                    ForEach(viewModel.titles, id: \.self) { title in
                        NavigationLink(value: Route.entryList(
                            link: title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title,
                            title: title
                        )) {
                            resultRow(title: title, subtitle: "başlığa git", icon: "text.book.closed.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !viewModel.nicks.isEmpty {
                    sectionHeader(title: L10n.Search.authors, count: viewModel.nicks.count)
                        .padding(.top, viewModel.titles.isEmpty ? 0 : 12)

                    ForEach(viewModel.nicks, id: \.self) { nick in
                        NavigationLink(value: Route.profile(username: nick)) {
                            resultRow(title: nick, subtitle: "profili aç", icon: "person.crop.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func resultRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.current.accentColor)
                .frame(width: 44, height: 44)
                .background(themeManager.current.accentColor.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(themeManager.current.labelColor)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(themeManager.current.cellPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private func channelRow(_ channel: Channel) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: Route.topicList(link: channel.link, title: channel.name)) {
                HStack(spacing: 12) {
                    Text(channel.name.prefix(1) == "#" ? String(channel.name.prefix(2)) : "#")
                        .font(.headline)
                        .foregroundColor(themeManager.current.accentColor)
                        .frame(width: 44, height: 44)
                        .background(themeManager.current.accentColor.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 13))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(channel.name)
                            .font(.body.weight(.semibold))
                            .foregroundColor(themeManager.current.labelColor)
                        if !channel.description.isEmpty {
                            Text(channel.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if session.isLoggedIn {
                Button {
                    Task { await viewModel.toggleFollow(channel: channel) }
                } label: {
                    Text(channel.isFollowed ? "takipte" : "takip et")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(channel.isFollowed ? themeManager.current.accentColor : themeManager.current.labelColor)
                        .padding(.horizontal, 11)
                        .frame(minHeight: 44)
                        .background(
                            channel.isFollowed
                            ? themeManager.current.accentColor.opacity(0.12)
                            : themeManager.current.backgroundColor.opacity(0.7)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(themeManager.current.cellPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.current.labelColor)
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.accentColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(themeManager.current.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var compactRetryCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.clockwise")
                .font(.title2)
                .foregroundColor(themeManager.current.accentColor)
            Text("kanallar yüklenemedi")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.current.labelColor)
            Button(L10n.Common.retry) {
                Task { await viewModel.loadChannels() }
            }
            .buttonStyle(.bordered)
            .tint(themeManager.current.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(themeManager.current.cellPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func searchMessage(
        icon: String,
        title: String,
        detail: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(themeManager.current.accentColor)
                .frame(width: 64, height: 64)
                .background(themeManager.current.accentColor.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text(title)
                .font(.title3.bold())
                .foregroundColor(themeManager.current.labelColor)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.current.accentColor)
                    .controlSize(.large)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openResolvedQuery() {
        guard let route = viewModel.resolveQuery() else { return }
        isSearchFocused = false
        navigationPath.append(route)
    }
}
