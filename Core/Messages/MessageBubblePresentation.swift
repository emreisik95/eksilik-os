import Foundation

enum MessageBubbleSide: Equatable, Sendable {
    case leading
    case trailing
}

enum MessageBubblePresentation {
    static func side(
        direction: MessageDirection,
        sender: String,
        currentUsername: String?
    ) -> MessageBubbleSide {
        switch direction {
        case .incoming:
            return .leading
        case .outgoing:
            return .trailing
        case .unknown:
            let normalizedSender = normalized(sender)
            let normalizedUsername = normalized(currentUsername ?? "")
            return !normalizedUsername.isEmpty && normalizedSender == normalizedUsername
                ? .trailing
                : .leading
        }
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "tr_TR"))
    }
}
