import Foundation

/// Predefined emotional states for call logging
enum EmotionalState: String, CaseIterable, Codable, Identifiable {
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case frustrated = "frustrated"
    case excited = "excited"

    var id: String { rawValue }

    /// Emoji representation of the emotional state
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😢"
        case .frustrated: return "😤"
        case .excited: return "🤩"
        }
    }

    /// Display name for the emotional state
    var displayName: String {
        rawValue.capitalized
    }
}
