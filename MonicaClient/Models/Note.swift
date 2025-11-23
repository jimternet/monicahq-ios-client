import Foundation

/// Free-form text content associated with a contact
struct Note: Codable, Identifiable {
    let id: Int
    let body: String
    let isFavorited: Bool
    let createdAt: Date?
    let updatedAt: Date?

    // Nested structures that API might return but we don't use
    let object: String?
    let favoritedAt: Date?

    // UI-only properties with defaults
    var title: String? { nil }
    var isFavorite: Bool { isFavorited }

    // Computed property for contactId - extract from contact object if present
    var contactId: Int {
        // Will be set by the view when creating, extracted when decoding
        return contact?.id ?? 0
    }

    // Contact reference that API might include
    let contact: ContactReference?
    let account: AccountReference?

    struct ContactReference: Codable {
        let id: Int
    }

    struct AccountReference: Codable {
        let id: Int
    }

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case isFavorited = "is_favorited"
        case object
        case favoritedAt = "favorited_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contact
        case account
    }

    // Custom initializer for creating notes (without server fields)
    init(id: Int, contactId: Int, body: String, isFavorited: Bool) {
        self.id = id
        self.body = body
        self.isFavorited = isFavorited
        self.object = "note"
        self.favoritedAt = nil
        self.createdAt = nil
        self.updatedAt = nil
        self.contact = ContactReference(id: contactId)
        self.account = nil
    }
}

/// API response wrapper for notes
typealias NotesResponse = APIResponse<[Note]>

/// Single note response wrapper
struct NoteSingleResponse: Codable {
    let data: Note
}

/// Payload for creating new notes
struct NoteCreatePayload: Codable {
    let contactId: Int
    let body: String
    let isFavorited: Bool

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case body
        case isFavorited = "is_favorited"
    }
}

/// Payload for updating existing notes
struct NoteUpdatePayload: Codable {
    let body: String?
    let isFavorited: Bool?

    enum CodingKeys: String, CodingKey {
        case body
        case isFavorited = "is_favorited"
    }
}