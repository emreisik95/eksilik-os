import SwiftUI

enum AppTheme: Int, CaseIterable, Identifiable {
    case dark = 0
    case light = 1
    case classic = 2
    case twitter = 3
    case oled = 4

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .dark: return "gece"
        case .light: return "gündüz"
        case .classic: return "klasik"
        case .twitter: return "x"
        case .oled: return "oled"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .dark: return Color(red: 37/255, green: 37/255, blue: 37/255)
        case .light: return .white
        case .classic: return Color(red: 221/255, green: 221/255, blue: 221/255)
        case .twitter: return Color(red: 23/255, green: 32/255, blue: 42/255)
        case .oled: return .black
        }
    }

    var cellPrimaryColor: Color {
        switch self {
        case .dark: return Color(red: 28/255, green: 28/255, blue: 28/255)
        case .light: return Color(red: 245/255, green: 245/255, blue: 245/255)
        case .classic: return Color(red: 221/255, green: 221/255, blue: 221/255)
        case .twitter: return Color(red: 23/255, green: 32/255, blue: 42/255)
        case .oled: return Color(red: 10/255, green: 10/255, blue: 10/255)
        }
    }

    var cellSecondaryColor: Color {
        switch self {
        case .dark: return Color(red: 22/255, green: 22/255, blue: 22/255)
        case .light: return Color(red: 245/255, green: 245/255, blue: 245/255)
        case .classic: return Color(red: 221/255, green: 221/255, blue: 221/255)
        case .twitter: return Color(red: 23/255, green: 32/255, blue: 42/255)
        case .oled: return Color(red: 5/255, green: 5/255, blue: 5/255)
        }
    }

    var accentColor: Color {
        switch self {
        case .dark: return Color(red: 102/255, green: 180/255, blue: 63/255)
        case .light: return Color(red: 78/255, green: 125/255, blue: 28/255)
        case .classic: return Color(red: 0/255, green: 39/255, blue: 184/255)
        case .twitter: return Color(red: 76/255, green: 158/255, blue: 235/255)
        case .oled: return Color(red: 232/255, green: 152/255, blue: 56/255) // warm orange
        }
    }

    var entryTextColor: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        case .classic: return .black
        case .twitter: return .white
        case .oled: return Color(red: 180/255, green: 180/255, blue: 180/255) // soft gray
        }
    }

    var linkColor: Color {
        switch self {
        case .dark: return Color(red: 180/255, green: 238/255, blue: 116/255)
        case .light: return Color(red: 78/255, green: 125/255, blue: 28/255)
        case .classic: return Color(red: 0/255, green: 39/255, blue: 184/255)
        case .twitter: return Color(red: 76/255, green: 158/255, blue: 235/255)
        case .oled: return Color(red: 245/255, green: 178/255, blue: 80/255) // light orange
        }
    }

    var labelColor: Color {
        switch self {
        case .dark, .twitter: return .white
        case .light, .classic: return .black
        case .oled: return Color(red: 200/255, green: 200/255, blue: 200/255)
        }
    }

    var dateColor: Color { .gray }

    var separatorColor: Color {
        switch self {
        case .dark, .twitter: return .black
        case .light: return Color(.darkGray)
        case .classic: return .gray
        case .oled: return Color(red: 25/255, green: 25/255, blue: 25/255)
        }
    }

    var navBarColor: Color {
        switch self {
        case .dark: return Color(red: 22/255, green: 22/255, blue: 22/255)
        case .light: return .clear
        case .classic: return Color(red: 221/255, green: 221/255, blue: 221/255)
        case .twitter: return Color(red: 23/255, green: 32/255, blue: 42/255)
        case .oled: return .black
        }
    }

    var tabBarTintColor: Color {
        switch self {
        case .dark: return Color(red: 136/255, green: 202/255, blue: 64/255)
        case .light: return Color(red: 136/255, green: 202/255, blue: 64/255)
        case .classic: return .white
        case .twitter: return Color(red: 76/255, green: 158/255, blue: 235/255)
        case .oled: return Color(red: 232/255, green: 152/255, blue: 56/255)
        }
    }

    var entryCountColor: Color {
        switch self {
        case .dark: return Color(red: 180/255, green: 238/255, blue: 116/255)
        case .light: return Color(red: 78/255, green: 125/255, blue: 28/255)
        case .classic: return Color(red: 0/255, green: 39/255, blue: 184/255)
        case .twitter: return Color(red: 76/255, green: 158/255, blue: 235/255)
        case .oled: return Color(red: 232/255, green: 152/255, blue: 56/255)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark, .twitter, .oled: return .dark
        case .light, .classic: return .light
        }
    }

    var spoilerBackgroundHex: String {
        switch self {
        case .dark, .twitter, .oled: return "#616161"
        case .light, .classic: return "#ffff9e"
        }
    }
}
