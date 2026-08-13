import Foundation

enum FormURLEncoder {
    private static let allowedCharacters = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "-._~"))

    static func encode(_ fields: [String: String]) -> String {
        fields.keys.sorted().map { key in
            "\(encodeComponent(key))=\(encodeComponent(fields[key] ?? ""))"
        }
        .joined(separator: "&")
    }

    private static func encodeComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
}
