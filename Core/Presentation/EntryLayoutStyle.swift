import Foundation

enum EntryLayoutFamily: String, CaseIterable, Hashable, Sendable {
    case classic
    case xFeed
    case instagram
    case linkedIn
    case reddit
    case reader
    case terminal
    case minimal
}

enum EntryLayoutStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic
    case xFeed
    case instagram
    case linkedIn
    case reddit
    case reader
    case terminal
    case minimal

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return "klasik ekşi"
        case .xFeed: return "X"
        case .instagram: return "Instagram"
        case .linkedIn: return "LinkedIn"
        case .reddit: return "Reddit"
        case .reader: return "okuma"
        case .terminal: return "terminal"
        case .minimal: return "minimal"
        }
    }

    var summary: String {
        switch self {
        case .classic: return "tanıdık ekşi sözlük akışı"
        case .xFeed: return "avatar solda, hızlı sosyal akış"
        case .instagram: return "yazar ve medya odaklı gönderi"
        case .linkedIn: return "kimlik başlıklı profesyonel kart"
        case .reddit: return "oy sütunlu forum düzeni"
        case .reader: return "ferah ve sakin uzun okuma"
        case .terminal: return "monospace bilgi ve kompakt komutlar"
        case .minimal: return "avatar ve kalın ayraçları kaldırır"
        }
    }

    var systemImage: String {
        switch self {
        case .classic: return "rectangle.split.3x1"
        case .xFeed: return "bubble.left"
        case .instagram: return "camera"
        case .linkedIn: return "person.text.rectangle"
        case .reddit: return "arrow.up.circle"
        case .reader: return "book.closed"
        case .terminal: return "chevron.left.forwardslash.chevron.right"
        case .minimal: return "minus"
        }
    }

    var family: EntryLayoutFamily {
        switch self {
        case .classic: return .classic
        case .xFeed: return .xFeed
        case .instagram: return .instagram
        case .linkedIn: return .linkedIn
        case .reddit: return .reddit
        case .reader: return .reader
        case .terminal: return .terminal
        case .minimal: return .minimal
        }
    }

    var presentation: EntryLayoutPresentation {
        switch self {
        case .classic:
            return EntryLayoutPresentation(
                horizontalPadding: 16,
                verticalPadding: 16,
                contentSpacing: 12,
                metadataPlacement: .footer,
                container: .fullWidth,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 6,
                cornerRadius: 0
            )
        case .xFeed:
            return EntryLayoutPresentation(
                horizontalPadding: 14,
                verticalPadding: 12,
                contentSpacing: 10,
                metadataPlacement: .authorHeader,
                container: .fullWidth,
                actionStyle: .compact,
                showsAvatar: true,
                separatorHeight: 2,
                cornerRadius: 0
            )
        case .instagram:
            return EntryLayoutPresentation(
                horizontalPadding: 14,
                verticalPadding: 14,
                contentSpacing: 12,
                metadataPlacement: .authorHeader,
                container: .fullWidth,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 6,
                cornerRadius: 0
            )
        case .linkedIn:
            return EntryLayoutPresentation(
                horizontalPadding: 16,
                verticalPadding: 16,
                contentSpacing: 12,
                metadataPlacement: .footer,
                container: .card,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 0,
                cornerRadius: 16
            )
        case .reddit:
            return EntryLayoutPresentation(
                horizontalPadding: 12,
                verticalPadding: 14,
                contentSpacing: 10,
                metadataPlacement: .metadataHeader,
                container: .fullWidth,
                actionStyle: .compact,
                showsAvatar: false,
                separatorHeight: 4,
                cornerRadius: 0
            )
        case .reader:
            return EntryLayoutPresentation(
                horizontalPadding: 22,
                verticalPadding: 24,
                contentSpacing: 20,
                metadataPlacement: .footer,
                container: .fullWidth,
                actionStyle: .quiet,
                showsAvatar: false,
                separatorHeight: 8,
                cornerRadius: 0
            )
        case .terminal:
            return EntryLayoutPresentation(
                horizontalPadding: 14,
                verticalPadding: 12,
                contentSpacing: 10,
                metadataPlacement: .metadataHeader,
                container: .fullWidth,
                actionStyle: .compact,
                showsAvatar: false,
                separatorHeight: 1,
                cornerRadius: 0
            )
        case .minimal:
            return EntryLayoutPresentation(
                horizontalPadding: 14,
                verticalPadding: 12,
                contentSpacing: 10,
                metadataPlacement: .inlineFooter,
                container: .fullWidth,
                actionStyle: .compact,
                showsAvatar: false,
                separatorHeight: 1,
                cornerRadius: 0
            )
        }
    }

    static func resolve(storedValue: String?) -> EntryLayoutStyle {
        guard let storedValue else { return .classic }
        if let style = EntryLayoutStyle(rawValue: storedValue) {
            return style
        }

        switch storedValue {
        case "compact": return .xFeed
        case "comfortable", "focus": return .reader
        case "card": return .linkedIn
        case "authorFirst": return .instagram
        case "metadataFirst": return .terminal
        default: return .classic
        }
    }
}

struct EntryLayoutPresentation: Equatable, Sendable {
    enum MetadataPlacement: Equatable, Sendable {
        case footer
        case inlineFooter
        case authorHeader
        case metadataHeader
    }

    enum Container: Equatable, Sendable {
        case fullWidth
        case card
    }

    enum ActionStyle: Equatable, Sendable {
        case standard
        case compact
        case quiet
    }

    let horizontalPadding: Double
    let verticalPadding: Double
    let contentSpacing: Double
    let metadataPlacement: MetadataPlacement
    let container: Container
    let actionStyle: ActionStyle
    let showsAvatar: Bool
    let separatorHeight: Double
    let cornerRadius: Double
}
