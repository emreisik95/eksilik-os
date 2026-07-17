import SwiftUI

struct DownloadOptionsView: View {
    let title: String
    let request: TopicRequest
    let totalPages: Int

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var contentMode: OfflineContentMode = .normal
    @State private var pageLimit: OfflinePageLimit = .fivePages
    @State private var isStarting = false
    @State private var error: String?

    private var resolvedPages: Int {
        OfflineDownloadPlanner.pages(for: pageLimit, totalPages: totalPages).count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("içerik") {
                    Picker("içerik", selection: $contentMode) {
                        ForEach(OfflineContentMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("kapsam") {
                    Picker("sayfalar", selection: $pageLimit) {
                        ForEach(OfflinePageLimit.allCases, id: \.self) { limit in
                            Text(limit.title).tag(limit)
                        }
                    }
                    Text("en fazla \(resolvedPages) sayfa; kesin sayı içerik türü kontrol edilince arka planda indirilecek")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Section {
                    Button {
                        startDownload()
                    } label: {
                        HStack {
                            Spacer()
                            if isStarting {
                                ProgressView()
                            } else {
                                Label("indirmeyi başlat", systemImage: "arrow.down.circle.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isStarting)
                    .accessibilityLabel("\(title) başlığını çevrimdışı okumak için indir")
                }
            }
            .navigationTitle("çevrimdışı indir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Entry.cancel) { dismiss() }
                }
            }
            .tint(themeManager.current.accentColor)
        }
    }

    private func startDownload() {
        isStarting = true
        error = nil
        Task {
            do {
                _ = try await OfflineDownloadManager.shared.startDownload(
                    title: title,
                    request: request,
                    contentMode: contentMode,
                    pageLimit: pageLimit
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
                isStarting = false
            }
        }
    }
}
