import SwiftUI

struct EntryLayoutPickerView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(EntryLayoutStyle.allCases) { style in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            preferences.entryLayoutStyle = style
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: style.systemImage)
                                    .frame(width: 24)
                                    .foregroundColor(themeManager.current.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(themeManager.current.labelColor)
                                    Text(style.summary)
                                        .font(.caption)
                                        .foregroundColor(themeManager.current.dateColor)
                                }

                                Spacer()

                                Image(systemName: preferences.entryLayoutStyle == style
                                    ? "checkmark.circle.fill"
                                    : "circle")
                                    .font(.title3)
                                    .foregroundColor(preferences.entryLayoutStyle == style
                                        ? themeManager.current.accentColor
                                        : themeManager.current.dateColor.opacity(0.45))
                            }

                            EntryLayoutPreview(style: style)
                        }
                        .padding(14)
                        .background(
                            themeManager.current.cellPrimaryColor,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    preferences.entryLayoutStyle == style
                                        ? themeManager.current.accentColor
                                        : themeManager.current.separatorColor.opacity(0.18),
                                    lineWidth: preferences.entryLayoutStyle == style ? 2 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(style.name), \(style.summary)")
                    .accessibilityValue(preferences.entryLayoutStyle == style ? "seçili" : "")
                }
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("entry görünümü")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EntryLayoutPreview: View {
    let style: EntryLayoutStyle

    @EnvironmentObject private var themeManager: ThemeManager

    private var presentation: EntryLayoutPresentation { style.presentation }

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat(presentation.contentSpacing * 0.55)) {
            if presentation.metadataPlacement == .authorHeader {
                previewAuthorRow
                previewDivider
            } else if presentation.metadataPlacement == .metadataHeader {
                previewDateRow
                previewDivider
            }

            Text("adam 4 kişiyi paketledi. 38 yaşında dünya kupasında yapıyor bunu.")
                .font(.system(size: previewFontSize, weight: .regular))
                .foregroundColor(themeManager.current.entryTextColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch presentation.metadataPlacement {
            case .footer:
                previewFooter
            case .inlineFooter:
                previewInlineFooter
            case .authorHeader:
                previewDateRow
            case .metadataHeader:
                previewAuthorRow
            }

            previewActions
        }
        .padding(.horizontal, CGFloat(presentation.horizontalPadding * 0.72))
        .padding(.vertical, CGFloat(presentation.verticalPadding * 0.65))
        .background(previewBackground)
        .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous))
        .padding(.horizontal, presentation.container == .card ? 8 : 0)
    }

    private var previewFontSize: CGFloat {
        style == .comfortable || style == .focus ? 15 : 14
    }

    private var previewCornerRadius: CGFloat {
        presentation.container == .card ? 13 : 8
    }

    private var previewBackground: Color {
        presentation.container == .card
            ? themeManager.current.cellSecondaryColor
            : themeManager.current.backgroundColor.opacity(0.72)
    }

    private var previewAuthorRow: some View {
        HStack(spacing: 7) {
            if presentation.showsAvatar {
                Circle()
                    .fill(themeManager.current.accentColor.opacity(0.24))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                            .foregroundColor(themeManager.current.accentColor)
                    }
            }
            Text("vapors")
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.current.accentColor)
            Spacer()
        }
    }

    private var previewDateRow: some View {
        HStack(spacing: 6) {
            Text("15.07.2026 22:38")
            Text("#185088056")
            Spacer()
        }
        .font(.caption2)
        .foregroundColor(themeManager.current.dateColor.opacity(0.75))
    }

    private var previewFooter: some View {
        HStack(alignment: .bottom) {
            previewAuthorRow
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("15.07.2026 22:38")
                Text("#185088056")
            }
            .font(.caption2)
            .foregroundColor(themeManager.current.dateColor.opacity(0.75))
        }
    }

    private var previewInlineFooter: some View {
        HStack(spacing: 6) {
            Text("vapors")
                .foregroundColor(themeManager.current.accentColor)
            Spacer()
            Text("15.07.2026 · #185088056")
                .foregroundColor(themeManager.current.dateColor.opacity(0.75))
        }
        .font(.caption2.weight(.medium))
    }

    private var previewActions: some View {
        HStack(spacing: presentation.actionStyle == .standard ? 16 : 22) {
            Label("5", systemImage: "star")
            Image(systemName: "chevron.up")
            Image(systemName: "chevron.down")
            Spacer()
            Image(systemName: "square.and.arrow.up")
            Image(systemName: "ellipsis")
        }
        .font(.caption)
        .foregroundColor(themeManager.current.dateColor.opacity(
            presentation.actionStyle == .quiet ? 0.52 : 0.72
        ))
        .padding(.top, 3)
    }

    private var previewDivider: some View {
        Rectangle()
            .fill(themeManager.current.separatorColor.opacity(0.18))
            .frame(height: 1)
    }
}
