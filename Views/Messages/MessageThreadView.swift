import SwiftUI

struct MessageThreadView: View {
    @StateObject private var viewModel: MessageThreadViewModel
    @StateObject private var composer: MessageComposeViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var preferences: UserPreferences
    @FocusState private var composerIsFocused: Bool

    private let bottomAnchor = "message-thread-bottom"

    init(link: String, title: String) {
        _viewModel = StateObject(
            wrappedValue: MessageThreadViewModel(link: link, title: title)
        )
        _composer = StateObject(
            wrappedValue: MessageComposeViewModel(
                recipient: title,
                subject: "",
                threadID: link
            )
        )
    }

    var body: some View {
        conversation
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(viewModel.threadTitle)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerBar
            }
            .task {
                guard viewModel.messages.isEmpty else { return }
                await viewModel.loadMessages()
            }
            .alert(L10n.Message.sendFailed, isPresented: composerErrorBinding) {
                Button("tamam", role: .cancel) { composer.error = nil }
            } message: {
                Text(composer.error ?? "")
            }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            Group {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.messages.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadMessages() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: messageSpacing) {
                            if viewModel.messages.isEmpty {
                                EmptyStateView(message: L10n.Message.noMessages)
                                    .padding(.top, 80)
                            } else {
                                ForEach(viewModel.messages) { message in
                                    messageBubble(message)
                                        .id(message.id)
                                }
                            }

                            Color.clear
                                .frame(height: 1)
                                .id(bottomAnchor)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    }
                    .refreshable { await viewModel.loadMessages() }
                }
            }
            .onChange(of: viewModel.messages.last?.id) { _ in
                scrollToBottom(proxy, animated: true)
            }
            .onChange(of: composer.sendGeneration) { _ in
                scrollToBottom(proxy, animated: true)
            }
        }
    }

    private func messageBubble(_ message: Message) -> some View {
        let side = MessageBubblePresentation.side(
            direction: message.direction,
            sender: message.sender,
            currentUsername: session.username
        )
        let isOutgoing = side == .trailing

        return HStack(alignment: .bottom, spacing: 8) {
            if isOutgoing {
                Spacer(minLength: 54)
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 5) {
                senderLabel(message, isOutgoing: isOutgoing)
                bubbleText(message, isOutgoing: isOutgoing)
                dateLabel(message)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isOutgoing ? "gönderdiğin mesaj" : "gelen mesaj")

            if !isOutgoing {
                Spacer(minLength: 54)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func senderLabel(_ message: Message, isOutgoing: Bool) -> some View {
        if !isOutgoing, !message.sender.isEmpty {
            Text(message.sender)
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.current.accentColor)
                .padding(.horizontal, 4)
        }
    }

    private func bubbleText(_ message: Message, isOutgoing: Bool) -> some View {
        Text(message.contentText)
            .font(.system(size: CGFloat(preferences.selectedFontSize)))
            .foregroundColor(isOutgoing
                ? themeManager.current.backgroundColor
                : themeManager.current.entryTextColor)
            .textSelection(.enabled)
            .padding(.horizontal, bubbleHorizontalPadding)
            .padding(.vertical, bubbleVerticalPadding)
            .background(
                isOutgoing ? themeManager.current.accentColor : themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: bubbleCornerRadius, style: .continuous)
            )
            .overlay {
                if !isOutgoing {
                    RoundedRectangle(cornerRadius: bubbleCornerRadius, style: .continuous)
                        .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
                }
            }
    }

    @ViewBuilder
    private func dateLabel(_ message: Message) -> some View {
        if !message.date.isEmpty {
            Text(message.date)
                .font(.caption2)
                .foregroundColor(themeManager.current.dateColor)
                .padding(.horizontal, 4)
        }
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(L10n.Message.placeholder, text: $composer.messageText, axis: .vertical)
                .focused($composerIsFocused)
                .font(.system(size: CGFloat(preferences.selectedFontSize)))
                .foregroundColor(themeManager.current.labelColor)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    themeManager.current.cellPrimaryColor,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeManager.current.separatorColor.opacity(0.3), lineWidth: 1)
                }
                .accessibilityLabel(L10n.Message.placeholder)

            Button {
                Task { await sendReply() }
            } label: {
                Group {
                    if composer.isSending {
                        ProgressView()
                            .tint(themeManager.current.backgroundColor)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundColor(themeManager.current.backgroundColor)
                .frame(width: 44, height: 44)
                .background(
                    composer.canSend
                        ? themeManager.current.accentColor
                        : themeManager.current.dateColor.opacity(0.32),
                    in: Circle()
                )
            }
            .buttonStyle(.plain)
            .disabled(!composer.canSend)
            .accessibilityLabel(L10n.Message.send)
            .accessibilityHint("yanıtı bu konuşmaya gönderir")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().overlay(themeManager.current.separatorColor.opacity(0.2))
        }
    }

    @MainActor
    private func sendReply() async {
        let generation = composer.sendGeneration
        await composer.send(csrfToken: session.csrfToken)
        guard composer.sendGeneration != generation else { return }
        await viewModel.loadMessages()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        let action = { proxy.scrollTo(bottomAnchor, anchor: .bottom) }
        if animated {
            withAnimation(.easeOut(duration: 0.22), action)
        } else {
            action()
        }
    }

    private var messageSpacing: CGFloat {
        CGFloat(10 + max(0, preferences.selectedFontSize - 15))
    }

    private var horizontalPadding: CGFloat {
        CGFloat(12 + max(0, preferences.selectedFontSize - 15) / 2)
    }

    private var bubbleHorizontalPadding: CGFloat {
        CGFloat(14 + max(0, preferences.selectedFontSize - 15) / 2)
    }

    private var bubbleVerticalPadding: CGFloat {
        CGFloat(10 + max(0, preferences.selectedFontSize - 15) / 3)
    }

    private var bubbleCornerRadius: CGFloat {
        CGFloat(18 + max(0, preferences.selectedFontSize - 15) / 3)
    }

    private var composerErrorBinding: Binding<Bool> {
        Binding(
            get: { composer.error != nil },
            set: { if !$0 { composer.error = nil } }
        )
    }
}
