//
//  Conversation.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

/// API model for conversations (maps to /api/conversations endpoint)
/// Based on Monica v4.x Conversations API
struct Conversation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let happenedAt: Date              // When the conversation occurred
    let contactFieldTypeId: Int?      // Optional: categorizes conversation type (in-person, email, text, etc.)
    let notes: String?                // Free-form text describing conversation content (max 10,000 chars)
    let createdAt: Date
    let updatedAt: Date

    /// Check if conversation has notes
    var hasNotes: Bool {
        !(notes?.isEmpty ?? true)
    }

    /// Check if this is a quick log (no notes)
    var isQuickLog: Bool {
        !hasNotes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case contact
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoding to extract contact_id from nested contact object
    // (matching CallLog pattern)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        // Extract contact ID from nested contact object
        let contactContainer = try container.nestedContainer(keyedBy: NestedContactKeys.self, forKey: .contact)
        contactId = try contactContainer.decode(Int.self, forKey: .id)

        happenedAt = try container.decode(Date.self, forKey: .happenedAt)
        contactFieldTypeId = try container.decodeIfPresent(Int.self, forKey: .contactFieldTypeId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    // Custom encoding to use flat contact_id for create/update operations
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(contactId, forKey: .contactId)
        try container.encode(happenedAt, forKey: .happenedAt)
        try container.encodeIfPresent(contactFieldTypeId, forKey: .contactFieldTypeId)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    private enum NestedContactKeys: String, CodingKey {
        case id
    }

    private enum EncodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer for tests and previews
    init(id: Int, contactId: Int, happenedAt: Date, contactFieldTypeId: Int?, notes: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.contactId = contactId
        self.happenedAt = happenedAt
        self.contactFieldTypeId = contactFieldTypeId
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Request payload for creating new conversations
struct ConversationCreateRequest: Encodable {
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}

/// Request payload for updating existing conversations
struct ConversationUpdateRequest: Encodable {
    let happenedAt: Date?
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}

/// API response wrapper for conversation list
struct ConversationListResponse: Codable {
    let data: [Conversation]
}
