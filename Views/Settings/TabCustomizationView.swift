import SwiftUI

struct TabCustomizationView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    private var orderedTabs: [HomeTabDefinition] {
        let definitions = Dictionary(
            uniqueKeysWithValues: HomeTabDefinition.all.map { ($0.id, $0) }
        )
        return HomeTabCatalog.normalizedOrder(preferences.homeTabOrder).compactMap { definitions[$0] }
    }

    var body: some View {
        List {
            Section {
                ForEach(orderedTabs) { tab in
                    Button {
                        toggleTab(tab.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tab.systemImage)
                                .foregroundColor(isVisible(tab.id)
                                    ? themeManager.current.accentColor
                                    : .secondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.name)
                                    .foregroundColor(themeManager.current.labelColor)
                                if tab.requiresLogin {
                                    Text("giriş yapınca kullanılabilir")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: isVisible(tab.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(isVisible(tab.id)
                                    ? themeManager.current.accentColor
                                    : .secondary.opacity(0.45))
                        }
                        .frame(minHeight: 48)
                    }
                    .buttonStyle(.plain)
                }
                .onMove(perform: moveTabs)
            } header: {
                Text("görünürlük ve sıra")
            } footer: {
                Text("Sekmeye dokunarak gizle veya göster. Sıralamak için sağ üstten Düzenle'ye basıp tutamaçları sürükle.")
            }
            .listRowBackground(themeManager.current.cellPrimaryColor)

            Section {
                Button {
                    withAnimation {
                        preferences.visibleHomeTabs = []
                        preferences.homeTabOrder = HomeTabCatalog.defaultOrder
                    }
                } label: {
                    Label("varsayılan düzene dön", systemImage: "arrow.counterclockwise")
                        .foregroundColor(themeManager.current.accentColor)
                }
            }
            .listRowBackground(themeManager.current.cellPrimaryColor)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.backgroundColor)
        .navigationTitle("sekmeler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }

    private func isVisible(_ id: String) -> Bool {
        let visible = preferences.visibleHomeTabs
        return visible.isEmpty || visible.contains(id)
    }

    private func toggleTab(_ id: String) {
        var visible = preferences.visibleHomeTabs
        if visible.isEmpty {
            visible = HomeTabCatalog.defaultOrder
        }

        if let index = visible.firstIndex(of: id) {
            guard visible.count > 1 else { return }
            visible.remove(at: index)
        } else {
            visible.append(id)
        }

        let knownVisible = Set(visible).intersection(HomeTabCatalog.defaultOrder)
        preferences.visibleHomeTabs = knownVisible.count == HomeTabCatalog.defaultOrder.count
            ? []
            : HomeTabCatalog.normalizedOrder(preferences.homeTabOrder).filter(knownVisible.contains)
    }

    private func moveTabs(from source: IndexSet, to destination: Int) {
        preferences.homeTabOrder = HomeTabCatalog.moving(
            preferences.homeTabOrder,
            fromOffsets: source,
            toOffset: destination
        )
    }
}
