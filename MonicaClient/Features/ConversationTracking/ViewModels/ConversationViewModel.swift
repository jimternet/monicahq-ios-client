//
//  ConversationViewModel.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation
import SwiftUI

/// ViewModel for managing conversation operations (Backend-only)
/// Based on Monica v4.x Conversations API (verified)
@MainActor
class ConversationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var conversations: [Conversation] = []  // Using API model, not Core Data
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false

    // Form state for new/edit conversation (Monica v4.x fields only)
    @Published var happenedAt = Date()
    @Published var notes: String = ""
    @Published var selectedConversationType: Int?  // Optional contact_field_type_id

    // Edit mode
    @Published var editingConversation: Conversation?

    // MARK: - Dependencies

    private let apiService: ConversationAPIService
    private let contactId: Int

    // MARK: - Initialization

    init(contactId: Int, apiService: ConversationAPIService) {
        self.contactId = contactId
        self.apiService = apiService
    }

    // MARK: - Data Loading

    /// Load conversations for the contact from the API
    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            conversations = try await apiService.fetchConversations(for: contactId)
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load conversations: \(error)")
        }

        isLoading = false
    }

    // MARK: - Create/Update Operations

    /// Save a new conversation directly to API (Monica v4.x API fields)
    func saveConversation() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            let payload = ConversationCreatePayload(
                contactId: contactId,
                happenedAt: formatter.string(from: happenedAt),
                content: notes.isEmpty ? nil : notes,
                contactFieldTypeId: selectedConversationType
            )

            _ = try await apiService.createConversation(payload)

            // Refresh list from server
            await loadConversations()

            // Reset form
            resetForm()
        } catch {
            errorMessage = "Failed to save conversation: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to save conversation: \(error)")
        }

        isLoading = false
    }

    /// Update an existing conversation directly via API (Monica v4.x API fields)
    func updateConversation() async {
        guard let conversation = editingConversation else { return }
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            let payload = ConversationUpdatePayload(
                happenedAt: formatter.string(from: happenedAt),
                contactFieldTypeId: selectedConversationType,
                content: notes.isEmpty ? nil : notes
            )

            _ = try await apiService.updateConversation(id: conversation.id, payload)

            // Refresh list from server
            await loadConversations()

            // Clear edit state
            editingConversation = nil
            resetForm()
        } catch {
            errorMessage = "Failed to update conversation: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to update conversation: \(error)")
        }

        isLoading = false
    }

    // MARK: - Delete Operations

    /// Delete a conversation directly via API
    func deleteConversation(_ conversation: Conversation) async {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteConversation(id: conversation.id)

            // Refresh list from server
            await loadConversations()
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to delete conversation: \(error)")
        }

        isLoading = false
    }

    // MARK: - Quick Log

    /// Quick log a conversation with current date and no notes
    func quickLogConversation() async {
        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            let payload = ConversationCreatePayload(
                contactId: contactId,
                happenedAt: formatter.string(from: Date()),
                content: nil,
                contactFieldTypeId: nil
            )

            _ = try await apiService.createConversation(payload)

            // Refresh list from server
            await loadConversations()
        } catch {
            errorMessage = "Failed to quick log conversation: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to quick log conversation: \(error)")
        }

        isLoading = false
    }

    // MARK: - Form Management

    /// Load conversation data into form for editing
    func loadForEditing(_ conversation: Conversation) {
        editingConversation = conversation
        happenedAt = conversation.happenedAt
        selectedConversationType = conversation.contactFieldTypeId
        notes = conversation.content ?? ""
    }

    /// Reset form to initial state
    func resetForm() {
        happenedAt = Date()
        notes = ""
        selectedConversationType = nil
        editingConversation = nil
    }

    /// Validate form inputs
    func validateForm() -> Bool {
        // Prevent future dates
        if happenedAt > Date() {
            errorMessage = "Conversation date cannot be in the future"
            showingError = true
            return false
        }

        // Notes character limit (10,000 chars)
        if notes.count > 10_000 {
            errorMessage = "Notes cannot exceed 10,000 characters"
            showingError = true
            return false
        }

        return true
    }

    // MARK: - Computed Properties

    /// Check if currently editing a conversation
    var isEditing: Bool {
        editingConversation != nil
    }

    /// Check if form is valid and has changes
    var canSave: Bool {
        // Always allow saving - even just timestamp is valid
        return true
    }

    /// Sorted conversations (most recent first)
    var sortedConversations: [Conversation] {
        conversations.sorted { $0.happenedAt > $1.happenedAt }
    }

    /// Get character count for notes with color coding
    func notesCharacterCount() -> (count: Int, color: Color) {
        let count = notes.count
        let maxLength = 10_000

        if count >= maxLength {
            return (count, .red)
        } else if count >= maxLength * 8 / 10 {  // 80%
            return (count, .orange)
        } else if count >= maxLength * 6 / 10 {  // 60%
            return (count, .yellow)
        } else {
            return (count, .secondary)
        }
    }

    // MARK: - Statistics

    /// Get conversation statistics
    func getStatistics() -> (total: Int, withNotes: Int) {
        let withNotes = conversations.filter { $0.hasNotes }.count
        return (total: conversations.count, withNotes: withNotes)
    }

    // MARK: - Date Formatting

    /// Format date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }

        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: date)
        }
    }
}
