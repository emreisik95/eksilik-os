import SwiftUI

struct MessageComposeView: View {
    let recipient: String
    let subject: String

    @State private var messageText = ""
    @State private var isLoading = false
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.Message.to)
                    .foregroundColor(.gray)
                Text(recipient)
                    .foregroundColor(themeManager.current.accentColor)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            TextEditor(text: $messageText)
                .padding(8)
                .foregroundColor(themeManager.current.labelColor)
                .scrollContentBackground(.hidden)
                .background(themeManager.current.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.current.accentColor, lineWidth: 0.5)
                )
                .padding()
        }
        .navigationTitle(L10n.Message.newMessage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.Message.send) {
                    Task { await sendMessage() }
                }
                .foregroundColor(themeManager.current.accentColor)
                .disabled(messageText.isEmpty || isLoading)
            }
        }
        .background(themeManager.current.backgroundColor)
        .overlay { if isLoading { LoadingView() } }
    }

    private func sendMessage() async {
        isLoading = true
        do {
            try await HTTPClient.shared.post(
                endpoint: .sendMessage,
                body: [
                    "To": recipient,
                    "Message": messageText,
                    "Title": subject
                ]
            )
            dismiss()
        } catch {
            isLoading = false
        }
    }
}
