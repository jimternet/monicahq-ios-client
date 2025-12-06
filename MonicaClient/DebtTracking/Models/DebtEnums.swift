import SwiftUI

/// Semantic wrapper for debt direction
/// Maps Monica API "yes"/"no" to meaningful values
enum DebtDirection: String, CaseIterable {
    case theyOweMe = "yes"    // Contact owes user money
    case iOweThem = "no"      // User owes contact money

    var displayLabel: String {
        switch self {
        case .theyOweMe: return "They owe me"
        case .iOweThem: return "I owe them"
        }
    }

    var shortLabel: String {
        switch self {
        case .theyOweMe: return "Owed to you"
        case .iOweThem: return "You owe"
        }
    }

    var color: Color {
        switch self {
        case .theyOweMe: return .green
        case .iOweThem: return .red
        }
    }
}

/// Semantic wrapper for debt status
enum DebtStatus: String, CaseIterable {
    case outstanding = "inprogress"
    case settled = "completed"

    var displayLabel: String {
        switch self {
        case .outstanding: return "Outstanding"
        case .settled: return "Settled"
        }
    }

    var icon: String {
        switch self {
        case .outstanding: return "clock"
        case .settled: return "checkmark.circle.fill"
        }
    }
}
