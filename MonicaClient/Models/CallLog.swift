import Foundation

/// API model for call logs (maps to Activities API)
struct CallLog: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let calledAt: Date
    let duration: Int?           // Minutes, optional
    let emotionalState: EmotionalState?  // Optional
    let notes: String?           // Max 5000 chars, optional
    let createdAt: Date
    let updatedAt: Date

    /// Check if call has additional details beyond just timestamp
    var hasDetails: Bool {
        duration != nil || emotionalState != nil || !(notes?.isEmpty ?? true)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case calledAt = "called_at"
        case duration
        case emotionalState = "emotional_state"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Metadata stored in Activity.description for call logs
struct CallMetadata: Codable {
    let duration: Int?
    let emotion: String?
    let notes: String?
}
