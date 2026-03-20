import SwiftUI

struct ErrorView: View {
    let message: String
    var showRetry: Bool = true
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: message.contains("bulunamadı") ? "magnifyingglass" : "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            if showRetry, let retryAction {
                Button(L10n.Common.retry, action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
