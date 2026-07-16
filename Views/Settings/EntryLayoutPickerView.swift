import SwiftUI

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

    private let sample = "adam 4 kişiyi paketledi. 38 yaşında dünya kupasında yapıyor bunu."

    var body: some View {
        composition
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.current.cellPrimaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(themeManager.current.separatorColor.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(style.name) canlı entry önizlemesi")
    }

    @ViewBuilder
    private var composition: some View {
        switch style.family {
        case .classic:
            classicPreview
        case .xFeed:
            xPreview
        case .instagram:
            instagramPreview
        case .linkedIn:
            linkedInPreview
        case .reddit:
            redditPreview
        case .reader:
            readerPreview
        case .terminal:
            terminalPreview
        case .minimal:
            minimalPreview
        }
    }

    private var classicPreview: some View {
        VStack(alignment: .leading, spacing: 18) {
            sampleText
            HStack(alignment: .bottom) {
                authorLabel(avatarSize: 26)
                Spacer()
                dateBlock
            }
            Divider().opacity(0.22)
            socialActions(labels: false)
        }
        .padding(18)
    }

    private var xPreview: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar(size: 42)
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 4) {
                    Text("vapors").font(.subheadline.bold())
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(themeManager.current.accentColor)
                    Text("· 22:38").foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                .font(.subheadline)
                .foregroundColor(themeManager.current.labelColor)

                sampleText
                socialActions(labels: false)
                    .padding(.leading, -8)
            }
        }
        .padding(16)
    }

    private var instagramPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                avatar(size: 34)
                    .overlay(Circle().stroke(themeManager.current.accentColor, lineWidth: 2))
                Text("vapors").font(.subheadline.bold())
                Spacer()
                Image(systemName: "ellipsis")
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.current.accentColor.opacity(0.48),
                            themeManager.current.cellSecondaryColor,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 118)
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(themeManager.current.labelColor.opacity(0.72))
                }

            socialActions(labels: false)
            Text("\(Text("vapors").bold())  \(sample)")
                .font(.subheadline)
                .foregroundColor(themeManager.current.entryTextColor)
                .lineLimit(2)
            Text("15.07.2026 · #185088056")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }

    private var linkedInPreview: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 10) {
                avatar(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("vapors").font(.subheadline.bold())
                    Text("sözlük yazarı · 15.07.2026")
                    Text("#185088056")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "ellipsis")
            }
            sampleText
            Divider().opacity(0.26)
            socialActions(labels: true)
        }
        .padding(18)
        .background(themeManager.current.cellSecondaryColor.opacity(0.45))
    }

    private var redditPreview: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 5) {
                Image(systemName: "arrow.up")
                Text("5").font(.caption.bold())
                Image(systemName: "arrow.down")
            }
            .foregroundColor(themeManager.current.accentColor)
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 10) {
                Text("r/ekşisözlük · vapors · 22:38")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                sampleText
                HStack(spacing: 18) {
                    Label("entry", systemImage: "text.bubble")
                    Label("paylaş", systemImage: "square.and.arrow.up")
                    Image(systemName: "ellipsis")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }

    private var readerPreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("ENTRY 185088056")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.4)
                Spacer()
                Image(systemName: "bookmark")
            }
            .foregroundColor(.secondary)

            Text(sample)
                .font(.system(.body, design: .serif))
                .foregroundColor(themeManager.current.entryTextColor)
                .lineSpacing(5)

            HStack {
                Rectangle()
                    .fill(themeManager.current.accentColor)
                    .frame(width: 24, height: 2)
                Text("vapors · 15 Temmuz 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
    }

    private var terminalPreview: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Circle().fill(Color.red.opacity(0.8)).frame(width: 8, height: 8)
                Circle().fill(Color.yellow.opacity(0.8)).frame(width: 8, height: 8)
                Circle().fill(Color.green.opacity(0.8)).frame(width: 8, height: 8)
                Spacer()
                Text("entry://185088056")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 11, design: .monospaced))

            Text("> vapors @ 15.07.2026 22:38")
                .foregroundColor(themeManager.current.accentColor)
            Text(sample)
                .foregroundColor(themeManager.current.entryTextColor)
                .lineLimit(3)
            Text("[★ 5]  [↑]  [↓]          [share]  […]")
                .foregroundColor(.secondary)
        }
        .font(.system(.subheadline, design: .monospaced))
        .padding(16)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(themeManager.current.accentColor)
                .frame(width: 3)
        }
    }

    private var minimalPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            sampleText
            HStack(spacing: 6) {
                Text("vapors").foregroundColor(themeManager.current.accentColor)
                Text("·")
                Text("15.07.2026")
                Spacer()
                Image(systemName: "star")
                Text("5")
                Image(systemName: "ellipsis")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
    }

    private var sampleText: some View {
        Text(sample)
            .font(.body)
            .foregroundColor(themeManager.current.entryTextColor)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func avatar(size: CGFloat) -> some View {
        Circle()
            .fill(themeManager.current.accentColor.opacity(0.16))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundColor(themeManager.current.accentColor)
            }
    }

    private func authorLabel(avatarSize: CGFloat) -> some View {
        HStack(spacing: 8) {
            avatar(size: avatarSize)
            Text("vapors")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.current.accentColor)
        }
    }

    private var dateBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("15.07.2026 22:38")
            Text("#185088056")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private func socialActions(labels: Bool) -> some View {
        HStack(spacing: labels ? 0 : 20) {
            actionItem("star", label: labels ? "beğen" : nil)
            actionItem("chevron.up", label: labels ? "oyla" : nil)
            if !labels {
                Image(systemName: "chevron.down")
            }
            Spacer()
            actionItem("square.and.arrow.up", label: labels ? "paylaş" : nil)
            Image(systemName: "ellipsis")
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .frame(minHeight: 28)
    }

    @ViewBuilder
    private func actionItem(_ image: String, label: String?) -> some View {
        if let label {
            Label(label, systemImage: image)
                .frame(maxWidth: .infinity)
        } else {
            Image(systemName: image)
        }
    }
}
