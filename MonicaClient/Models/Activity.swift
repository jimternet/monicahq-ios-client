import Foundation

/// Represents an interaction or event related to one or more contacts
struct Activity: Codable, Identifiable {
    let id: Int
    let activityTypeId: Int?
    let summary: String?
    let description: String?
    let happenedAt: Date?
    let contacts: [ActivityContact]?
    let activityType: ActivityType?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case activityTypeId = "activity_type_id"
        case summary
        case description
        case happenedAt = "happened_at"
        case contacts
        case activityType = "activity_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Helper to safely access contacts
    var safeContacts: [ActivityContact] {
        return contacts ?? []
    }
}

/// Activity type for categorization and display
struct ActivityType: Codable, Identifiable {
    let id: Int
    let name: String
    let iconName: String?
    let color: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName = "icon_name"
        case color
    }
}

/// Contact information within activity context
struct ActivityContact: Codable, Identifiable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let nickname: String?
    
    var completeName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        let first = firstName ?? ""
        let last = lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? "Unknown" : fullName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
    }
}

/// API response wrapper for activities
typealias ActivitiesResponse = APIResponse<[Activity]>

/// Single activity response wrapper
struct ActivitySingleResponse: Codable {
    let data: Activity
}

/// Payload for creating new activities
struct ActivityCreatePayload: Codable {
    let activityTypeId: Int
    let summary: String?
    let description: String?
    let happenedAt: Date?
    let contacts: [Int]
    
    enum CodingKeys: String, CodingKey {
        case activityTypeId = "activity_type_id"
        case summary
        case description
        case happenedAt = "happened_at"
        case contacts
    }
}

/// Payload for updating existing activities
struct ActivityUpdatePayload: Codable {
    let activityTypeId: Int?
    let summary: String?
    let description: String?
    let happenedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case activityTypeId = "activity_type_id"
        case summary
        case description
        case happenedAt = "happened_at"
    }
}