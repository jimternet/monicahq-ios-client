//
//  ConversationAPIService.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

/// API service for conversations using Monica v4.x /api/conversations endpoint
@MainActor
class ConversationAPIService {
    private let apiClient: MonicaAPIClient

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Conversation API Methods (Monica v4.x)

    /// Fetch all conversations for a contact from the server
    /// Uses GET /api/conversations?contact_id={id} endpoint
    func fetchConversations(for contactId: Int) async throws -> [Conversation] {
        let response: ConversationsResponse = try await apiClient.getConversations(for: contactId)
        return response.data
    }

    /// Create a conversation on the server via POST /api/conversations endpoint
    /// Monica v4.x fields: contact_id, happened_at, contact_field_type_id (optional), content (optional)
    func createConversation(_ payload: ConversationCreatePayload) async throws -> Conversation {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: payload.happenedAt) ?? Date()
        let response: APIResponse<Conversation> = try await apiClient.createConversation(for: payload.contactId, happenedAt: date, content: payload.content)
        return response.data
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
}
