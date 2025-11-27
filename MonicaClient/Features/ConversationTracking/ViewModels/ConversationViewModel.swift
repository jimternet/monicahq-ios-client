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
    @Published var notes: String = ""  // Legacy - kept for backwards compat
    @Published var selectedConversationType: Int?  // Optional contact_field_type_id

    // Messages form state (replaces notes)
    @Published var formMessages: [FormMessage] = []

    /// Represents a message being edited in the form
    ///
    /// # Form Message Editing Pattern
    ///
    /// This struct supports both new messages and editing existing messages from the server.
    /// Key features:
    ///
    /// ## New Messages
    /// - Created with `init()` - no existingMessageId
    /// - Will be sent via `POST /api/conversations/{id}/messages`
    ///
    /// ## Existing Messages
    /// - Created with `init(from: ConversationMessage)` - stores original values
    /// - Tracks changes via `hasChanges` computed property
    /// - Modified messages sent via `PUT /api/conversations/{id}/messages/{messageId}`
    /// - Removed messages (not in formMessages) trigger `DELETE` API calls
    ///
    /// ## Change Detection
    /// Original values (`originalContent`, `originalWrittenByMe`) are stored when loading
    /// existing messages. The `hasChanges` property compares current values to originals
    /// to determine if an API update is needed.
    struct FormMessage: Identifiable {
        let id: UUID
        var content: String
        var writtenByMe: Bool
        /// API message ID if this is an existing message (nil for new messages)
        let existingMessageId: Int?
        /// Original content for change detection (only set for existing messages)
        let originalContent: String?
        /// Original writtenByMe for change detection (only set for existing messages)
        let originalWrittenByMe: Bool?

        /// Whether this is an existing message from the server
        var isExisting: Bool { existingMessageId != nil }

        /// Whether this existing message has been modified
        var hasChanges: Bool {
            guard isExisting else { return false }
            return content != originalContent || writtenByMe != originalWrittenByMe
        }

        init(id: UUID = UUID(), content: String = "", writtenByMe: Bool = true) {
            self.id = id
            self.content = content
            self.writtenByMe = writtenByMe
            self.existingMessageId = nil
            self.originalContent = nil
            self.originalWrittenByMe = nil
        }

        /// Create from existing API message (editable, with change tracking)
        init(from message: ConversationMessage) {
            self.id = UUID()
            self.content = message.content
            self.writtenByMe = message.writtenByMe
            self.existingMessageId = message.id
            self.originalContent = message.content
            self.originalWrittenByMe = message.writtenByMe
        }
    }

    // Contact field types cache
    @Published var contactFieldTypes: [ContactFieldType] = []
    @Published var isLoadingFieldTypes = false

    // Edit mode
    @Published var editingConversation: Conversation?

    // MARK: - Dependencies

    private let apiService: ConversationAPIService
    private let contactId: Int
    private let userDefaults = UserDefaultsService()

    /// Contact name for display in message threads
    let contactName: String

    // MARK: - Initialization

    init(contactId: Int, contactName: String = "Contact", apiService: ConversationAPIService) {
        self.contactId = contactId
        self.contactName = contactName
        self.apiService = apiService
    }

    // MARK: - Data Loading

    /// Load conversations for the contact from the API
    func loadConversations() async {
        // Use Task.yield to avoid publishing during view updates
        await Task.yield()

        isLoading = true
        errorMessage = nil

        do {
            let fetchedConversations = try await apiService.fetchConversations(for: contactId)
            conversations = fetchedConversations
            // Debug: log loaded conversations and their messages
            for conv in fetchedConversations {
                print("📝 Conversation \(conv.id): \(conv.messages.count) messages")
                for msg in conv.messages {
                    print("   - Message \(msg.id): \"\(msg.content.prefix(50))...\"")
                }
            }
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load conversations: \(error)")
        }

        isLoading = false
    }

    /// Load contact field types from the API (cached)
    func loadContactFieldTypes() async {
        // Don't reload if already loaded
        guard contactFieldTypes.isEmpty else { return }

        // Use Task.yield to avoid publishing during view updates
        await Task.yield()

        isLoadingFieldTypes = true

        do {
            let types = try await apiService.fetchContactFieldTypes()
            contactFieldTypes = types
            print("✅ Loaded \(types.count) contact field types: \(types.map { "\($0.name) (id: \($0.id))" }.joined(separator: ", "))")

            // Set default type if not already set
            if selectedConversationType == nil {
                // Check for user-configured default first
                if let savedDefault = userDefaults.defaultConversationType,
                   types.contains(where: { $0.id == savedDefault }) {
                    selectedConversationType = savedDefault
                    let typeName = types.first(where: { $0.id == savedDefault })?.name ?? "Unknown"
                    print("📌 Using saved default conversation type: \(typeName) (id: \(savedDefault))")
                } else if let firstType = types.first {
                    // Fall back to first available type
                    selectedConversationType = firstType.id
                    print("📌 Using first available conversation type: \(firstType.name) (id: \(firstType.id))")
                }
            }
            isLoadingFieldTypes = false
        } catch {
            print("❌ Failed to load contact field types: \(error)")
            errorMessage = "Failed to load conversation types. Please try again."
            showingError = true
            isLoadingFieldTypes = false
        }
    }

    /// Set the default conversation type for future conversations
    func setDefaultConversationType(_ typeId: Int?) {
        userDefaults.defaultConversationType = typeId
        if let typeId = typeId {
            let typeName = contactFieldTypes.first(where: { $0.id == typeId })?.name ?? "Unknown"
            print("💾 Saved default conversation type: \(typeName) (id: \(typeId))")
        } else {
            print("💾 Cleared default conversation type")
        }
    }

    /// Get the current default conversation type ID
    var defaultConversationTypeId: Int? {
        userDefaults.defaultConversationType
    }

    // MARK: - Create/Update Operations

    /// Save a new conversation directly to API (Monica v4.x API fields)
    func saveConversation() async {
        guard validateForm() else { return }

        // Ensure we have a valid contact field type ID
        guard let typeId = selectedConversationType else {
            await MainActor.run {
                errorMessage = "Please select a conversation type"
                showingError = true
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Convert form messages to API message data
            let messageData = nonEmptyMessages.map {
                ConversationAPIService.MessageData(content: $0.content, writtenByMe: $0.writtenByMe)
            }

            print("📋 Form state:")
            print("   formMessages count: \(formMessages.count)")
            print("   nonEmptyMessages count: \(nonEmptyMessages.count)")
            for (i, msg) in formMessages.enumerated() {
                print("   Message \(i): content=\"\(msg.content.prefix(30))\" writtenByMe=\(msg.writtenByMe)")
            }
            print("   messageData count: \(messageData.count)")

            if messageData.isEmpty {
                // Quick log - no messages
                let formatter = ISO8601DateFormatter()
                let payload = ConversationCreatePayload(
                    contactId: contactId,
                    happenedAt: formatter.string(from: happenedAt),
                    contactFieldTypeId: typeId,
                    content: nil
                )
                _ = try await apiService.createConversation(payload)
            } else {
                // Create with multiple messages
                _ = try await apiService.createConversationWithMessages(
                    contactId: contactId,
                    happenedAt: happenedAt,
                    contactFieldTypeId: typeId,
                    messages: messageData
                )
            }

            await MainActor.run {
                isLoading = false
            }

            // Defer reload and reset to avoid publishing during view update
            await Task.yield()
            await loadConversations()
            await MainActor.run {
                resetForm()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save conversation: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
            print("❌ Failed to save conversation: \(error)")
        }
    }

    /// Update an existing conversation directly via API (Monica v4.x API fields)
    /// Full editing: update modified messages, delete removed ones, add new ones
    func updateConversation() async {
        guard let conversation = editingConversation else { return }
        guard validateForm() else { return }

        guard let typeId = selectedConversationType else {
            await MainActor.run {
                errorMessage = "Please select a conversation type"
                showingError = true
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Find which existing messages were deleted (not in current form)
            let originalMessageIds = Set(conversation.messages.map { $0.id })
            let keptMessageIds = Set(existingMessageIdsToKeep)
            let deletedMessageIds = originalMessageIds.subtracting(keptMessageIds)

            // Get modified existing messages
            let messagesToUpdate = modifiedExistingMessages.compactMap { msg -> ConversationAPIService.ExistingMessageUpdate? in
                guard let messageId = msg.existingMessageId else { return nil }
                return ConversationAPIService.ExistingMessageUpdate(
                    messageId: messageId,
                    content: msg.content,
                    writtenByMe: msg.writtenByMe
                )
            }

            print("📋 Update conversation \(conversation.id):")
            print("   Original messages: \(originalMessageIds)")
            print("   Kept messages: \(keptMessageIds)")
            print("   To delete: \(deletedMessageIds)")
            print("   Modified existing: \(messagesToUpdate.count)")
            print("   New messages to add: \(newMessages.count)")

            // Get only NEW messages to add (not existing ones)
            let newMessageData = newMessages.map {
                ConversationAPIService.MessageData(content: $0.content, writtenByMe: $0.writtenByMe)
            }

            // Full update: update modified, delete removed, add new
            try await apiService.updateConversationFull(
                conversationId: conversation.id,
                contactId: conversation.contactId,
                happenedAt: happenedAt,
                contactFieldTypeId: typeId,
                messagesToUpdate: messagesToUpdate,
                messageIdsToDelete: Array(deletedMessageIds),
                newMessages: newMessageData
            )

            await MainActor.run {
                isLoading = false
            }

            // Defer reload and reset to avoid publishing during view update
            await Task.yield()
            await loadConversations()
            await MainActor.run {
                editingConversation = nil
                resetForm()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update conversation: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
            print("❌ Failed to update conversation: \(error)")
        }
    }

    // MARK: - Delete Operations

    /// Delete a conversation directly via API
    func deleteConversation(_ conversation: Conversation) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try await apiService.deleteConversation(id: conversation.id)

            // Refresh list from server
            await loadConversations()

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
            print("❌ Failed to delete conversation: \(error)")
        }
    }

    // MARK: - Quick Log

    /// Quick log a conversation with current date and no notes
    func quickLogConversation() async {
        // Ensure we have a valid contact field type
        if contactFieldTypes.isEmpty {
            await loadContactFieldTypes()
        }

        // Use saved default first, then fall back to first available
        let typeId: Int
        if let savedDefault = defaultConversationTypeId,
           contactFieldTypes.contains(where: { $0.id == savedDefault }) {
            typeId = savedDefault
            let typeName = contactFieldTypes.first(where: { $0.id == savedDefault })?.name ?? "Unknown"
            print("📌 Quick log using saved default type: \(typeName) (id: \(savedDefault))")
        } else if let firstType = contactFieldTypes.first {
            typeId = firstType.id
            print("📌 Quick log using first available type: \(firstType.name) (id: \(firstType.id))")
        } else {
            errorMessage = "No conversation type available. Please try again."
            showingError = true
            return
        }

        // Use Task.yield to avoid publishing during view updates
        await Task.yield()

        isLoading = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            let payload = ConversationCreatePayload(
                contactId: contactId,
                happenedAt: formatter.string(from: Date()),
                contactFieldTypeId: typeId,
                content: nil
            )

            _ = try await apiService.createConversation(payload)

            isLoading = false
            await loadConversations()
        } catch {
            errorMessage = "Failed to quick log conversation: \(error.localizedDescription)"
            showingError = true
            isLoading = false
            print("❌ Failed to quick log conversation: \(error)")
        }
    }

    // MARK: - Form Management

    /// Load conversation data into form for editing
    func loadForEditing(_ conversation: Conversation) {
        print("📝 loadForEditing called for conversation \(conversation.id)")
        print("   conversation.messages.count: \(conversation.messages.count)")
        for msg in conversation.messages {
            print("   - Message \(msg.id): \"\(msg.content.prefix(30))\" writtenByMe=\(msg.writtenByMe)")
        }

        editingConversation = conversation
        happenedAt = conversation.happenedAt
        selectedConversationType = conversation.contactFieldTypeId
        notes = conversation.content ?? ""

        // Load existing messages
        if conversation.messages.isEmpty {
            // If no messages, start with one empty message
            formMessages = [FormMessage()]
            print("   -> No messages, initialized with empty FormMessage")
        } else {
            formMessages = conversation.messages.map { FormMessage(from: $0) }
            print("   -> Loaded \(formMessages.count) form messages")
        }
    }

    /// Reset form to initial state
    func resetForm() {
        happenedAt = Date()
        notes = ""
        selectedConversationType = nil
        editingConversation = nil
        formMessages = [FormMessage()]  // Start with one empty message
    }

    /// Add a new empty message to the form
    func addMessage() {
        formMessages.append(FormMessage())
    }

    /// Remove a message from the form
    /// For existing messages, this marks them for deletion on save
    func removeMessage(at index: Int) {
        // Allow removing if we have more than one message, OR if removing an existing message
        // (we always want at least one new message input available)
        guard formMessages.count > 1 || formMessages[index].isExisting else { return }
        formMessages.remove(at: index)

        // If no messages left, add an empty one for new input
        if formMessages.isEmpty {
            formMessages.append(FormMessage())
        }
    }

    /// Get non-empty messages for saving
    var nonEmptyMessages: [FormMessage] {
        formMessages.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Get existing messages (from server)
    var existingMessages: [FormMessage] {
        formMessages.filter { $0.isExisting }
    }

    /// Get existing messages that have been modified
    var modifiedExistingMessages: [FormMessage] {
        formMessages.filter { $0.isExisting && $0.hasChanges }
    }

    /// Get new messages (editable, to be created)
    var newMessages: [FormMessage] {
        formMessages.filter { !$0.isExisting && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Get IDs of existing messages that should be kept (not deleted)
    var existingMessageIdsToKeep: [Int] {
        formMessages.compactMap { $0.existingMessageId }
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
