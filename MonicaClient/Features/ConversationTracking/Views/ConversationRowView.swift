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

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Date
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .accessibilityHidden(true)

                Text(viewModel.formatDate(conversation.happenedAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Quick log indicator
                if conversation.isQuickLog {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .accessibilityLabel("Quick logged")
                }
            }
            .accessibilityElement(children: .combine)

            // Notes preview or empty state
            if let notes = conversation.notes, !notes.isEmpty {
                if isExpanded {
                    // Full notes
                    Text(notes)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                        .accessibilityLabel("Notes: \(notes)")
                } else {
                    // Preview (first 100 chars)
                    let preview = String(notes.prefix(100))
                    let needsTruncation = notes.count > 100

                    VStack(alignment: .leading, spacing: 4) {
                        Text(preview + (needsTruncation ? "..." : ""))
                            .font(.callout)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if needsTruncation {
                            Button(action: { isExpanded = true }) {
                                Text("Show more")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Show full notes")
                        }
                    }
                    .padding(.top, 4)
                }

                // Collapse button when expanded
                if isExpanded {
                    Button(action: { isExpanded = false }) {
                        Text("Show less")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Show less")
                }
            } else {
                // No notes indicator
                HStack {
                    Image(systemName: "note.text.badge.plus")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("No notes")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.top, 4)
                .accessibilityLabel("No notes added")
                .accessibilityHint("Tap to edit and add notes")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = ConversationAPIService(apiClient: apiClient)
    let viewModel = ConversationViewModel(contactId: 1, apiService: apiService)

    // Sample conversation with notes
    let conversationWithNotes = Conversation(
        id: 1,
        contactId: 1,
        happenedAt: Date(),
        contactFieldTypeId: nil,
        content: "Had a great conversation about the project. They're excited about the progress and want to schedule a follow-up meeting next week. We discussed the timeline and potential challenges. Everything looks good!",
        createdAt: Date(),
        updatedAt: Date()
    )

    // Sample quick log (no notes)
    let quickLog = Conversation(
        id: 2,
        contactId: 1,
        happenedAt: Date().addingTimeInterval(-3600),
        contactFieldTypeId: nil,
        content: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    List {
        ConversationRowView(conversation: conversationWithNotes, viewModel: viewModel)
        ConversationRowView(conversation: quickLog, viewModel: viewModel)
    }
}
