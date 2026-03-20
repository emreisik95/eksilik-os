import SwiftUI

struct DebeView: View {
    @StateObject private var viewModel = DebeViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                LoadingView()
            } else if let error = viewModel.error, viewModel.entries.isEmpty {
                ErrorView(message: error) {
                    Task { await viewModel.loadDebe() }
                }
            } else {
                debeList
            }
        }
        .background(themeManager.current.backgroundColor)
        .task { await viewModel.loadDebe() }
        .refreshable { await viewModel.loadDebe() }
    }

    private var debeList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 0) {
                        // Title row - tap to expand/collapse
                        Button {
                            Task { await viewModel.toggle(entry) }
                        } label: {
                            HStack {
                                Text(entry.topicTitle)
                                    .font(.system(size: CGFloat(preferences.selectedFontSize)))
                                    .foregroundColor(themeManager.current.labelColor)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: entry.isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        // Expanded content
                        if entry.isExpanded {
                            VStack(alignment: .leading, spacing: 8) {
                                if let content = entry.parsedContent {
                                    EntryTextView(attributedText: content)
                                } else {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }

                                if let author = entry.authorNick, !author.isEmpty {
                                    HStack {
                                        Text(author)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(themeManager.current.accentColor)
                                        Spacer()
                                        if let date = entry.date {
                                            Text(date)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }

                                // Navigate to full topic
                                NavigationLink(value: Route.entryById(id: entry.id)) {
                                    Text("basliga git →")
                                        .font(.caption)
                                        .foregroundColor(themeManager.current.accentColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }

                        Divider().overlay(themeManager.current.separatorColor)
                    }
                }
            }
        }
    }
}
