import Foundation

enum EntryLayoutStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic
    case compact
    case comfortable
    case card
    case authorFirst
    case metadataFirst
    case focus
    case minimal

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return "klasik"
        case .compact: return "kompakt"
        case .comfortable: return "ferah"
        case .card: return "kart"
        case .authorFirst: return "yazar üstte"
        case .metadataFirst: return "bilgi üstte"
        case .focus: return "odak"
        case .minimal: return "minimal"
        }
    }

    var summary: String {
        switch self {
        case .classic: return "tanıdık ve dengeli"
        case .compact: return "ekranda daha fazla entry"
        case .comfortable: return "daha geniş okuma aralıkları"
        case .card: return "entry'leri ayrı kartlarda gösterir"
        case .authorFirst: return "yazarı içerikten önce gösterir"
        case .metadataFirst: return "tarih ve numarayı üste taşır"
        case .focus: return "içeriği ve aksiyonları öne çıkarır"
        case .minimal: return "avatar ve kalın ayraçları kaldırır"
        }
    }

    var systemImage: String {
        switch self {
        case .classic: return "rectangle.split.3x1"
        case .compact: return "list.bullet"
        case .comfortable: return "text.alignleft"
        case .card: return "rectangle.stack"
        case .authorFirst: return "person.crop.circle"
        case .metadataFirst: return "number.square"
        case .focus: return "scope"
        case .minimal: return "minus"
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
        case .compact:
            return EntryLayoutPresentation(
                horizontalPadding: 12,
                verticalPadding: 10,
                contentSpacing: 8,
                metadataPlacement: .inlineFooter,
                container: .fullWidth,
                actionStyle: .compact,
                showsAvatar: false,
                separatorHeight: 2,
                cornerRadius: 0
            )
        case .comfortable:
            return EntryLayoutPresentation(
                horizontalPadding: 20,
                verticalPadding: 22,
                contentSpacing: 18,
                metadataPlacement: .footer,
                container: .fullWidth,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 8,
                cornerRadius: 0
            )
        case .card:
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
        case .authorFirst:
            return EntryLayoutPresentation(
                horizontalPadding: 16,
                verticalPadding: 14,
                contentSpacing: 12,
                metadataPlacement: .authorHeader,
                container: .fullWidth,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 6,
                cornerRadius: 0
            )
        case .metadataFirst:
            return EntryLayoutPresentation(
                horizontalPadding: 16,
                verticalPadding: 14,
                contentSpacing: 12,
                metadataPlacement: .metadataHeader,
                container: .fullWidth,
                actionStyle: .standard,
                showsAvatar: true,
                separatorHeight: 6,
                cornerRadius: 0
            )
        case .focus:
            return EntryLayoutPresentation(
                horizontalPadding: 18,
                verticalPadding: 20,
                contentSpacing: 16,
                metadataPlacement: .footer,
                container: .fullWidth,
                actionStyle: .quiet,
                showsAvatar: false,
                separatorHeight: 3,
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
        guard let storedValue, let style = EntryLayoutStyle(rawValue: storedValue) else {
            return .classic
        }
        return style
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
