import SwiftUI
import UIKit

struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var session: SessionManager

    @State private var editorRequest: ThemeEditorRequest?
    @State private var isImporting = false
    @State private var importedTheme: CustomTheme?
    @State private var renaming: CustomTheme?
    @State private var renameText = ""
    @State private var deleting: CustomTheme?

    private var metrics: SettingsLayoutMetrics {
        SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
    }

    var body: some View {
        let scale = CGFloat(metrics.scale)

        ScrollView {
            VStack(alignment: .leading, spacing: CGFloat(metrics.sectionSpacing)) {
                customSection
                builtInSection
            }
            .padding(.horizontal, 16 * scale)
            .padding(.top, 8 * scale)
            .padding(.bottom, 32 * scale)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle(L10n.Settings.theme)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorRequest) { request in
            NavigationStack {
                ThemeEditorView(theme: request.theme, isNew: request.isNew)
            }
            .environmentObject(themeManager)
            .environmentObject(preferences)
            .environmentObject(session)
            .preferredColorScheme(themeManager.current.colorScheme)
        }
        .sheet(isPresented: $isImporting, onDismiss: openImportedTheme) {
            NavigationStack {
                ThemeImportView { theme in
                    importedTheme = theme
                    isImporting = false
                }
            }
            .environmentObject(themeManager)
            .environmentObject(preferences)
            .preferredColorScheme(themeManager.current.colorScheme)
        }
        .alert("yeniden adlandır", isPresented: isRenamingBinding, presenting: renaming) { theme in
            TextField("tema adı", text: $renameText)
            Button("kaydet") {
                themeManager.renameCustomTheme(id: theme.id, to: renameText)
            }
            Button("vazgeç", role: .cancel) {}
        } message: { _ in
            Text("en fazla \(CustomTheme.maximumNameLength) karakter.")
        }
        .confirmationDialog(
            "tema silinsin mi?",
            isPresented: isDeletingBinding,
            titleVisibility: .visible,
            presenting: deleting
        ) { theme in
            Button("\(theme.name) temasını sil", role: .destructive) {
                themeManager.deleteCustomTheme(id: theme.id)
            }
            Button("vazgeç", role: .cancel) {}
        } message: { theme in
            Text(themeManager.isSelected(.custom(theme.id))
                ? "bu tema şu an kullanılıyor; silinince \(theme.baseTheme.name) temasına dönülür."
                : "bu işlem geri alınamaz.")
        }
    }

    // MARK: - Sections

    private var customSection: some View {
        SettingsCardSection(
            title: "kendi temaların",
            systemImage: "paintbrush.pointed",
            footer: "kendi temaların yalnızca bu cihazda saklanır; başkasıyla paylaşmak için kodunu gönder."
        ) {
            Button(action: createFromCurrent) {
                SettingsNavigationRow(
                    icon: "plus",
                    title: "kendi temanı oluştur",
                    subtitle: "\(themeManager.currentName) renkleriyle başlar",
                    isAccented: true
                )
            }
            .buttonStyle(.plain)

            SettingsCardDivider()

            Button {
                isImporting = true
            } label: {
                SettingsNavigationRow(icon: "square.and.arrow.down", title: "kod ile içe aktar")
            }
            .buttonStyle(.plain)

            ForEach(themeManager.customThemes) { theme in
                SettingsCardDivider()
                customRow(theme)
            }
        }
    }

    private var builtInSection: some View {
        SettingsCardSection(title: "hazır temalar", systemImage: "square.grid.2x2") {
            ForEach(AppTheme.allCases) { theme in
                if theme != AppTheme.allCases.first {
                    SettingsCardDivider()
                }
                Button {
                    themeManager.setTheme(theme)
                } label: {
                    ThemeChoiceRow(
                        palette: theme.palette,
                        name: theme.name,
                        subtitle: theme.summary,
                        isSelected: themeManager.isSelected(.builtIn(theme))
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        editorRequest = ThemeEditorRequest(theme: themeManager.makeDraft(from: theme), isNew: true)
                    } label: {
                        Label("bundan tema oluştur", systemImage: "paintbrush.pointed")
                    }
                }
            }
        }
    }

    private func customRow(_ theme: CustomTheme) -> some View {
        HStack(spacing: 0) {
            Button {
                themeManager.select(.custom(theme.id))
            } label: {
                ThemeChoiceRow(
                    palette: theme.palette,
                    name: theme.name,
                    subtitle: "temel: \(theme.baseTheme.name)",
                    isSelected: themeManager.isSelected(.custom(theme.id))
                )
            }
            .buttonStyle(.plain)
            .contextMenu { actions(for: theme) }

            Menu {
                actions(for: theme)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(themeManager.current.accentColor)
                    .frame(width: CGFloat(metrics.controlMinimumSize), height: CGFloat(metrics.controlMinimumSize))
                    .contentShape(Rectangle())
            }
            .padding(.trailing, CGFloat(metrics.horizontalPadding) - 8)
            .accessibilityLabel("\(theme.name) seçenekleri")
        }
    }

    @ViewBuilder
    private func actions(for theme: CustomTheme) -> some View {
        Button {
            editorRequest = ThemeEditorRequest(theme: theme, isNew: false)
        } label: {
            Label("düzenle", systemImage: "slider.horizontal.3")
        }
        Button {
            themeManager.duplicateCustomTheme(id: theme.id)
        } label: {
            Label("çoğalt", systemImage: "plus.square.on.square")
        }
        Button {
            renameText = theme.name
            renaming = theme
        } label: {
            Label("yeniden adlandır", systemImage: "pencil")
        }
        Button {
            UIPasteboard.general.string = ThemeShareCode.encode(theme)
        } label: {
            Label("kodu kopyala", systemImage: "doc.on.doc")
        }
        Button(role: .destructive) {
            deleting = theme
        } label: {
            Label("sil", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private var isRenamingBinding: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private var isDeletingBinding: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    /// Starts from whatever is on screen now, so tweaking the current look is one tap away.
    private func createFromCurrent() {
        let base: AppTheme
        switch themeManager.selection {
        case .builtIn(let theme):
            base = theme
        case .custom(let id):
            base = themeManager.customThemes.first { $0.id == id }?.baseTheme ?? .dark
        }
        var draft = themeManager.makeDraft(from: base)
        draft.palette = themeManager.current
        editorRequest = ThemeEditorRequest(theme: draft, isNew: true)
    }

    /// The import sheet hands its theme over here, after it has gone, so the editor can take its place.
    private func openImportedTheme() {
        guard let theme = importedTheme else { return }
        importedTheme = nil
        editorRequest = ThemeEditorRequest(theme: theme, isNew: true)
    }
}

struct ThemeEditorRequest: Identifiable {
    let theme: CustomTheme
    let isNew: Bool

    var id: UUID { theme.id }
}
