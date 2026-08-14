import Foundation

struct AppIconChoice: Identifiable, Equatable, Sendable {
    let title: String
    let iconName: String?
    let imageName: String

    var id: String { iconName ?? "primary" }
}

enum AppIconPresentationPolicy {
    static let choices: [AppIconChoice] = [
        AppIconChoice(title: "oldschool", iconName: nil, imageName: "AppIcon"),
        AppIconChoice(title: "light", iconName: "AlternateIcon", imageName: "AlternateIcon@2x"),
        AppIconChoice(
            title: "ornament",
            iconName: "AlternateKlasik",
            imageName: "AlternateKlasik@2x"
        ),
        AppIconChoice(title: "noir", iconName: "AlternateNoir", imageName: "AlternateNoir@2x"),
        AppIconChoice(title: "aurora", iconName: "AlternateAurora", imageName: "AlternateAurora@2x"),
        AppIconChoice(title: "depth", iconName: "AlternateDepth", imageName: "AlternateDepth@2x"),
        AppIconChoice(title: "forest", iconName: "AlternateForest", imageName: "AlternateForest@2x"),
    ]

    static func title(for iconName: String?) -> String {
        choices.first(where: { $0.iconName == iconName })?.title ?? choices[0].title
    }
}
