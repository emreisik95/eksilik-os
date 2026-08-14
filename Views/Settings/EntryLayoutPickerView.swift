import SwiftUI
import UIKit

struct EntryLayoutPickerView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var themeManager: ThemeManager

    private let columns = [
        GridItem(.adaptive(minimum: 154), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewSection

                Text("düzenler")
                    .font(.headline)
                    .foregroundColor(themeManager.current.labelColor)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(EntryLayoutStyle.allCases) { style in
                        styleButton(style)
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("entry görünümü")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("canlı önizleme", systemImage: "eye.fill")
                    .font(.headline)
                    .foregroundColor(themeManager.current.labelColor)

                Spacer()

                Text(preferences.entryLayoutStyle.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(themeManager.current.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        themeManager.current.accentColor.opacity(0.12),
                        in: Capsule()
                    )
            }

            EntryLayoutPreview(style: preferences.entryLayoutStyle)
                .id(preferences.entryLayoutStyle.id)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .animation(.easeInOut(duration: 0.22), value: preferences.entryLayoutStyle)
    }

    private func styleButton(_ style: EntryLayoutStyle) -> some View {
        let isSelected = preferences.entryLayoutStyle == style

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                preferences.entryLayoutStyle = style
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: style.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(isSelected
                            ? themeManager.current.backgroundColor
                            : themeManager.current.accentColor)
                        .frame(width: 30, height: 30)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected
                            ? themeManager.current.backgroundColor
                            : themeManager.current.dateColor.opacity(0.45))
                }

                Text(style.name)
                    .font(.body.weight(.bold))
                    .foregroundColor(isSelected
                        ? themeManager.current.backgroundColor
                        : themeManager.current.labelColor)

                Text(style.summary)
                    .font(.caption)
                    .foregroundColor(isSelected
                        ? themeManager.current.backgroundColor.opacity(0.76)
                        : themeManager.current.dateColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
            .padding(14)
            .background(
                isSelected
                    ? themeManager.current.accentColor
                    : themeManager.current.cellPrimaryColor,
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.name), \(style.summary)")
        .accessibilityValue(isSelected ? "seçili" : "")
    }
}

private struct EntryLayoutPreview: View {
    let style: EntryLayoutStyle

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @StateObject private var navigation = NavigationCoordinator()

    private var sampleEntry: Entry {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(max(3, preferences.selectedFontSize / 4))
        let font = UIFont(
            name: preferences.selectedFont,
            size: CGFloat(preferences.selectedFontSize)
        ) ?? .systemFont(ofSize: CGFloat(preferences.selectedFontSize))
        let sample = "adam 4 kişiyi paketledi. 38 yaşında dünya kupasında yapıyor bunu."
        let attributed = NSAttributedString(
            string: sample,
            attributes: [
                .font: font,
                .foregroundColor: UIColor(themeManager.current.entryTextColor),
                .paragraphStyle: paragraphStyle,
            ]
        )

        return Entry(
            id: "185088056",
            contentHTML: sample,
            author: Author(id: "preview-author", nick: "vapors", avatarURL: nil),
            date: "15.07.2026 22:38",
            favoriteCount: 5,
            isFavorited: false,
            voteState: .none,
            authorId: "preview-author",
            imageURLs: [],
            parsedContent: attributed
        )
    }

    var body: some View {
        EntryRowView(
            entry: sampleEntry,
            isEven: true,
            styleOverride: style,
            onFavorite: {},
            onUpvote: {},
            onDownvote: {},
            onOpenImages: { _, _ in }
        )
        .environmentObject(navigation)
        .allowsHitTesting(false)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(themeManager.current.separatorColor.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(style.name) canlı entry önizlemesi")
    }
}
