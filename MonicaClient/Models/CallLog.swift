import Foundation

/// API model for call logs (maps to /api/calls endpoint)
/// Based on Monica v4.x Call model (verified against source code)
/// https://github.com/monicahq/monica/blob/4.x/app/Models/Contact/Call.php
struct CallLog: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let calledAt: Date           // When the call happened
    let content: String?         // Call notes/description
    let contactCalled: Bool      // true = they called me, false = I called them
    let emotions: [Emotion]?     // Optional array of emotions
    let createdAt: Date
    let updatedAt: Date

    /// Check if call has additional details beyond just timestamp
    var hasDetails: Bool {
        !(content?.isEmpty ?? true) || !(emotions?.isEmpty ?? true)
    }

    /// Convert Monica's contact_called boolean to our CallDirection enum
    var callDirection: CallDirection {
        contactCalled ? .contact : .me
    }

    enum CodingKeys: String, CodingKey {
        case id
        case contact
        case calledAt = "called_at"
        case content
        case contactCalled = "contact_called"
        case emotions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoding to extract contact_id from nested contact object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)

        // Extract contact ID from nested contact object
        let contactContainer = try container.nestedContainer(keyedBy: NestedContactKeys.self, forKey: .contact)
        contactId = try contactContainer.decode(Int.self, forKey: .id)

        calledAt = try container.decode(Date.self, forKey: .calledAt)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        contactCalled = try container.decode(Bool.self, forKey: .contactCalled)
        emotions = try container.decodeIfPresent([Emotion].self, forKey: .emotions)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    // Custom encoding to use flat contact_id for create/update operations
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(contactId, forKey: .contactId)
        try container.encode(calledAt, forKey: .calledAt)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encode(contactCalled, forKey: .contactCalled)
        try container.encodeIfPresent(emotions, forKey: .emotions)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    private enum NestedContactKeys: String, CodingKey {
        case id
    }

    private enum EncodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
        case contactCalled = "contact_called"
        case emotions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer for tests and previews
    init(id: Int, contactId: Int, calledAt: Date, content: String?, contactCalled: Bool, emotions: [Emotion]?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.contactId = contactId
        self.calledAt = calledAt
        self.content = content
        self.contactCalled = contactCalled
        self.emotions = emotions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Call direction: who initiated the call
/// Maps to Monica's contact_called boolean field
enum CallDirection: String, Codable, CaseIterable {
    case me = "false"        // I called them (contact_called = false)
    case contact = "true"    // They called me (contact_called = true)

    var displayName: String {
        switch self {
        case .me: return "You called"
        case .contact: return "They called"
        }
    }

    var icon: String {
        switch self {
        case .me: return "phone.arrow.up.right"
        case .contact: return "phone.arrow.down.left"
        }
    }

    /// Convert to Monica API boolean value
    var boolValue: Bool {
        self == .contact
    }

    /// Create from Monica API boolean value
    init(contactCalled: Bool) {
        self = contactCalled ? .contact : .me
    }
}

/// API response wrapper for call list
struct CallListResponse: Codable {
    let data: [CallLog]
}
