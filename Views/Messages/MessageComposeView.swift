import SwiftUI

struct MessageComposeView: View {
    @StateObject private var viewModel: MessageComposeViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field { case recipient, message }

    init(recipient: String, subject: String, threadID: String?) {
        _viewModel = StateObject(
            wrappedValue: MessageComposeViewModel(
                recipient: recipient,
                subject: subject,
                threadID: threadID
            )
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            recipientCard

            if !viewModel.subject.isEmpty {
                Label(viewModel.subject, systemImage: "text.quote")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.messageText.isEmpty {
                    Text(L10n.Message.placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.messageText)
                    .focused($focusedField, equals: .message)
                    .font(.body)
                    .foregroundColor(themeManager.current.labelColor)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .accessibilityLabel(L10n.Message.placeholder)
            }
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(themeManager.current.separatorColor.opacity(0.35), lineWidth: 1)
            }

            HStack {
                Text("\(viewModel.messageText.count) karakter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("taslak gönderilene kadar korunur")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .navigationTitle(L10n.Message.newMessage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.send(csrfToken: session.csrfToken) }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                    } else {
                        Text(L10n.Message.send)
                            .fontWeight(.bold)
                    }
                }
                .disabled(!viewModel.canSend)
                .accessibilityHint("mesajı gönderir")
            }
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .onAppear {
            focusedField = viewModel.isRecipientLocked ? .message : .recipient
        }
        .onChange(of: viewModel.didSend) { didSend in
            if didSend { dismiss() }
        }
        .alert(L10n.Message.sendFailed, isPresented: errorBinding) {
            Button("tamam", role: .cancel) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var recipientCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .foregroundColor(themeManager.current.accentColor)
            Text(L10n.Message.recipientLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if viewModel.isRecipientLocked {
                Text(viewModel.recipient)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(1)
            } else {
                TextField(L10n.Message.recipientPlaceholder, text: $viewModel.recipient)
                    .focused($focusedField, equals: .recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(themeManager.current.labelColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .message }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(
            themeManager.current.cellSecondaryColor,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
}
