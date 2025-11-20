import Foundation

/// Represents a reminder for important dates related to contacts
struct Reminder: Codable, Identifiable {
    let id: Int
    let contactId: Int?
    let initialDate: Date
    let frequencyType: String // "one_time", "week", "month", "year"
    let frequencyNumber: Int?
    let title: String
    let description: String?
    let delible: Bool? // Can be deleted (some system reminders cannot)
    let nextExpectedDate: Date?
    let contact: ReminderContact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case initialDate = "initial_date"
        case frequencyType = "frequency_type"
        case frequencyNumber = "frequency_number"
        case title
        case description
        case delible
        case nextExpectedDate = "next_expected_date"
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var isRecurring: Bool {
        return frequencyType != "one_time"
    }

    var frequencyDescription: String {
        switch frequencyType {
        case "one_time":
            return "One time"
        case "week":
            if let num = frequencyNumber {
                return num == 1 ? "Every week" : "Every \(num) weeks"
            }
            return "Weekly"
        case "month":
            if let num = frequencyNumber {
                return num == 1 ? "Every month" : "Every \(num) months"
            }
            return "Monthly"
        case "year":
            if let num = frequencyNumber {
                return num == 1 ? "Every year" : "Every \(num) years"
            }
            return "Yearly"
        default:
            return frequencyType
        }
    }

    var daysUntilDue: Int? {
        guard let nextDate = nextExpectedDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reminderDate = calendar.startOfDay(for: nextDate)
        return calendar.dateComponents([.day], from: today, to: reminderDate).day
    }

    var isDueSoon: Bool {
        guard let days = daysUntilDue else { return false }
        return days >= 0 && days <= 7
    }

    var isOverdue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0
    }

    var dueDateDescription: String {
        guard let days = daysUntilDue else {
            return "Date unknown"
        }

        if days < 0 {
            let absDays = abs(days)
            return absDays == 1 ? "1 day overdue" : "\(absDays) days overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "In \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "In 1 week" : "In \(weeks) weeks"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "In 1 month" : "In \(months) months"
        } else {
            let years = days / 365
            return years == 1 ? "In 1 year" : "In \(years) years"
        }
    }

    var icon: String {
        // Try to guess icon from title
        let lowercaseTitle = title.lowercased()
        if lowercaseTitle.contains("birthday") {
            return "birthday.cake"
        } else if lowercaseTitle.contains("anniversary") {
            return "heart.circle"
        } else if lowercaseTitle.contains("call") {
            return "phone"
        } else if lowercaseTitle.contains("meeting") || lowercaseTitle.contains("meet") {
            return "person.2"
        } else {
            return "bell"
        }
    }
}

/// Simplified contact info within reminder context
struct ReminderContact: Codable, Identifiable {
    let id: Int
    let hashId: String?
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let completeName: String

    enum CodingKeys: String, CodingKey {
        case id
        case hashId = "hash_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
        case completeName = "complete_name"
    }

    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        return completeName
    }
}

// MARK: - API Response Types

/// API response wrapper for reminders
typealias RemindersResponse = APIResponse<[Reminder]>

/// Single reminder response wrapper
struct ReminderSingleResponse: Codable {
    let data: Reminder
}

// MARK: - API Payloads

/// Payload for creating new reminders
struct ReminderCreatePayload: Codable {
    let contactId: Int
    let initialDate: String // YYYY-MM-DD format
    let frequencyType: String
    let frequencyNumber: Int?
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case initialDate = "initial_date"
        case frequencyType = "frequency_type"
        case frequencyNumber = "frequency_number"
        case title
        case description
    }
}

/// Payload for updating existing reminders
struct ReminderUpdatePayload: Codable {
    let initialDate: String?
    let frequencyType: String?
    let frequencyNumber: Int?
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case initialDate = "initial_date"
        case frequencyType = "frequency_type"
        case frequencyNumber = "frequency_number"
        case title
        case description
    }
}

// MARK: - Frequency Type Enum

enum ReminderFrequency: String, CaseIterable {
    case oneTime = "one_time"
    case week = "week"
    case month = "month"
    case year = "year"

    var displayName: String {
        switch self {
        case .oneTime:
            return "One time"
        case .week:
            return "Weekly"
        case .month:
            return "Monthly"
        case .year:
            return "Yearly"
        }
    }

    var icon: String {
        switch self {
        case .oneTime:
            return "1.circle"
        case .week:
            return "calendar.badge.clock"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.exclamationmark"
        }
    }
}
