import SwiftUI
import UIKit

struct ReadingFontPickerView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var themeManager: ThemeManager

    static let sampleParagraph = """
    sabah çayını demledim, gündeme bir göz attım. (bkz: pazartesi sendromu) \
    şehir uyanırken ığdır'dan iğneada'ya herkes aynı başlığa entry giriyor.
    """

    private var fontSize: CGFloat { CGFloat(preferences.selectedFontSize) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("entry metni, başlıklar ve entry listesi bu yazı tipiyle gösterilir. "
                    + "boyutu yazı boyutu ayarı belirler.")
                    .settingsFont(baseSize: 13)
                    .foregroundColor(themeManager.current.dateColor)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(ReadingFont.allCases) { font in
                    fontCard(font)
                }

                Text("atkinson hyperlegible next, source serif 4, ibm plex sans ve jetbrains mono "
                    + "sil open font license 1.1 ile dağıtılır; lisans metinleri uygulamayla birlikte gelir.")
                    .settingsFont(baseSize: 11)
                    .foregroundColor(themeManager.current.dateColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("okuma yazı tipi")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: preferences.readingFont)
    }

    private func fontCard(_ font: ReadingFont) -> some View {
        let isSelected = preferences.readingFont == font

        return Button {
            preferences.readingFont = font
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(font.name)
                            .settingsFont(baseSize: 17, weight: .semibold)
                            .foregroundColor(themeManager.current.labelColor)
                        Text(font.summary)
                            .settingsFont(baseSize: 12)
                            .foregroundColor(themeManager.current.dateColor)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected
                            ? themeManager.current.accentColor
                            : themeManager.current.dateColor.opacity(0.45))
                }

                sample(font)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? themeManager.current.accentColor
                            : themeManager.current.separatorColor.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(font.name), \(font.summary)")
        .accessibilityValue(isSelected ? "seçili" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func sample(_ font: ReadingFont) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.sampleParagraph)
                .font(font.font(size: fontSize))
                .foregroundColor(themeManager.current.entryTextColor)
                .lineSpacing(CGFloat(max(3, preferences.selectedFontSize / 4)))
                .fixedSize(horizontal: false, vertical: true)

            traitsLine(font)
        }
        .foregroundColor(themeManager.current.entryTextColor)
    }

    /// Bold and italic come from the same face lookup the entry renderer uses.
    private func traitsLine(_ font: ReadingFont) -> Text {
        let regular = font.font(size: fontSize)
        let bold = Font(font.uiFont(size: fontSize, bold: true) as CTFont)
        let italic = Font(font.uiFont(size: fontSize, italic: true) as CTFont)
        let link = Text("link").font(regular).foregroundColor(themeManager.current.linkColor)
        return Text("kalın").font(bold)
            + Text(", ").font(regular)
            + Text("eğik").font(italic)
            + Text(" ve ").font(regular)
            + link
    }
}
