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
        let endpoint = "/conversations?contact_id=\(contactId)"
        let data = try await apiClient.makeRequest(endpoint: endpoint, method: "GET")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ConversationListResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode conversations: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Create a conversation on the server via POST /api/conversations endpoint
    /// Monica v4.x fields: contact_id, happened_at, contact_field_type_id (optional), notes (optional)
    func createConversation(_ request: ConversationCreateRequest) async throws -> Conversation {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)

        let data = try await apiClient.makeRequest(endpoint: "/conversations", method: "POST", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ConversationResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode created conversation: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Update a conversation on the server via PUT /api/conversations/{id} endpoint
    /// Monica v4.x fields: happened_at (optional), contact_field_type_id (optional), notes (optional)
    func updateConversation(id: Int, _ request: ConversationUpdateRequest) async throws -> Conversation {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(request)

        let data = try await apiClient.makeRequest(endpoint: "/conversations/\(id)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ConversationResponse.self, from: data)
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

// MARK: - API Response Models

/// API response wrapper for a single conversation
private struct ConversationResponse: Codable {
    let data: Conversation
}
