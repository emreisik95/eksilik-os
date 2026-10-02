import Foundation

struct AppIconChoice: Identifiable, Equatable, Sendable {
    let title: String
    let iconName: String?
    let imageName: String

    var id: String { iconName ?? "primary" }

    /// An alternate icon registered under `CFBundleAlternateIcons`; previews load the @2x file.
    static func alternate(_ title: String, iconName: String) -> AppIconChoice {
        AppIconChoice(title: title, iconName: iconName, imageName: "\(iconName)@2x")
    }
}

enum AppIconPresentationPolicy {
    static let choices: [AppIconChoice] = [
        AppIconChoice(title: "oldschool", iconName: nil, imageName: "AppIcon"),
        .alternate("kağıt", iconName: "AlternateIcon"),
        .alternate("sözlük", iconName: "AlternateDictionary"),
        .alternate("noir", iconName: "AlternateNoir"),
        .alternate("terminal", iconName: "AlternateTerminal"),
        .alternate("neon", iconName: "AlternateNeon"),
        .alternate("aurora", iconName: "AlternateAurora"),
        .alternate("boğaz", iconName: "AlternateBosphorus"),
        .alternate("orman", iconName: "AlternateForest"),
        .alternate("limon", iconName: "AlternateLemon"),
        .alternate("kahve", iconName: "AlternateCoffee"),
        .alternate("altın", iconName: "AlternateGold"),
        .alternate("kil", iconName: "AlternateDepth"),
        .alternate("8-bit", iconName: "AlternatePixel"),
        .alternate("ornament", iconName: "AlternateKlasik"),
    ]

    static var alternates: [AppIconChoice] {
        choices.filter { $0.iconName != nil }
    }

    static func title(for iconName: String?) -> String {
        choices.first(where: { $0.iconName == iconName })?.title ?? choices[0].title
    }
}
