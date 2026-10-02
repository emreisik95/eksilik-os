import Foundation

/// Text form of a custom theme: `eksilik-tema:` followed by base64 JSON. Small enough to paste
/// into a message, versioned so older apps can refuse codes they do not understand.
enum ThemeShareCode {
    static let prefix = "eksilik-tema:"
    static let currentVersion = 1
    static let maximumLength = 4_096

    enum DecodeError: Error, Equatable {
        case missingPrefix
        case tooLong
        case invalidEncoding
        case invalidPayload
        case unsupportedVersion

        var message: String {
            switch self {
            case .missingPrefix: return "kod \"\(ThemeShareCode.prefix)\" ile başlamalı"
            case .tooLong: return "kod çok uzun"
            case .invalidEncoding: return "kod bozuk görünüyor"
            case .invalidPayload: return "kodda eksik ya da hatalı renk var"
            case .unsupportedVersion: return "bu kod uygulamanın daha yeni bir sürümüyle oluşturulmuş"
            }
        }
    }

    static func encode(_ theme: CustomTheme) -> String {
        let payload = Payload(
            version: currentVersion,
            name: theme.name,
            base: theme.baseTheme.rawValue,
            palette: theme.palette
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Encoding plain strings and ints cannot fail; an empty payload would be rejected on import.
        let data = (try? encoder.encode(payload)) ?? Data()
        return prefix + data.base64EncodedString()
    }

    /// Imports always get a fresh id so pasting a code can never overwrite an existing theme.
    static func decode(_ code: String) -> Result<CustomTheme, DecodeError> {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return .failure(.missingPrefix) }
        guard trimmed.count <= maximumLength else { return .failure(.tooLong) }

        let body = trimmed.dropFirst(prefix.count).filter { !$0.isWhitespace }
        guard let data = Data(base64Encoded: String(body)) else { return .failure(.invalidEncoding) }

        guard let header = try? JSONDecoder().decode(VersionHeader.self, from: data) else {
            return .failure(.invalidPayload)
        }
        guard header.version <= currentVersion else { return .failure(.unsupportedVersion) }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return .failure(.invalidPayload)
        }

        return .success(CustomTheme(
            name: CustomTheme.sanitizedName(payload.name),
            baseTheme: AppTheme(rawValue: payload.base) ?? .dark,
            palette: payload.palette
        ))
    }

    private struct VersionHeader: Decodable {
        let version: Int
    }

    private struct Payload: Codable {
        let version: Int
        let name: String
        let base: Int
        let palette: ThemePalette
    }
}
