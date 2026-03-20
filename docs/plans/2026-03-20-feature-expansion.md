# Feature Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add home tab expansion (8 tabs), DEBE accordion, advanced filtering, entry action menu, and settings/follow management.

**Architecture:** All new tabs reuse existing TopicListViewModel/TopicListView. DEBE gets a dedicated parser+view. Filtering uses a rule-based engine. Entry actions use confirmationDialog. WebView-based pages use a shared GenericWebView.

**Tech Stack:** SwiftUI, Kanna HTML parsing, WKWebView for settings/management pages

---

### Task 1: Expand Home Tabs

**Goal:** Show gündem, bugün, debe, tarihte bugün, son, takip, kenar, çaylaklar, çöp as scrollable tabs. Auth-required tabs (takip, çöp) only visible when logged in.

**Files:**
- Modify: `EksilikApp/Views/Home/HomeTabView.swift`
- Modify: `EksilikApp/Core/Network/EksiEndpoint.swift`
- Modify: `EksilikApp/ViewModels/TopicListViewModel.swift`
- Modify: `EksilikApp/Core/Strings.swift`

**Changes:**

1. Add new cases to `EksiEndpoint`:
```swift
case kenar
case caylaklar
case cop

// paths:
case .kenar: return "/basliklar/m/kenar"
case .caylaklar: return "/basliklar/m/caylaklar/bugun"
case .cop: return "/cop"
```

2. Add new ListType cases in `TopicListViewModel`:
```swift
enum ListType: String {
    case popular, today, debe, todayInHistory, latest, following, kenar, caylaklar, cop
}
```

3. Add L10n strings:
```swift
static let tarihte = "tarihte bugün"
static let son = "son"
static let takip = "takip"
static let kenar = "kenar"
static let caylaklar = "çaylaklar"
static let cop = "çöp"
```

4. Rewrite HomeTabView tabs array to be scrollable:
```swift
@EnvironmentObject var session: SessionManager

private var tabs: [(String, TopicListViewModel.ListType)] {
    var list: [(String, TopicListViewModel.ListType)] = [
        (L10n.Home.gundem, .popular),
        (L10n.Home.bugun, .today),
        (L10n.Home.debe, .debe),
        (L10n.Home.tarihte, .todayInHistory),
        (L10n.Home.son, .latest),
    ]
    if session.isLoggedIn {
        list.append((L10n.Home.takip, .following))
    }
    list.append((L10n.Home.kenar, .kenar))
    list.append((L10n.Home.caylaklar, .caylaklar))
    if session.isLoggedIn {
        list.append((L10n.Home.cop, .cop))
    }
    return list
}
```

5. Wrap tabs HStack in `ScrollView(.horizontal)` and remove the DEBE toolbar star button.

6. Handle new cases in `TopicListViewModel.loadTopics()` — kenar, caylaklar, cop go through `topicService.fetchFromEndpoint()` with matching endpoint.

---

### Task 2: DEBE Accordion View

**Goal:** DEBE shows topic titles. Tapping expands inline to show the single entry content. Tapping title navigates to the full topic.

**Files:**
- Create: `EksilikApp/Models/DebeEntry.swift`
- Create: `EksilikApp/Core/Parsing/DebeParser.swift`
- Create: `EksilikApp/Views/Home/DebeView.swift`
- Create: `EksilikApp/ViewModels/DebeViewModel.swift`
- Modify: `EksilikApp/Views/Home/HomeTabView.swift` (show DebeView when debe tab selected)

**Model:**
```swift
struct DebeEntry: Identifiable {
    let id: String          // entry ID from href
    let topicTitle: String  // span.caption text
    let entryLink: String   // /entry/12345?debe=true
    var expanded: Bool = false
    var contentHTML: String? // loaded on expand
    var parsedContent: NSAttributedString?
}
```

**Parser** — parses `ul.topic-list li a[href*=debe=true]`:
```swift
struct DebeParser {
    static func parseList(html: String) -> [DebeEntry] {
        // css: "ul.topic-list li a[href*=debe]"
        // title: a > span.caption text
        // id: extract from href /entry/{id}?debe=true
    }
}
```

**DebeView** — List of titles, tap to expand/collapse:
```swift
ForEach($viewModel.entries) { $entry in
    VStack(alignment: .leading) {
        // Title row — tap to toggle expand
        Button { viewModel.toggle(entry) } label: {
            HStack {
                Text(entry.topicTitle)
                Spacer()
                Image(systemName: entry.expanded ? "chevron.up" : "chevron.down")
            }
        }

        // Expanded content
        if entry.expanded {
            if let content = entry.parsedContent {
                EntryTextView(attributedText: content)
            } else {
                ProgressView()
            }
            // "başlığa git" link
            NavigationLink(value: Route.entryList(...)) { Text("başlığa git →") }
        }
    }
}
```

**ViewModel** — `toggle()` fetches entry HTML via `/entry/{id}` on first expand, parses single entry content, pre-renders to NSAttributedString.

---

### Task 3: Advanced Topic Filtering

**Goal:** Replace simple blocked topics list with a rule-based filter engine supporting exact match, keyword contains, and regex patterns.

**Files:**
- Rewrite: `EksilikApp/Core/Storage/BlockedTopicStore.swift`
- Rewrite: `EksilikApp/Views/Settings/BlockedTopicsView.swift` (or create if doesn't exist)
- Modify: `EksilikApp/Core/Strings.swift`

**Model:**
```swift
struct FilterRule: Identifiable, Codable {
    let id: UUID
    var pattern: String
    var type: FilterType
    var isEnabled: Bool

    enum FilterType: String, Codable, CaseIterable {
        case exact      // exact title match
        case contains   // title contains keyword
        case regex      // regex pattern match

        var label: String {
            switch self {
            case .exact: return "tam eşleşme"
            case .contains: return "içeren"
            case .regex: return "regex"
            }
        }
    }

    func matches(_ title: String) -> Bool {
        guard isEnabled else { return false }
        let lower = title.lowercased()
        switch type {
        case .exact: return lower == pattern.lowercased()
        case .contains: return lower.contains(pattern.lowercased())
        case .regex:
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
            return regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil
        }
    }
}
```

**BlockedTopicStore** rewrite — stores `[FilterRule]` in UserDefaults as JSON:
```swift
func isBlocked(_ title: String) -> Bool {
    rules.contains { $0.matches(title) }
}
func addRule(_ rule: FilterRule) { ... }
func removeRule(id: UUID) { ... }
// Migration: convert old [String] blocked list to .exact rules on first launch
```

**BlockedTopicsView** — List of rules + add button:
- Each row: toggle switch, pattern text, type badge (tam/içeren/regex)
- Swipe to delete
- Add sheet: text field for pattern, picker for type, preview of matching count
- Long press on topic rows (TopicListView) adds a `.contains` rule via context menu

**TopicListView** — add context menu:
```swift
.contextMenu {
    Button("başlığı engelle") { blockedStore.addRule(.init(id: UUID(), pattern: topic.title, type: .exact, isEnabled: true)) }
}
```

---

### Task 4: Entry Action Menu

**Goal:** Expand the "..." menu on entries with: mesaj gönder, şikayet, modlog, engelle (author).

**Files:**
- Modify: `EksilikApp/Views/Entry/EntryRowView.swift`
- Modify: `EksilikApp/Core/Strings.swift`

**Changes to confirmationDialog:**
```swift
.confirmationDialog("", isPresented: $showActions) {
    Button(L10n.Entry.shareScreenshot) { shareEntryScreenshot() }
    Button(L10n.Entry.copyEntry) { UIPasteboard.general.string = entry.contentHTML.strippingHTML }

    // Link sharing
    Button(L10n.Entry.shareLink) { shareItems([entry.shareURL]) }

    // Who favorited
    NavigationLink(value: Route.favoriteUsers(entryId: entry.id)) — not possible in dialog, use separate state

    if session.isLoggedIn {
        // Send message to author
        Button("mesaj gönder") {
            pendingRoute = Route.composeMessage(to: entry.author.nick, subject: "#\(entry.id)")
        }
        // Block author — add to filter rules
        Button("yazarı engelle", role: .destructive) {
            // TODO: use UserService to call blockUser endpoint
        }
    }

    // Open modlog in browser
    Button("modlog") {
        if let url = URL(string: "https://eksisozluk.com/entry/\(entry.id)/modlog") {
            UIApplication.shared.open(url)
        }
    }

    Button(L10n.Entry.cancel, role: .cancel) {}
}
```

Add L10n strings for new actions. Use `@State var pendingRoute` + `.onChange` to navigate after dialog dismisses.

---

### Task 5: Settings WebView + Follow/Block Management

**Goal:** "Tercihler" in settings opens eksisozluk.com/ayarlar/tercihler in an in-app WebView. "Takip/Engellenmişler" opens eksisozluk.com/takip-engellenmis.

**Files:**
- Create: `EksilikApp/Views/Common/EksiWebView.swift`
- Modify: `EksilikApp/Views/Settings/SettingsView.swift`
- Modify: `EksilikApp/Core/Navigation/Route.swift`

**EksiWebView** — Reusable authenticated WKWebView:
```swift
struct EksiWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // has auth cookies
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.load(URLRequest(url: url))
        return wv
    }
    func updateUIView(_ wv: WKWebView, context: Context) {}
}
```

**Route additions:**
```swift
case webPage(url: String, title: String)
```

**SettingsView additions** (new rows):
```swift
Section("hesap") {
    NavigationLink(value: Route.webPage(url: "https://eksisozluk.com/ayarlar/tercihler", title: "tercihler")) {
        Text("tercihler")
    }
    NavigationLink(value: Route.webPage(url: "https://eksisozluk.com/takip-engellenmis", title: "takip / engellenmişler")) {
        Text("takip / engellenmişler")
    }
}
```

**destinationView** addition:
```swift
case .webPage(let url, let title):
    EksiWebView(url: URL(string: url)!)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
```

---

## Execution Order

| # | Task | Depends On | Complexity |
|---|------|-----------|------------|
| 1 | Home Tab Expansion | — | Medium |
| 2 | DEBE Accordion | Task 1 (debe tab) | Medium |
| 3 | Advanced Filtering | — | Medium |
| 4 | Entry Action Menu | — | Small |
| 5 | Settings WebView | — | Small |

Tasks 1, 3, 4, 5 are independent. Task 2 depends on Task 1 (debe tab exists).

## Verification

After each task:
1. `xcodegen generate && xcodebuild build` must pass
2. Visual check: screenshot or manual test for the specific feature
