import SwiftUI
import UIKit

struct EntryComposeView: View {
    @StateObject private var viewModel: EntryComposeViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var editorIsFirstResponder = false
    @State private var activePrompt: ComposeFormatKind?

    init(topicLink: String) {
        _viewModel = StateObject(wrappedValue: EntryComposeViewModel(topicLink: topicLink))
    }

    var body: some View {
        VStack(spacing: 0) {
            composeStatus
            editor
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            formatBar
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(themeManager.current.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("geri")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(viewModel.topicTitle.isEmpty ? "entry yaz" : viewModel.topicTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.current.labelColor)
                        .lineLimit(1)
                    Text("yeni entry")
                        .font(.caption2)
                        .foregroundColor(themeManager.current.dateColor)
                }
                .frame(maxWidth: UIScreen.main.bounds.width - 180)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.submit()
                        if viewModel.isSubmitted { dismiss() }
                    }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(L10n.Entry.send)
                                .font(.subheadline.bold())
                        }
                    }
                    .frame(minWidth: 54, minHeight: 44)
                }
                .disabled(!viewModel.canSubmit)
                .foregroundColor(
                    viewModel.canSubmit
                        ? themeManager.current.accentColor
                        : themeManager.current.dateColor
                )
            }
        }
        .sheet(item: $activePrompt) { kind in
            EntryFormatPromptSheet(kind: kind) { value in
                insert(kind.replacement(for: value))
                activePrompt = nil
                editorIsFirstResponder = true
            }
            .presentationDetents([.height(230)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "bir şey ters gitti",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            if !viewModel.isFormReady {
                Button("tekrar dene") {
                    Task { await viewModel.loadForm() }
                }
            }
            Button("tamam", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "bilinmeyen hata")
        }
        .task {
            selection = NSRange(location: (viewModel.content as NSString).length, length: 0)
            editorIsFirstResponder = true
            await viewModel.loadForm()
        }
    }

    private var composeStatus: some View {
        HStack(spacing: 8) {
            Group {
                if viewModel.isLoadingForm {
                    ProgressView()
                        .controlSize(.small)
                    Text("başlık hazırlanıyor")
                } else if viewModel.isFormReady {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.current.accentColor)
                    Text(viewModel.lastDraftSavedAt == nil ? "yazmaya hazır" : "taslak kaydedildi")
                } else {
                    Image(systemName: "arrow.clockwise.circle")
                    Text("yeniden yüklemek için dokun")
                }
            }
            .font(.caption)
            .foregroundColor(themeManager.current.dateColor)

            Spacer()

            Text("\((viewModel.content as NSString).length) karakter")
                .font(.caption.monospacedDigit())
                .foregroundColor(themeManager.current.dateColor)
        }
        .frame(minHeight: 36)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isFormReady, !viewModel.isLoadingForm else { return }
            Task { await viewModel.loadForm() }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeManager.current.cellPrimaryColor)

            ComposeTextEditor(
                text: $viewModel.content,
                selection: $selection,
                isFirstResponder: $editorIsFirstResponder,
                textColor: UIColor(themeManager.current.entryTextColor),
                tintColor: UIColor(themeManager.current.accentColor)
            )

            if viewModel.content.isEmpty {
                Text("aklındakini yaz...")
                    .font(.body)
                    .foregroundColor(themeManager.current.dateColor.opacity(0.8))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(themeManager.current.separatorColor.opacity(0.45), lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var formatBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(themeManager.current.separatorColor.opacity(0.6))

            HStack(spacing: 4) {
                ForEach(ComposeFormatKind.allCases) { kind in
                    Button {
                        apply(kind)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: kind.symbol)
                                .font(.body.weight(.medium))
                            Text(kind.shortTitle)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .contentShape(Rectangle())
                    }
                    .foregroundColor(themeManager.current.accentColor)
                    .accessibilityLabel(kind.title)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(themeManager.current.cellPrimaryColor)
    }

    private func apply(_ kind: ComposeFormatKind) {
        if let selectedText {
            insert(kind.replacement(for: selectedText))
            editorIsFirstResponder = true
        } else {
            editorIsFirstResponder = false
            activePrompt = kind
        }
    }

    private func insert(_ replacement: String) {
        selection = viewModel.insert(replacement, at: selection)
    }

    private var selectedText: String? {
        let source = viewModel.content as NSString
        guard selection.location != NSNotFound,
              selection.location >= 0,
              selection.length > 0,
              selection.location <= source.length,
              selection.length <= source.length - selection.location else {
            return nil
        }
        return source.substring(with: selection)
    }
}

private enum ComposeFormatKind: String, CaseIterable, Identifiable {
    case bkz, hede, hidden, spoiler, link

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bkz: return "başlığa bakınız"
        case .hede: return "yazar bağlantısı"
        case .hidden: return "gizli metin"
        case .spoiler: return "spoiler"
        case .link: return "bağlantı"
        }
    }

    var shortTitle: String {
        switch self {
        case .bkz: return "bkz"
        case .hede: return "hede"
        case .hidden: return "gizli"
        case .spoiler: return "spoiler"
        case .link: return "link"
        }
    }

    var symbol: String {
        switch self {
        case .bkz: return "text.magnifyingglass"
        case .hede: return "person.crop.circle"
        case .hidden: return "eye.slash"
        case .spoiler: return "exclamationmark.triangle"
        case .link: return "link"
        }
    }

    var placeholder: String {
        switch self {
        case .bkz: return "başlık"
        case .hede: return "yazar adı"
        case .hidden: return "gizlenecek metin"
        case .spoiler: return "spoiler içeriği"
        case .link: return "https://..."
        }
    }

    func replacement(for text: String) -> String {
        switch self {
        case .bkz: return EntryFormatting.bkz(text)
        case .hede: return EntryFormatting.hede(text)
        case .hidden: return EntryFormatting.hidden(text)
        case .spoiler: return EntryFormatting.spoiler(text)
        case .link: return EntryFormatting.link(text)
        }
    }
}

private struct EntryFormatPromptSheet: View {
    let kind: ComposeFormatKind
    let onInsert: (String) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var value: String
    @FocusState private var isFocused: Bool

    init(kind: ComposeFormatKind, onInsert: @escaping (String) -> Void) {
        self.kind = kind
        self.onInsert = onInsert
        _value = State(initialValue: kind == .link ? "https://" : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(kind.title, systemImage: kind.symbol)
                    .font(.headline)
                    .foregroundColor(themeManager.current.labelColor)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(themeManager.current.dateColor)
                .accessibilityLabel("kapat")
            }

            TextField(kind.placeholder, text: $value, axis: .vertical)
                .focused($isFocused)
                .textInputAutocapitalization(kind == .link ? .never : .sentences)
                .autocorrectionDisabled(kind == .link)
                .keyboardType(kind == .link ? .URL : .default)
                .submitLabel(.done)
                .padding(12)
                .background(themeManager.current.cellSecondaryColor, in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(themeManager.current.labelColor)
                .onSubmit { submit() }

            Button {
                submit()
            } label: {
                Text("ekle")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.current.accentColor)
            .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(20)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .task { isFocused = true }
    }

    private func submit() {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onInsert(value)
    }
}

private struct ComposeTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var isFirstResponder: Bool
    let textColor: UIColor
    let tintColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        textView.textContainer.lineFragmentPadding = 0
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        textView.text = text
        textView.selectedRange = selection
        textView.textColor = textColor
        textView.tintColor = tintColor
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.textColor = textColor
        textView.tintColor = tintColor

        if textView.text != text {
            textView.text = text
        }

        let length = (text as NSString).length
        let location = min(max(selection.location, 0), length)
        let safeSelection = NSRange(
            location: location,
            length: min(max(selection.length, 0), length - location)
        )
        if textView.selectedRange != safeSelection {
            textView.selectedRange = safeSelection
        }

        if isFirstResponder, !textView.isFirstResponder {
            DispatchQueue.main.async { textView.becomeFirstResponder() }
        } else if !isFirstResponder, textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposeTextEditor

        init(parent: ComposeTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selection = textView.selectedRange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard parent.selection != textView.selectedRange else { return }
            parent.selection = textView.selectedRange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFirstResponder = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFirstResponder = false
        }
    }
}
