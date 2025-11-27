import Foundation

/// Emotion model representing feelings that can be attached to calls and activities
/// Based on Dr. Phillip Shaver's emotion categorization (Primary, Secondary, Tertiary)
/// See: https://www.monicahq.com/blog for emotion system details
struct Emotion: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int?
    let name: String?
    let nameTranslationKey: String?
    let type: EmotionType
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case name
        case nameTranslationKey = "name_translation_key"
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Display name with fallback logic (custom name > translation key > "Emotion \(id)")
    var displayName: String {
        if let customName = name, !customName.isEmpty {
            return customName
        }
        if let translationKey = nameTranslationKey {
            // For MVP, just remove "emotion." prefix if present
            return translationKey.replacingOccurrences(of: "emotion.", with: "").capitalized
        }
        return "Emotion \(id)"
    }

    /// Emoji representation based on emotion type
    var emoji: String {
        switch type {
        case .positive:
            return "😊"
        case .neutral:
            return "😐"
        case .negative:
            return "😢"
        }
    }
}

/// Emotion type/category based on valence
enum EmotionType: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"

    var displayName: String {
        rawValue.capitalized
    }
}

/// API response wrapper for emotion list
struct EmotionListResponse: Codable {
    let data: [Emotion]
}
