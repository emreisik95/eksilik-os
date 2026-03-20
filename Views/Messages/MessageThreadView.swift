import SwiftUI

struct MessageThreadView: View {
    @StateObject private var viewModel: MessageThreadViewModel
    @EnvironmentObject var themeManager: ThemeManager

    init(link: String, title: String) {
        _viewModel = StateObject(wrappedValue: MessageThreadViewModel(link: link, title: title))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                LoadingView()
            } else if viewModel.messages.isEmpty {
                EmptyStateView(message: L10n.Message.noMessages)
            } else {
                List(viewModel.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(message.sender)
                                .font(.subheadline.bold())
                                .foregroundColor(themeManager.current.accentColor)
                            Spacer()
                            Text(message.date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Text(message.contentHTML.strippingHTML)
                            .font(.subheadline)
                            .foregroundColor(themeManager.current.entryTextColor)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(viewModel.threadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Route.composeMessage(to: viewModel.threadTitle, subject: "")) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
            }
        }
        .background(themeManager.current.backgroundColor)
        .task { await viewModel.loadMessages() }
        .refreshable { await viewModel.loadMessages() }
    }
}
