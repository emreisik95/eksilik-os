import SwiftUI

struct MessageListView: View {
    @StateObject private var viewModel = MessageListViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.threads.isEmpty {
                    LoadingView()
                } else if viewModel.threads.isEmpty {
                    EmptyStateView(message: L10n.Message.noMessages)
                } else {
                    List(viewModel.threads) { thread in
                        NavigationLink(value: Route.messageThread(link: thread.link, title: thread.username)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(thread.username)
                                        .foregroundColor(themeManager.current.accentColor)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(thread.messageCount)
                                        .font(.caption)
                                        .foregroundColor(themeManager.current.accentColor)
                                }
                                Text(thread.preview)
                                    .foregroundColor(themeManager.current.labelColor)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                Text(thread.date)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(themeManager.current.cellPrimaryColor)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L10n.Message.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.current.backgroundColor)
            .task { await viewModel.loadMessages() }
            .refreshable { await viewModel.loadMessages() }
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
    }
}
