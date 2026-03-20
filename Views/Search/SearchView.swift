import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.titles.isEmpty {
                    Section(L10n.Search.topics) {
                        ForEach(viewModel.titles, id: \.self) { title in
                            NavigationLink(value: Route.entryList(
                                link: title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title,
                                title: title
                            )) {
                                Text(title)
                                    .foregroundColor(themeManager.current.labelColor)
                            }
                        }
                    }
                }

                if !viewModel.nicks.isEmpty {
                    Section(L10n.Search.authors) {
                        ForEach(viewModel.nicks, id: \.self) { nick in
                            NavigationLink(value: Route.profile(username: nick)) {
                                Text(nick)
                                    .foregroundColor(themeManager.current.accentColor)
                            }
                        }
                    }
                }

                // Skeleton loading when channels loading
                if viewModel.query.isEmpty && viewModel.channels.isEmpty {
                    Section {
                        ForEach(0..<8, id: \.self) { _ in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.current.cellSecondaryColor)
                                    .frame(width: 100, height: 16)
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(themeManager.current.cellSecondaryColor)
                                    .frame(width: 60, height: 14)
                            }
                            .padding(.vertical, 4)
                            .redacted(reason: .placeholder)
                        }
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                }

                // Show channels when search is empty
                if viewModel.query.isEmpty && !viewModel.channels.isEmpty {
                    Section("kanallar") {
                        ForEach(viewModel.channels) { channel in
                            HStack {
                                NavigationLink(value: Route.topicList(link: channel.link, title: channel.name)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(channel.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(themeManager.current.accentColor)
                                        if !channel.description.isEmpty {
                                            Text(channel.description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                if session.isLoggedIn {
                                    Button {
                                        Task { await viewModel.toggleFollow(channel: channel) }
                                    } label: {
                                        Text(channel.isFollowed ? "takipte" : "takip et")
                                            .font(.caption)
                                            .foregroundColor(channel.isFollowed ? themeManager.current.accentColor : .gray)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(channel.isFollowed ? themeManager.current.accentColor : .gray, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $viewModel.query, prompt: L10n.Search.prompt)
            .onSubmit(of: .search) {
                if let route = viewModel.resolveQuery() {
                    // Navigation handled by route
                }
            }
            .onChange(of: viewModel.query) { _ in viewModel.search() }
            .navigationTitle(L10n.Search.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
            .background(themeManager.current.backgroundColor)
            .task { await viewModel.loadChannels() }
        }
    }
}
