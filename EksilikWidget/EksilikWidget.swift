import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Configuration Intent

struct EksilikWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "ek$ilik Widget"
    static var description: IntentDescription = "Ekşi sözlük başlıklarını gösterir."

    @Parameter(title: "Kaynak", default: .gundem)
    var source: WidgetSource

    @Parameter(title: "Tema", default: .dark)
    var theme: WidgetTheme

    @Parameter(title: "Kullanıcı (son entry'leri)")
    var username: String?
}

enum WidgetSource: String, AppEnum {
    case gundem, bugun, debe, caylaklar, user

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Kaynak"
    static var caseDisplayRepresentations: [WidgetSource: DisplayRepresentation] = [
        .gundem: "gündem",
        .bugun: "bugün",
        .debe: "debe",
        .caylaklar: "çaylaklar",
        .user: "kullanıcı entry'leri",
    ]
}

enum WidgetTheme: String, AppEnum {
    case dark, light, classic, twitter, oled

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tema"
    static var caseDisplayRepresentations: [WidgetTheme: DisplayRepresentation] = [
        .dark: "gece",
        .light: "gündüz",
        .classic: "klasik",
        .twitter: "x",
        .oled: "oled",
    ]

    var bgColor: Color {
        switch self {
        case .dark: return Color(red: 37/255, green: 37/255, blue: 37/255)
        case .light: return .white
        case .classic: return Color(red: 221/255, green: 221/255, blue: 221/255)
        case .twitter: return Color(red: 23/255, green: 32/255, blue: 42/255)
        case .oled: return .black
        }
    }

    var textColor: Color {
        switch self {
        case .dark, .twitter: return .white
        case .light, .classic: return .black
        case .oled: return Color(red: 200/255, green: 200/255, blue: 200/255)
        }
    }

    var accentColor: Color {
        switch self {
        case .dark: return Color(red: 102/255, green: 180/255, blue: 63/255)
        case .light: return Color(red: 78/255, green: 125/255, blue: 28/255)
        case .classic: return Color(red: 0/255, green: 39/255, blue: 184/255)
        case .twitter: return Color(red: 76/255, green: 158/255, blue: 235/255)
        case .oled: return Color(red: 232/255, green: 152/255, blue: 56/255)
        }
    }
}

// MARK: - Widget

struct EksilikWidget: Widget {
    let kind = "EksilikWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: EksilikWidgetIntent.self, provider: TopicsProvider()) { entry in
            WidgetTopicView(entry: entry)
        }
        .configurationDisplayName("ek$ilik")
        .description("Ekşi sözlük başlıklarını gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
