//
//  ConversationRowView.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// Row view for displaying a single conversation entry
/// Based on Monica v4.x Conversations API (verified) - Backend-only
struct ConversationRowView: View {
    let conversation: Conversation
    let viewModel: ConversationViewModel
    let contactName: String

    @State private var isExpanded = false

    init(conversation: Conversation, viewModel: ConversationViewModel, contactName: String = "Contact") {
        self.conversation = conversation
        self.viewModel = viewModel
        self.contactName = contactName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Date and conversation type
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .accessibilityHidden(true)

                Text(viewModel.formatDate(conversation.happenedAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let typeName = conversation.contactFieldType?.name {
                    Text("via \(typeName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quick log indicator
                if conversation.isQuickLog {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .accessibilityLabel("Quick logged")
                }

                // Message count badge
                if conversation.messages.count > 1 {
                    Text("\(conversation.messages.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .accessibilityLabel("\(conversation.messages.count) messages")
                }
            }
            .accessibilityElement(children: .combine)

            // Messages thread or empty state
            if conversation.hasMessages {
                messagesThreadView
            } else {
                // No messages indicator (quick log)
                HStack {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("Quick log - no messages")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.top, 4)
                .accessibilityLabel("Quick log with no messages")
                .accessibilityHint("Tap to edit and add messages")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Messages Thread View

    @ViewBuilder
    private var messagesThreadView: some View {
        let messagesToShow = isExpanded ? conversation.messages : Array(conversation.messages.prefix(2))
        let hasMore = conversation.messages.count > 2

        VStack(alignment: .leading, spacing: 6) {
            ForEach(messagesToShow) { message in
                MessageBubbleView(
                    message: message,
                    contactName: contactName
                )
            }

            // Show more/less toggle
            if hasMore {
                Button(action: { isExpanded.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                        Text(isExpanded ? "Show less" : "Show \(conversation.messages.count - 2) more")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Show less messages" : "Show all \(conversation.messages.count) messages")
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Message Bubble View

/// Individual message bubble in a conversation thread
struct MessageBubbleView: View {
    let message: ConversationMessage
    let contactName: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Sender indicator
            VStack(spacing: 2) {
                Image(systemName: message.writtenByMe ? "person.fill" : "person")
                    .font(.caption)
                    .foregroundColor(message.writtenByMe ? .blue : .secondary)

                Text(message.writtenByMe ? "You" : contactName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 50)

            // Message content
            VStack(alignment: .leading, spacing: 2) {
                Text(message.content)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(message.writtenByMe ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
            )

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.writtenByMe ? "You" : contactName) said: \(message.content)")
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = ConversationAPIService(apiClient: apiClient)
    let viewModel = ConversationViewModel(contactId: 1, contactName: "Aaron", apiService: apiService)

    // Sample messages
    let sampleMessages = [
        ConversationMessage(
            id: 1,
            writtenAt: Date(),
            writtenByMe: true,
            content: "Hey, how's it going?",
            createdAt: Date(),
            updatedAt: Date()
        ),
        ConversationMessage(
            id: 2,
            writtenAt: Date(),
            writtenByMe: false,
            content: "Great! Just finished the project we discussed.",
            createdAt: Date(),
            updatedAt: Date()
        ),
        ConversationMessage(
            id: 3,
            writtenAt: Date(),
            writtenByMe: true,
            content: "That's awesome news!",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    // Sample conversation with messages
    let conversationWithMessages = Conversation(
        id: 1,
        contactId: 1,
        happenedAt: Date(),
        contactFieldTypeId: 1,
        content: nil,
        createdAt: Date(),
        updatedAt: Date(),
        messages: sampleMessages
    )

    // Sample quick log (no messages)
    let quickLog = Conversation(
        id: 2,
        contactId: 1,
        happenedAt: Date().addingTimeInterval(-3600),
        contactFieldTypeId: 1,
        content: nil,
        createdAt: Date(),
        updatedAt: Date(),
        messages: []
    )

    return List {
        ConversationRowView(conversation: conversationWithMessages, viewModel: viewModel, contactName: "Aaron")
        ConversationRowView(conversation: quickLog, viewModel: viewModel, contactName: "Aaron")
    }
}
