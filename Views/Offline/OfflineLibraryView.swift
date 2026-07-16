import SwiftUI

struct OfflineLibraryView: View {
    @StateObject private var viewModel = OfflineLibraryViewModel()
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.items.isEmpty {
                    ErrorView(message: error) { Task { await viewModel.load() } }
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 42))
                            .foregroundColor(.gray)
                        Text("indirilen başlık yok")
                            .font(.headline)
                        Text("bir başlıktaki indirme düğmesinden normal veya şükela entry'leri kaydedebilirsin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            offlineRow(item)
                                .listRowBackground(themeManager.current.cellPrimaryColor)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(item.topic) }
                                    } label: {
                                        Label("sil", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.load() }
                }
            }
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(L10n.Offline.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: .offlineTopicsDidChange)) { _ in
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private func offlineRow(_ item: OfflineLibraryItem) -> some View {
        HStack(spacing: 12) {
            if item.topic.isReadable {
                NavigationLink {
                    OfflineTopicView(topicID: item.topic.id, title: item.topic.title)
                } label: {
                    rowContent(item)
                }
            } else {
                rowContent(item)
            }

            Menu {
                if item.topic.status.isActive {
                    Button {
                        Task { await viewModel.cancel(item.topic) }
                    } label: {
                        Label("iptal et", systemImage: "xmark.circle")
                    }
                }
                if item.topic.status == .failed || item.topic.status == .cancelled {
                    Button {
                        Task { await viewModel.retry(item.topic) }
                    } label: {
                        Label(L10n.Common.retry, systemImage: "arrow.clockwise")
                    }
                }
                Button(role: .destructive) {
                    Task { await viewModel.delete(item.topic) }
                } label: {
                    Label("sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(themeManager.current.accentColor)
                    .frame(width: 34, height: 44)
            }
            .accessibilityLabel("\(item.topic.title) indirme seçenekleri")
        }
    }

    private func rowContent(_ item: OfflineLibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(item.topic.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(2)
                Spacer()
                Text(item.topic.contentMode.title)
                    .font(.caption2)
                    .foregroundColor(themeManager.current.accentColor)
            }

            ProgressView(value: item.topic.progress)
                .tint(statusColor(item.topic.status))

            HStack(spacing: 8) {
                Text(statusText(item.topic))
                Text(ByteCountFormatter.string(fromByteCount: item.storageSize, countStyle: .file))
                Spacer()
                Text(item.topic.updatedAt, style: .relative)
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if let error = item.topic.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 5)
    }

    private func statusText(_ topic: OfflineTopic) -> String {
        switch topic.status {
        case .queued: return "sırada"
        case .downloading: return "\(topic.completedPages.count)/\(topic.plannedPages.count) sayfa"
        case .completed: return "\(topic.completedPages.count) sayfa hazır"
        case .failed: return "indirme başarısız"
        case .cancelled: return "iptal edildi"
        }
    }

    private func statusColor(_ status: OfflineDownloadStatus) -> Color {
        switch status {
        case .failed: return .red
        case .cancelled: return .gray
        default: return themeManager.current.accentColor
        }
    }
}
