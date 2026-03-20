import SwiftUI

struct EntryComposeView: View {
    @StateObject private var viewModel: EntryComposeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    init(topicLink: String) {
        _viewModel = StateObject(wrappedValue: EntryComposeViewModel(topicLink: topicLink))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.content)
                .padding(8)
                .background(themeManager.current.backgroundColor)
                .foregroundColor(themeManager.current.labelColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.current.accentColor, lineWidth: 0.5)
                )
                .padding()

            HStack(spacing: 16) {
                FormatButton(title: L10n.Compose.bkz) {
                    promptInsert(type: .bkz)
                }
                FormatButton(title: L10n.Compose.hede) {
                    promptInsert(type: .hede)
                }
                FormatButton(title: L10n.Compose.star) {
                    promptInsert(type: .hidden)
                }
                FormatButton(title: L10n.Compose.spoiler) {
                    promptInsert(type: .spoiler)
                }
                FormatButton(title: L10n.Compose.link) {
                    promptInsert(type: .link)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle(viewModel.topicTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.Entry.send) {
                    Task {
                        await viewModel.submit()
                        if viewModel.isSubmitted { dismiss() }
                    }
                }
                .foregroundColor(themeManager.current.accentColor)
            }
        }
        .background(themeManager.current.backgroundColor)
        .task { await viewModel.loadForm() }
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
    }

    private enum InsertType { case bkz, hede, hidden, spoiler, link }

    private func promptInsert(type: InsertType) {
        // Simple insertion - a sheet-based prompt would be better UX
        switch type {
        case .bkz: viewModel.insertBkz("")
        case .hede: viewModel.insertHede("")
        case .hidden: viewModel.content += "`:`"
        case .spoiler: viewModel.insertSpoiler("")
        case .link: viewModel.insertLink("http://")
        }
    }
}

private struct FormatButton: View {
    let title: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(title, action: action)
            .font(.caption)
            .foregroundColor(themeManager.current.accentColor)
    }
}
