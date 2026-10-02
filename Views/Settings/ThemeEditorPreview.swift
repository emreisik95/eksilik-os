import SwiftUI
import UIKit

/// Live preview for the theme editor. Topic rows, the entry and pagination are the production
/// views, fed by a non-persisting `ThemeManager`; the bars and the button are drawn from the same
/// tokens because the real ones are system chrome. Tapping an element reports the tokens it uses.
struct ThemeEditorPreview: View {
    let palette: ThemePalette
    let highlighted: Set<ThemeTokenKey>
    let highlightColor: Color
    let onSelect: ([ThemeTokenKey]) -> Void

    @EnvironmentObject private var preferences: UserPreferences
    @StateObject private var previewManager: ThemeManager
    @StateObject private var navigation = NavigationCoordinator()
    @State private var entryContent: NSAttributedString?

    init(
        palette: ThemePalette,
        highlighted: Set<ThemeTokenKey>,
        highlightColor: Color,
        onSelect: @escaping ([ThemeTokenKey]) -> Void
    ) {
        self.palette = palette
        self.highlighted = highlighted
        self.highlightColor = highlightColor
        self.onSelect = onSelect
        _previewManager = StateObject(wrappedValue: ThemeManager(previewPalette: palette))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                navigationBar
                topicRows
                entry
                pagination
                primaryButton
                tabBar
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect([.background]) }
            .background(palette.backgroundColor)
            .overlay {
                if highlighted == [.background] {
                    Rectangle()
                        .strokeBorder(highlightColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .allowsHitTesting(false)
                }
            }
        }
        .background(palette.backgroundColor)
        .environmentObject(previewManager)
        .environmentObject(navigation)
        .environment(\.colorScheme, palette.colorScheme)
        .onChange(of: palette) { newPalette in
            previewManager.applyPreview(newPalette)
        }
        .task(id: EntryRenderKey(palette: palette, preferences: preferences)) {
            if entryContent != nil {
                // Coalesce color-picker drags; the HTML importer is too slow to run per frame.
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
            }
            renderEntry()
        }
    }

    // MARK: - Elements

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundColor(palette.accentColor)
            Spacer(minLength: 0)
            Text(Self.topics[0].title)
                .font(preferences.readingFont.font(.subheadline, basePointSize: 15, bold: true))
                .foregroundColor(palette.labelColor)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "ellipsis.circle")
                .foregroundColor(palette.accentColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(palette.navBarColor)
        .previewTarget([.navBar, .label], label: "üst bar", context: targetContext)
    }

    private var topicRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.topics.enumerated()), id: \.element.id) { index, topic in
                TopicRowView(topic: topic, isEven: index % 2 == 0)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .frame(minHeight: 44)
                    .background(index % 2 == 0 ? palette.cellPrimaryColor : palette.cellSecondaryColor)
                    .previewTarget(
                        [index % 2 == 0 ? .cellPrimary : .cellSecondary, .label, .entryCount],
                        label: "başlık satırı",
                        context: targetContext
                    )
                separator
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(palette.separatorColor)
            .frame(height: 1)
            .overlay {
                // A one-point line is too thin to hit; give it a finger-sized target.
                Color.clear
                    .frame(height: 18)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect([.separator]) }
            }
            .overlay {
                if highlighted == [.separator] {
                    Rectangle().stroke(highlightColor, lineWidth: 2)
                }
            }
            .zIndex(1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("ayırıcı")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onSelect([.separator]) }
    }

    @ViewBuilder
    private var entry: some View {
        if let entryContent {
            EntryRowView(
                entry: Self.sampleEntry(content: entryContent),
                isEven: true,
                onFavorite: {},
                onUpvote: {},
                onDownvote: {},
                onOpenImages: { _, _ in }
            )
            .previewTarget(
                [.entryText, .link, .spoilerBackground, .accent, .date],
                label: "entry",
                context: targetContext
            )
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(palette.cellPrimaryColor)
        }
    }

    private var pagination: some View {
        PaginationView(pagination: Pagination(currentPage: 2, totalPages: 14), onPageChange: { _ in })
            .padding(.vertical, 6)
            .previewTarget([.accent, .cellSecondary, .label], label: "sayfalama", context: targetContext)
    }

    private var primaryButton: some View {
        Text("başlığı takip et")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(palette.backgroundColor)
            .padding(.horizontal, 18)
            .frame(minHeight: 40)
            .background(palette.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .previewTarget([.accent], label: "buton", context: targetContext)
            .padding(.vertical, 14)
    }

    private var tabBar: some View {
        let tabs = MainTab.visibleTabs(isLoggedIn: true)
        return HStack(spacing: 0) {
            ForEach(tabs) { tab in
                let isSelected = tab == tabs.first
                VStack(spacing: 3) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    Text(tab.title)
                        .font(.caption2)
                }
                .foregroundColor(isSelected ? palette.tabBarTintColor : Color(uiColor: .systemGray))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 7)
        .padding(.bottom, 9)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(palette.separatorColor.opacity(0.35))
                .frame(height: 0.5)
        }
        .previewTarget([.tabBarTint], label: "sekme çubuğu", context: targetContext)
    }

    // MARK: - Helpers

    private var targetContext: PreviewTargetContext {
        PreviewTargetContext(highlighted: highlighted, highlightColor: highlightColor, onSelect: onSelect)
    }

    private func renderEntry() {
        entryContent = HTMLContentRenderer.render(
            html: Self.sampleHTML,
            fontSize: preferences.selectedFontSize,
            readingFont: preferences.readingFont,
            textColorHex: palette.entryText.hexString,
            linkColorHex: palette.link.hexString,
            spoilerBgHex: palette.spoilerBackgroundHex
        )
    }
}

// MARK: - Sample content

extension ThemeEditorPreview {
    static let topics = [
        Topic(id: "preview-1", title: "pazartesi sendromu", slug: "pazartesi-sendromu", entryCount: "128", link: ""),
        Topic(id: "preview-2", title: "çay demleme sanatı", slug: "cay-demleme-sanati", entryCount: "47", link: ""),
    ]

    /// Local sample only: an outside link, a relative (bkz) and a marked spoiler. Nothing here
    /// is fetched; links cannot be followed because the preview disables hit testing.
    static let sampleHTML = """
    ilk yudumda insanın aklı açılır. ayrıntılar için \
    <a href="https://example.com/cay" class="url">example.com</a> \
    (bkz: <a class="b" href="/?q=demlik">demlik</a>)<br/><br/>\
    --- spoiler ---<br/><mark>son bardak hep soğuk kalır.</mark><br/>--- spoiler ---
    """

    static func sampleEntry(content: NSAttributedString) -> Entry {
        Entry(
            id: "1000001",
            contentHTML: sampleHTML,
            author: Author(id: "preview-author", nick: "örnek yazar", avatarURL: nil),
            date: "02.10.2026 09:41",
            favoriteCount: 12,
            isFavorited: false,
            voteState: .none,
            authorId: "preview-author",
            imageURLs: [],
            parsedContent: content
        )
    }
}

private struct EntryRenderKey: Hashable {
    let entryText: ThemeColorToken
    let link: ThemeColorToken
    let spoiler: ThemeColorToken
    let fontSize: Int
    let readingFont: ReadingFont

    init(palette: ThemePalette, preferences: UserPreferences) {
        entryText = palette.entryText
        link = palette.link
        spoiler = palette.spoilerBackground
        fontSize = preferences.selectedFontSize
        readingFont = preferences.readingFont
    }
}

// MARK: - Tap targets

struct PreviewTargetContext {
    let highlighted: Set<ThemeTokenKey>
    let highlightColor: Color
    let onSelect: ([ThemeTokenKey]) -> Void
}

private struct PreviewTargetModifier: ViewModifier {
    let keys: [ThemeTokenKey]
    let label: String
    let context: PreviewTargetContext

    /// Lights up every element that uses all of the selected tokens, so picking a single token
    /// in the list shows each place it appears.
    private var isHighlighted: Bool {
        !context.highlighted.isEmpty && context.highlighted.isSubset(of: keys)
    }

    func body(content: Content) -> some View {
        content
            .allowsHitTesting(false)
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { context.onSelect(keys) }
            }
            .overlay {
                if isHighlighted {
                    Rectangle()
                        .strokeBorder(context.highlightColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .allowsHitTesting(false)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint("bu öğenin renklerini aşağıda gösterir")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { context.onSelect(keys) }
    }
}

private extension View {
    func previewTarget(_ keys: [ThemeTokenKey], label: String, context: PreviewTargetContext) -> some View {
        modifier(PreviewTargetModifier(keys: keys, label: label, context: context))
    }
}
