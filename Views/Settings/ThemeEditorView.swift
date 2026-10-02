import SwiftUI
import UIKit

/// Creates or edits a custom theme. The draft only reaches `ThemeManager` on save; until then the
/// preview renders it through its own in-memory manager.
struct ThemeEditorView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private let original: CustomTheme
    private let isNew: Bool

    @State private var draft: CustomTheme
    @State private var highlighted: Set<ThemeTokenKey> = []
    @State private var pendingBase: AppTheme?
    @State private var isConfirmingReset = false
    @State private var isConfirmingDiscard = false
    @State private var isKeyboardVisible = false
    @State private var didCopyCode = false

    init(theme: CustomTheme, isNew: Bool) {
        original = theme
        self.isNew = isNew
        _draft = State(initialValue: theme)
    }

    private var hasChanges: Bool { isNew || draft != original }

    private var paletteDiffersFromBase: Bool {
        draft.palette != draft.baseTheme.palette
    }

    /// The preview gives up room while the keyboard is up so the hex field stays visible.
    private var previewHeight: CGFloat {
        isKeyboardVisible ? 150 : min(300, UIScreen.main.bounds.height * 0.38)
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ThemeEditorPreview(
                    palette: draft.palette,
                    highlighted: highlighted,
                    highlightColor: themeManager.current.accentColor,
                    onSelect: { keys in focus(keys, proxy: proxy) }
                )
                .frame(height: previewHeight)
                .clipped()

                Rectangle()
                    .fill(themeManager.current.separatorColor.opacity(0.4))
                    .frame(height: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        detailsSection
                        tokensSection
                        contrastSection(proxy: proxy)
                        shareSection
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle(isNew ? "yeni tema" : "temayı düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.current.navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(themeManager.current.accentColor)
        .toolbar { toolbarContent }
        .interactiveDismissDisabled(hasChanges)
        .confirmationDialog(
            isNew ? "tema kaydedilmedi" : "değişiklikler kaydedilmedi",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button(isNew ? "temayı at" : "değişiklikleri at", role: .destructive) { dismiss() }
            Button("düzenlemeye devam et", role: .cancel) {}
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) { isKeyboardVisible = false }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("vazgeç") {
                if hasChanges {
                    isConfirmingDiscard = true
                } else {
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("kaydet") { save() }
                .font(.body.weight(.semibold))
        }
    }
}

// MARK: - Sections

private extension ThemeEditorView {
    var detailsSection: some View {
        SettingsCardSection(
            title: "tema",
            systemImage: "paintpalette",
            footer: "görünüm; klavye, menüler ve sistem çubuklarının açık mı koyu mu olacağını belirler."
        ) {
            ThemeEditorFieldRow(title: "ad") {
                TextField("tema adı", text: nameBinding)
                    .settingsFont(baseSize: 16)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(themeManager.current.labelColor)
                    .submitLabel(.done)
            }
            SettingsCardDivider()
            ThemeEditorFieldRow(title: "görünüm") {
                Picker("görünüm", selection: $draft.palette.appearance) {
                    Text("açık").tag(ThemePalette.Appearance.light)
                    Text("koyu").tag(ThemePalette.Appearance.dark)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }
            SettingsCardDivider()
            baseMenu
            SettingsCardDivider()
            resetButton
        }
    }

    var baseMenu: some View {
        Menu {
            ForEach(AppTheme.allCases) { theme in
                Button(theme.name) { requestBase(theme) }
            }
        } label: {
            ThemeEditorFieldRow(title: "başlangıç") {
                HStack(spacing: 6) {
                    Text(draft.baseTheme.name)
                        .settingsFont(baseSize: 15)
                        .foregroundColor(themeManager.current.dateColor)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(themeManager.current.dateColor.opacity(0.65))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("başlangıç teması, \(draft.baseTheme.name)")
        .confirmationDialog(
            "başlangıç teması değişsin mi?",
            isPresented: pendingBaseBinding,
            titleVisibility: .visible,
            presenting: pendingBase
        ) { base in
            Button("\(base.name) renklerini kullan", role: .destructive) { apply(base: base) }
            Button("vazgeç", role: .cancel) {}
        } message: { _ in
            Text("yaptığın renk değişiklikleri kaybolur.")
        }
    }

    var resetButton: some View {
        Button {
            isConfirmingReset = true
        } label: {
            ThemeEditorFieldRow(
                title: "\(draft.baseTheme.name) renklerine sıfırla",
                systemImage: "arrow.counterclockwise"
            ) {
                EmptyView()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!paletteDiffersFromBase)
        .opacity(paletteDiffersFromBase ? 1 : 0.4)
        .confirmationDialog("renkler sıfırlansın mı?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("\(draft.baseTheme.name) renklerine dön", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) { draft.palette = draft.baseTheme.palette }
            }
            Button("vazgeç", role: .cancel) {}
        } message: {
            Text("yaptığın renk değişiklikleri kaybolur.")
        }
    }

    var tokensSection: some View {
        SettingsCardSection(
            title: "renkler",
            systemImage: "eyedropper",
            footer: "önizlemede bir öğeye dokununca kullandığı renkler burada işaretlenir."
        ) {
            ForEach(ThemeTokenKey.allCases) { key in
                if key != ThemeTokenKey.allCases.first {
                    SettingsCardDivider()
                }
                ThemeTokenRow(
                    key: key,
                    token: tokenBinding(key),
                    isHighlighted: highlighted.contains(key),
                    onFocus: { withAnimation(.easeInOut(duration: 0.2)) { highlighted = [key] } }
                )
                .id(key)
            }
        }
    }

    func contrastSection(proxy: ScrollViewProxy) -> some View {
        let checks = ThemeContrastPolicy.checks(for: draft.palette)
        return SettingsCardSection(
            title: "kontrast",
            systemImage: "circle.righthalf.filled",
            footer: "okunabilirlik için en az 4,5:1 önerilir (wcag aa). uyarılar kaydetmeye engel olmaz."
        ) {
            ForEach(checks, id: \.title) { check in
                if check.title != checks.first?.title {
                    SettingsCardDivider()
                }
                ThemeContrastRow(check: check, palette: draft.palette) {
                    focus([check.foreground, check.background], proxy: proxy)
                }
            }
        }
    }

    var shareSection: some View {
        let code = ThemeShareCode.encode(draft)
        return SettingsCardSection(
            title: "paylaş",
            systemImage: "square.and.arrow.up",
            footer: "kodu alan kişi tema ekranındaki \"kod ile içe aktar\" ile bu temayı ekleyebilir."
        ) {
            ShareLink(item: code) {
                ThemeEditorFieldRow(title: "kodu paylaş", systemImage: "square.and.arrow.up") {
                    EmptyView()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            SettingsCardDivider()
            Button {
                UIPasteboard.general.string = code
                didCopyCode = true
            } label: {
                ThemeEditorFieldRow(
                    title: didCopyCode ? "kopyalandı" : "kodu kopyala",
                    systemImage: didCopyCode ? "checkmark" : "doc.on.doc"
                ) {
                    EmptyView()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .task(id: didCopyCode) {
                guard didCopyCode else { return }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                didCopyCode = false
            }
        }
    }
}

// MARK: - Actions

private extension ThemeEditorView {
    var nameBinding: Binding<String> {
        Binding(
            get: { draft.name },
            set: { draft.name = String($0.prefix(CustomTheme.maximumNameLength)) }
        )
    }

    var pendingBaseBinding: Binding<Bool> {
        Binding(
            get: { pendingBase != nil },
            set: { if !$0 { pendingBase = nil } }
        )
    }

    func tokenBinding(_ key: ThemeTokenKey) -> Binding<ThemeColorToken> {
        Binding(
            get: { draft.palette[key] },
            set: { draft.palette[key] = $0 }
        )
    }

    /// Marks the tokens an element uses and brings the first of them into view.
    func focus(_ keys: [ThemeTokenKey], proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.25)) {
            highlighted = Set(keys)
            if let first = ThemeTokenKey.allCases.first(where: keys.contains) {
                proxy.scrollTo(first, anchor: .top)
            }
        }
    }

    func requestBase(_ base: AppTheme) {
        if paletteDiffersFromBase {
            pendingBase = base
        } else {
            apply(base: base)
        }
    }

    func apply(base: AppTheme) {
        withAnimation(.easeInOut(duration: 0.2)) {
            draft.baseTheme = base
            draft.palette = base.palette
        }
    }

    func save() {
        themeManager.saveCustomTheme(draft)
        themeManager.select(.custom(draft.id))
        dismiss()
    }
}
