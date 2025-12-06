import SwiftUI

/// Relationship categories for grouping relationship types
/// Maps to RelationshipTypeGroup from Monica API
enum RelationshipCategory: String, CaseIterable, Identifiable {
    case family = "family"
    case love = "love"
    case friend = "friend"
    case work = "work"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .family: return "Family"
        case .love: return "Love"
        case .friend: return "Friends"
        case .work: return "Work"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .family: return "figure.2.and.child.holdinghands"
        case .love: return "heart.fill"
        case .friend: return "person.2.fill"
        case .work: return "briefcase.fill"
        case .other: return "person.crop.circle.badge.questionmark"
        }
    }

    var color: Color {
        switch self {
        case .family: return .monicaRed
        case .love: return .pink
        case .friend: return .monicaGreen
        case .work: return .monicaOrange
        case .other: return .monicaBlue
        }
    }

    /// Initialize from RelationshipTypeGroup name
    init(groupName: String) {
        switch groupName.lowercased() {
        case "family": self = .family
        case "love": self = .love
        case "friend", "friends": self = .friend
        case "work": self = .work
        default: self = .other
        }
    }
}

/// Validation error types for relationship operations
enum RelationshipValidationError: LocalizedError {
    case selfRelationship
    case duplicateRelationship
    case invalidRelationshipType
    case contactNotFound

    var errorDescription: String? {
        switch self {
        case .selfRelationship:
            return "Cannot create a relationship with the same contact"
        case .duplicateRelationship:
            return "This relationship already exists"
        case .invalidRelationshipType:
            return "Please select a valid relationship type"
        case .contactNotFound:
            return "Contact not found"
        }
    }
}
