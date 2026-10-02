import SwiftUI

/// Paste box for an `eksilik-tema:` code. Validation runs as the text changes; a valid code opens
/// in the editor as a new theme, so nothing is saved until the person confirms it there.
struct ThemeImportView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss

    let onImport: (CustomTheme) -> Void

    @State private var code = ""
    @FocusState private var isEditorFocused: Bool

    init(onImport: @escaping (CustomTheme) -> Void) {
        self.onImport = onImport
    }

    private var result: Result<CustomTheme, ThemeShareCode.DecodeError>? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : ThemeShareCode.decode(trimmed)
    }

    private var importedTheme: CustomTheme? {
        if case .success(let theme) = result {
            return theme
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("arkadaşının gönderdiği \"\(ThemeShareCode.prefix)\" ile başlayan kodu buraya yapıştır.")
                    .settingsFont(baseSize: 13)
                    .foregroundColor(themeManager.current.dateColor)
                    .fixedSize(horizontal: false, vertical: true)

                codeEditor

                HStack {
                    PasteButton(payloadType: String.self) { strings in
                        DispatchQueue.main.async {
                            code = strings.first ?? ""
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.capsule)

                    Spacer()

                    if !code.isEmpty {
                        Button("temizle") { code = "" }
                            .settingsFont(baseSize: 15)
                    }
                }

                status
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("kod ile içe aktar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.current.navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(themeManager.current.accentColor)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("vazgeç") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("devam") {
                    if let importedTheme {
                        onImport(importedTheme)
                    }
                }
                .font(.body.weight(.semibold))
                .disabled(importedTheme == nil)
            }
        }
    }

    private var codeEditor: some View {
        TextEditor(text: $code)
            .focused($isEditorFocused)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(themeManager.current.labelColor)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 140)
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .accessibilityLabel("tema kodu")
    }

    private var borderColor: Color {
        switch result {
        case .failure:
            return Color(uiColor: .systemOrange)
        case .success:
            return themeManager.current.accentColor
        case nil:
            return themeManager.current.separatorColor.opacity(0.3)
        }
    }

    @ViewBuilder
    private var status: some View {
        switch result {
        case .failure(let error):
            Label(error.message, systemImage: "exclamationmark.triangle.fill")
                .settingsFont(baseSize: 14)
                .foregroundColor(Color(uiColor: .systemOrange))
                .fixedSize(horizontal: false, vertical: true)
        case .success(let theme):
            VStack(alignment: .leading, spacing: 8) {
                ThemeChoiceRow(
                    palette: theme.palette,
                    name: theme.name,
                    subtitle: "temel: \(theme.baseTheme.name)",
                    isSelected: false
                )
                .background(
                    themeManager.current.cellPrimaryColor,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                Text("devam edince tema düzenleyicide açılır; kaydedene kadar eklenmez.")
                    .settingsFont(baseSize: 12)
                    .foregroundColor(themeManager.current.dateColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case nil:
            EmptyView()
        }
    }
}
