import Foundation
import UIKit

@MainActor
final class DebeViewModel: ObservableObject {
    @Published var entries: [DebeEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    private let client = HTTPClient.shared

    func loadDebe() async {
        isLoading = true
        error = nil
        do {
            let html = try await client.fetchHTML(for: .debe)
            entries = DebeParser.parseList(html: html)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggle(_ entry: DebeEntry) async {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }

        if entries[index].isExpanded {
            entries[index].isExpanded = false
            return
        }

        // Collapse others
        for i in entries.indices { entries[i].isExpanded = false }
        entries[index].isExpanded = true

        // Load content if not yet loaded
        if entries[index].contentHTML == nil {
            do {
                let html = try await client.fetchHTML(for: .entry(id: entry.id))
                if let parsed = DebeParser.parseSingleEntry(html: html) {
                    entries[index].contentHTML = parsed.content
                    entries[index].authorNick = parsed.author
                    entries[index].date = parsed.date

                    // Pre-render HTML
                    let theme = ThemeManager().current
                    let prefs = UserPreferences()
                    entries[index].parsedContent = HTMLContentRenderer.render(
                        html: parsed.content,
                        fontSize: prefs.selectedFontSize,
                        fontName: prefs.selectedFont,
                        textColorHex: theme.entryTextColor.hexString,
                        linkColorHex: theme.linkColor.hexString,
                        spoilerBgHex: theme.spoilerBackgroundHex
                    )
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
