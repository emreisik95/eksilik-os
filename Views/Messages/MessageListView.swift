import SwiftUI

struct MessageListView: View {
    @StateObject private var viewModel = MessageListViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if viewModel.isLoading && viewModel.threads.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.threads.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadMessages() }
                    }
                } else if viewModel.threads.isEmpty {
                    EmptyStateView(message: L10n.Message.noMessages)
                } else {
                    messageList
                }
            }

            if viewModel.pagination.totalPages > 1 {
                PaginationView(pagination: viewModel.pagination) { page in
                    Task { await viewModel.goToPage(page) }
                }
            }
        }
        .navigationTitle(L10n.Message.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Route.composeMessage(recipient: "", subject: "", threadID: nil)) {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel(L10n.Message.newMessage)
            }
        }
        .background(themeManager.current.backgroundColor)
        .task {
            guard viewModel.threads.isEmpty else { return }
            await viewModel.loadMessages()
        }
        .refreshable { await viewModel.loadMessages() }
    }

    private var messageList: some View {
        List(viewModel.threads) { thread in
            NavigationLink(value: Route.messageThread(link: thread.link, title: thread.username)) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(themeManager.current.accentColor.opacity(0.14))
                            .frame(width: 46, height: 46)
                        Text(String(thread.username.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(themeManager.current.accentColor)
                            .frame(width: 46, height: 46)
                        if thread.isUnread {
                            Circle()
                                .fill(themeManager.current.accentColor)
                                .frame(width: 11, height: 11)
                                .overlay(Circle().stroke(themeManager.current.cellPrimaryColor, lineWidth: 2))
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(thread.username)
                                .foregroundColor(themeManager.current.labelColor)
                                .font(.subheadline.weight(thread.isUnread ? .bold : .semibold))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(thread.date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Text(thread.preview.isEmpty ? L10n.Message.openConversation : thread.preview)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .lineLimit(2)

                        if !thread.messageCount.isEmpty {
                            Text("\(thread.messageCount) mesaj")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(themeManager.current.accentColor)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(themeManager.current.cellPrimaryColor)
            .accessibilityValue(thread.isUnread ? "okunmamış" : "")
        }
        .listStyle(.plain)
    }
}
