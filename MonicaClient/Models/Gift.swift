import Foundation

/// Gift ideas or given gifts for a contact
struct Gift: Codable, Identifiable {
    let id: Int
    let contactId: Int?  // Optional - API doesn't always return this
    let name: String
    let comment: String?
    let status: String  // "idea", "offered", or "received"
    let url: String?
    let value: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case name
        case comment
        case status
        case url
        case value
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Custom decoding to handle value as either String or Double
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        contactId = try container.decodeIfPresent(Int.self, forKey: .contactId)
        name = try container.decode(String.self, forKey: .name)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        status = try container.decode(String.self, forKey: .status)
        url = try container.decodeIfPresent(String.self, forKey: .url)

        // Handle value as either String or Double
        if let valueString = try? container.decodeIfPresent(String.self, forKey: .value) {
            value = Double(valueString)
        } else {
            value = try container.decodeIfPresent(Double.self, forKey: .value)
        }

        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    var category: GiftCategory {
        switch status {
        case "idea":
            return .idea
        case "offered":
            return .given
        default:
            return .received
        }
    }

    // Computed properties for backward compatibility
    var isAnIdea: Bool {
        return status == "idea"
    }

    var hasBeenOffered: Bool {
        return status == "offered"
    }
}

enum GiftCategory: String, CaseIterable {
    case idea = "Gift ideas"
    case given = "Gifts given"
    case received = "Gifts received"
}

/// API response wrapper for gifts
typealias GiftsResponse = APIResponse<[Gift]>

/// Single gift response
struct GiftSingleResponse: Codable {
    let data: Gift
}

/// Payload for creating gifts
struct GiftCreatePayload: Codable {
    let contactId: Int
    let name: String
    let comment: String?
    let isAnIdea: Bool
    let hasBeenOffered: Bool
    let url: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case name
        case comment
        case isAnIdea = "is_an_idea"
        case hasBeenOffered = "has_been_offered"
        case url
        case value
    }
}

/// Payload for updating gifts
struct GiftUpdatePayload: Codable {
    let name: String?
    let comment: String?
    let isAnIdea: Bool?
    let hasBeenOffered: Bool?
    let url: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case comment
        case isAnIdea = "is_an_idea"
        case hasBeenOffered = "has_been_offered"
        case url
        case value
    }
}