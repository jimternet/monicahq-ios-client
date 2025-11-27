//
//  ConversationAPIService.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

/// API service for conversations using Monica v4.x /api/conversations endpoint
///
/// # Monica v4.x Conversations API Learnings
///
/// ## Two-Step Creation Process
/// Creating a conversation with messages requires two API calls:
/// 1. `POST /api/conversations` - Creates the conversation container
/// 2. `POST /api/conversations/{id}/messages` - Adds each message
///
/// ## Message Field Name Requirements
/// The API is strict about field names in the message payload:
/// - ✅ `written_by_me` (boolean) - Correct field name
/// - ❌ `written` - Will be ignored, messages won't save sender correctly
/// - ❌ `writtenByMe` - Wrong casing, will be ignored
///
/// ## Message Payload Structure
/// ```json
/// {
///     "contact_id": 123,
///     "written_at": "2025-01-15",   // Date format: yyyy-MM-dd
///     "written_by_me": true,         // Boolean: true = user, false = contact
///     "content": "Message text"
/// }
/// ```
///
/// ## Full Message Editing
/// Unlike some assumptions, Monica fully supports editing existing messages:
/// - `PUT /api/conversations/{id}/messages/{messageId}` - Update content and sender
/// - `DELETE /api/conversations/{id}/messages/{messageId}` - Remove a message
///
/// This service provides methods for all CRUD operations on conversations and messages.
@MainActor
class ConversationAPIService {
    private let apiClient: MonicaAPIClient

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Conversation API Methods (Monica v4.x)

    /// Fetch all conversations for a contact from the server
    /// Uses GET /api/contacts/{id}/conversations endpoint
    /// Messages may be embedded in the response depending on Monica version
    func fetchConversations(for contactId: Int) async throws -> [Conversation] {
        let response: ConversationsResponse = try await apiClient.getConversations(for: contactId)
        // Messages should be embedded in the conversation response from the API
        // The raw JSON logging will show us what fields are available
        return response.data
    }

    /// Create a conversation on the server via POST /api/conversations endpoint
    /// Monica API requires two steps: 1) create conversation, 2) add messages
    /// Monica v4.x fields: contact_id, happened_at, contact_field_type_id (required)
    func createConversation(_ payload: ConversationCreatePayload) async throws -> Conversation {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: payload.happenedAt) ?? Date()

        print("🔄 Creating conversation - Step 1: Create conversation container")
        print("   Contact ID: \(payload.contactId)")
        print("   Happened At: \(payload.happenedAt)")
        print("   Field Type ID: \(payload.contactFieldTypeId)")
        print("   Content: \(payload.content ?? "nil")")

        // Step 1: Create the conversation
        let response: APIResponse<Conversation> = try await apiClient.createConversation(for: payload.contactId, happenedAt: date, contactFieldTypeId: payload.contactFieldTypeId, content: nil)
        let conversation = response.data
        print("✅ Step 1 complete - Conversation created with ID: \(conversation.id)")

        // Step 2: Add message if content was provided
        if let content = payload.content, !content.isEmpty {
            print("🔄 Step 2: Adding message to conversation \(conversation.id)")
            print("   Content length: \(content.count) characters")
            do {
                try await apiClient.addMessageToConversation(
                    conversationId: conversation.id,
                    contactId: payload.contactId,
                    content: content,
                    writtenByMe: true,
                    writtenAt: date
                )
                print("✅ Step 2 complete - Message added")
            } catch {
                print("❌ Step 2 FAILED - Error adding message: \(error)")
                // Don't throw - conversation was created, just message failed
            }
        } else {
            print("ℹ️ Step 2 skipped - No content provided (quick log)")
        }

        return conversation
    }

    /// Message data for creating conversations with multiple messages
    struct MessageData {
        let content: String
        let writtenByMe: Bool
    }

    /// Create a conversation with multiple messages
    /// Monica API requires: 1) create conversation, 2) add each message
    func createConversationWithMessages(
        contactId: Int,
        happenedAt: Date,
        contactFieldTypeId: Int,
        messages: [MessageData]
    ) async throws -> Conversation {
        print("🔄 Creating conversation with \(messages.count) messages")
        print("   Contact ID: \(contactId)")
        print("   Field Type ID: \(contactFieldTypeId)")

        // Step 1: Create the conversation
        let response: APIResponse<Conversation> = try await apiClient.createConversation(
            for: contactId,
            happenedAt: happenedAt,
            contactFieldTypeId: contactFieldTypeId,
            content: nil
        )
        let conversation = response.data
        print("✅ Conversation created with ID: \(conversation.id)")

        // Step 2: Add each message
        for (index, message) in messages.enumerated() {
            print("🔄 Adding message \(index + 1)/\(messages.count): \"\(message.content.prefix(30))...\"")
            do {
                try await apiClient.addMessageToConversation(
                    conversationId: conversation.id,
                    contactId: contactId,
                    content: message.content,
                    writtenByMe: message.writtenByMe,
                    writtenAt: happenedAt
                )
                print("✅ Message \(index + 1) added")
            } catch {
                print("❌ Message \(index + 1) FAILED: \(error)")
                // Continue adding other messages even if one fails
            }
        }

        return conversation
    }

    /// Update a conversation on the server via PUT /api/conversations/{id} endpoint
    /// Monica v4.x fields: happened_at (optional), contact_field_type_id (optional), content (optional)
    func updateConversation(id: Int, _ payload: ConversationUpdatePayload) async throws -> Conversation {
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)

        let data = try await apiClient.makeRequest(endpoint: "/conversations/\(id)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ConversationSingleResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode updated conversation: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Delete a conversation from the server via DELETE /api/conversations/{id} endpoint
    func deleteConversation(id: Int) async throws {
        _ = try await apiClient.makeRequest(endpoint: "/conversations/\(id)", method: "DELETE")
        print("✅ Successfully deleted conversation \(id)")
    }

    /// Update a conversation with new messages
    /// Strategy: Update metadata, then add only NEW messages (messages not already in existing list)
    /// Note: Monica API may not support deleting individual messages, so we only add new ones
    func updateConversationWithMessages(
        conversationId: Int,
        contactId: Int,
        happenedAt: Date,
        contactFieldTypeId: Int,
        existingMessageIds: [Int],
        newMessages: [MessageData]
    ) async throws {
        print("🔄 Updating conversation \(conversationId)")
        print("   Existing messages: \(existingMessageIds.count)")
        print("   New messages to save: \(newMessages.count)")

        // Step 1: Update conversation metadata
        let formatter = ISO8601DateFormatter()
        let payload = ConversationUpdatePayload(
            happenedAt: formatter.string(from: happenedAt),
            contactFieldTypeId: contactFieldTypeId,
            content: nil
        )
        _ = try await updateConversation(id: conversationId, payload)
        print("✅ Conversation metadata updated")

        // Step 2: Try to delete existing messages (may fail if API doesn't support it)
        var deletedCount = 0
        for messageId in existingMessageIds {
            do {
                try await apiClient.deleteMessageFromConversation(conversationId: conversationId, messageId: messageId)
                deletedCount += 1
            } catch {
                print("⚠️ Could not delete message \(messageId) - API may not support message deletion")
                // Don't continue trying to delete if first one fails
                break
            }
        }
        print("📝 Deleted \(deletedCount) of \(existingMessageIds.count) existing messages")

        // Step 3: Add new messages
        for (index, message) in newMessages.enumerated() {
            print("🔄 Adding message \(index + 1)/\(newMessages.count): \"\(message.content.prefix(30))...\"")
            do {
                try await apiClient.addMessageToConversation(
                    conversationId: conversationId,
                    contactId: contactId,
                    content: message.content,
                    writtenByMe: message.writtenByMe,
                    writtenAt: happenedAt
                )
                print("✅ Message \(index + 1) added")
            } catch {
                print("❌ Message \(index + 1) FAILED: \(error)")
                // Throw so we know there's an issue
                throw error
            }
        }

        print("✅ Conversation update complete")
    }

    /// Simplified update: only delete specified messages and add new ones
    /// Does not try to update existing messages (they remain read-only)
    func updateConversationSimplified(
        conversationId: Int,
        contactId: Int,
        happenedAt: Date,
        contactFieldTypeId: Int,
        messageIdsToDelete: [Int],
        newMessages: [MessageData]
    ) async throws {
        print("🔄 Simplified update for conversation \(conversationId)")
        print("   Messages to delete: \(messageIdsToDelete.count)")
        print("   New messages to add: \(newMessages.count)")

        // Step 1: Update conversation metadata
        let formatter = ISO8601DateFormatter()
        let payload = ConversationUpdatePayload(
            happenedAt: formatter.string(from: happenedAt),
            contactFieldTypeId: contactFieldTypeId,
            content: nil
        )
        _ = try await updateConversation(id: conversationId, payload)
        print("✅ Conversation metadata updated")

        // Step 2: Delete messages that were removed
        for messageId in messageIdsToDelete {
            do {
                try await apiClient.deleteMessageFromConversation(conversationId: conversationId, messageId: messageId)
                print("✅ Deleted message \(messageId)")
            } catch {
                print("⚠️ Could not delete message \(messageId): \(error)")
                // Continue - deletion may not be supported or message already gone
            }
        }

        // Step 3: Add only new messages
        for (index, message) in newMessages.enumerated() {
            print("🔄 Adding new message \(index + 1)/\(newMessages.count): \"\(message.content.prefix(30))...\"")
            try await apiClient.addMessageToConversation(
                conversationId: conversationId,
                contactId: contactId,
                content: message.content,
                writtenByMe: message.writtenByMe,
                writtenAt: happenedAt
            )
            print("✅ New message \(index + 1) added")
        }

        print("✅ Simplified update complete")
    }

    /// Message update data for editing existing messages
    struct ExistingMessageUpdate {
        let messageId: Int
        let content: String
        let writtenByMe: Bool
    }

    /// Full update: update existing messages, delete removed ones, add new ones
    /// This replicates the Monica web app behavior where all messages are editable
    func updateConversationFull(
        conversationId: Int,
        contactId: Int,
        happenedAt: Date,
        contactFieldTypeId: Int,
        messagesToUpdate: [ExistingMessageUpdate],
        messageIdsToDelete: [Int],
        newMessages: [MessageData]
    ) async throws {
        print("🔄 Full update for conversation \(conversationId)")
        print("   Messages to update: \(messagesToUpdate.count)")
        print("   Messages to delete: \(messageIdsToDelete.count)")
        print("   New messages to add: \(newMessages.count)")

        // Step 1: Update conversation metadata
        let formatter = ISO8601DateFormatter()
        let payload = ConversationUpdatePayload(
            happenedAt: formatter.string(from: happenedAt),
            contactFieldTypeId: contactFieldTypeId,
            content: nil
        )
        _ = try await updateConversation(id: conversationId, payload)
        print("✅ Conversation metadata updated")

        // Step 2: Update existing messages that were modified
        for update in messagesToUpdate {
            print("🔄 Updating message \(update.messageId): \"\(update.content.prefix(30))...\"")
            try await apiClient.updateMessageInConversation(
                conversationId: conversationId,
                messageId: update.messageId,
                contactId: contactId,
                content: update.content,
                writtenByMe: update.writtenByMe,
                writtenAt: happenedAt
            )
            print("✅ Message \(update.messageId) updated")
        }

        // Step 3: Delete messages that were removed
        for messageId in messageIdsToDelete {
            do {
                try await apiClient.deleteMessageFromConversation(conversationId: conversationId, messageId: messageId)
                print("✅ Deleted message \(messageId)")
            } catch {
                print("⚠️ Could not delete message \(messageId): \(error)")
            }
        }

        // Step 4: Add new messages
        for (index, message) in newMessages.enumerated() {
            print("🔄 Adding new message \(index + 1)/\(newMessages.count): \"\(message.content.prefix(30))...\"")
            try await apiClient.addMessageToConversation(
                conversationId: conversationId,
                contactId: contactId,
                content: message.content,
                writtenByMe: message.writtenByMe,
                writtenAt: happenedAt
            )
            print("✅ New message \(index + 1) added")
        }

        print("✅ Full update complete")
    }

    /// Fetch all contact field types from the server via GET /api/contactfieldtypes endpoint
    func fetchContactFieldTypes() async throws -> [ContactFieldType] {
        let response: ContactFieldTypesResponse = try await apiClient.getContactFieldTypes()
        return response.data
    }
}
