import SwiftUI

struct TabCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var preferences: UserPreferences

    private let allTabs: [(String, String)] = [
        ("gundem", "popular"),
        ("bugun", "today"),
        ("debe", "debe"),
        ("tarihte bugun", "todayInHistory"),
        ("son", "latest"),
        ("takip", "following"),
        ("kenar", "kenar"),
        ("caylaklar", "caylaklar"),
        ("cop", "cop"),
    ]

    var body: some View {
        List {
            Section(footer: Text("hicbiri secilmezse tumu gosterilir")) {
                ForEach(allTabs, id: \.1) { tab in
                    Button {
                        toggleTab(tab.1)
                    } label: {
                        HStack {
                            Text(tab.0)
                                .foregroundColor(themeManager.current.labelColor)
                            Spacer()
                            if isVisible(tab.1) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.current.accentColor)
                            }
                        }
                    }
                }
            }
            .listRowBackground(themeManager.current.cellPrimaryColor)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.backgroundColor)
        .navigationTitle("sekmeler")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isVisible(_ rawValue: String) -> Bool {
        let visible = preferences.visibleHomeTabs
        return visible.isEmpty || visible.contains(rawValue)
    }

    private func toggleTab(_ rawValue: String) {
        var visible = preferences.visibleHomeTabs
        if visible.isEmpty {
            // First toggle: start with all tabs, then remove this one
            visible = allTabs.map { $0.1 }
            visible.removeAll { $0 == rawValue }
        } else if visible.contains(rawValue) {
            visible.removeAll { $0 == rawValue }
        } else {
            visible.append(rawValue)
        }
        // If all removed or all selected, reset to empty (show all)
        if visible.isEmpty || visible.count == allTabs.count {
            visible = []
        }
        preferences.visibleHomeTabs = visible
    }
}
