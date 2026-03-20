import SwiftUI

struct BlockedTopicsView: View {
    @EnvironmentObject var blockedStore: BlockedTopicStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(blockedStore.rules) { rule in
                ruleRow(rule)
                    .listRowBackground(themeManager.current.cellPrimaryColor)
            }
            .onDelete { indexSet in
                let ids = indexSet.map { blockedStore.rules[$0].id }
                for id in ids {
                    blockedStore.removeRule(id: id)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.blockedTopics)
        .background(themeManager.current.backgroundColor)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundColor(themeManager.current.accentColor)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddFilterRuleSheet()
                .environmentObject(blockedStore)
                .environmentObject(themeManager)
        }
        .overlay {
            if blockedStore.rules.isEmpty {
                Text(L10n.Settings.noFilterRules)
                    .foregroundColor(.gray)
            }
        }
    }

    private func ruleRow(_ rule: FilterRule) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in blockedStore.toggleRule(id: rule.id) }
            ))
            .labelsHidden()
            .tint(themeManager.current.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.pattern)
                    .foregroundColor(rule.isEnabled ? themeManager.current.labelColor : .gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(rule.type.label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.current.accentColor.opacity(0.15))
                .foregroundColor(themeManager.current.accentColor)
                .cornerRadius(6)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Filter Rule Sheet

private struct AddFilterRuleSheet: View {
    @EnvironmentObject var blockedStore: BlockedTopicStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var pattern = ""
    @State private var filterType: FilterRule.FilterType = .contains
    @State private var regexError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Settings.filterPattern) {
                    TextField(L10n.Settings.filterPatternPlaceholder, text: $pattern)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                Section(L10n.Settings.filterType) {
                    Picker(L10n.Settings.filterType, selection: $filterType) {
                        ForEach(FilterRule.FilterType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                if let error = regexError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                }
            }
            .navigationTitle(L10n.Settings.addFilterRule)
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.current.backgroundColor)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Settings.cancel) {
                        dismiss()
                    }
                    .foregroundColor(themeManager.current.accentColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Settings.save) {
                        addRule()
                    }
                    .disabled(pattern.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(themeManager.current.accentColor)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addRule() {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Validate regex if that type is selected
        if filterType == .regex {
            do {
                _ = try NSRegularExpression(pattern: trimmed, options: .caseInsensitive)
            } catch {
                regexError = L10n.Settings.invalidRegex
                return
            }
        }

        let rule = FilterRule(id: UUID(), pattern: trimmed, type: filterType, isEnabled: true)
        blockedStore.addRule(rule)
        dismiss()
    }
}
