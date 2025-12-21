import Foundation
import SwiftUI

struct Contact: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let hashId: String
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let completeName: String
    let initials: String
    let description: String?
    let gender: String?
    let genderType: String?
    let isStarred: Bool
    let isPartial: Bool
    let isActive: Bool
    let isDead: Bool
    let isMe: Bool
    let lastCalled: Date?
    let lastActivityTogether: Date?
    let stayInTouchFrequency: String?
    let stayInTouchTriggerDate: Date?
    let email: String? // Legacy field
    let phone: String? // Legacy field
    let birthdate: Date? // Legacy field
    let birthdateIsAgeBased: Bool? // Whether birthdate is age-based estimate
    let birthdateAge: Int? // Estimated age (only for age-based)
    let isBirthdateKnown: Bool? // Whether birthdate is known at all
    let address: String? // Legacy field
    let company: String? // Legacy field
    let jobTitle: String? // Legacy field
    let notes: String? // Legacy field
    let relationships: [Relationship]?
    let information: ContactInformation?
    let addresses: [ContactAddress]?
    let tags: [Tag]?
    let statistics: ContactStatistics?
    let url: String
    let account: Account
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for legacy compatibility
    var legacyCompleteName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let fullName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? completeName : fullName
    }
    
    var birthday: Date? {
        return birthdate
    }
    
    var avatarURL: String? {
        return information?.avatar.url
    }
    
    var avatarColor: String? {
        return information?.avatar.defaultAvatarColor
    }
    
    var computedInitials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case object
        case hashId = "hash_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
        case completeName = "complete_name"
        case initials
        case description
        case gender
        case genderType = "gender_type"
        case isStarred = "is_starred"
        case isPartial = "is_partial"
        case isActive = "is_active"
        case isDead = "is_dead"
        case isMe = "is_me"
        case lastCalled = "last_called"
        case lastActivityTogether = "last_activity_together"
        case stayInTouchFrequency = "stay_in_touch_frequency"
        case stayInTouchTriggerDate = "stay_in_touch_trigger_date"
        case email
        case phone
        case birthdate
        case birthdateIsAgeBased = "birthdate_is_age_based"
        case birthdateAge = "birthdate_age"
        case isBirthdateKnown = "is_birthdate_known"
        case address
        case company
        case jobTitle = "job_title"
        case notes
        case relationships
        case information
        case addresses
        case tags
        case statistics
        case url
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Contact Address structure
struct ContactAddress: Codable, Identifiable {
    let id: Int
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case street
        case city
        case province
        case postalCode = "postal_code"
        case country
        case latitude
        case longitude
    }
}

/// Contact Statistics structure
struct ContactStatistics: Codable {
    let numberOfCalls: Int
    let numberOfNotes: Int
    let numberOfActivities: Int
    let numberOfReminders: Int
    let numberOfTasks: Int
    let numberOfGifts: Int
    let numberOfDebts: Int
    
    enum CodingKeys: String, CodingKey {
        case numberOfCalls = "number_of_calls"
        case numberOfNotes = "number_of_notes"
        case numberOfActivities = "number_of_activities"
        case numberOfReminders = "number_of_reminders"
        case numberOfTasks = "number_of_tasks"
        case numberOfGifts = "number_of_gifts"
        case numberOfDebts = "number_of_debts"
    }
}

/// Gender structure for contact gender options
struct Gender: Codable, Identifiable, Hashable {
    let id: Int
    let object: String?
    let name: String
    let account: Account?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// API response wrapper for genders
typealias GendersResponse = APIResponse<[Gender]>

/// Tag structure that might be included in contact response
struct Tag: Codable, Identifiable {
    let id: Int
    let object: String?
    let name: String
    let nameSlug: String
    let account: Account?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case nameSlug = "name_slug"
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// API response wrapper for tags
typealias TagsResponse = APIResponse<[Tag]>

/// Journal entry structure for personal diary entries
struct JournalEntry: Codable, Identifiable, Hashable {
    let id: Int
    let object: String?
    let title: String
    let post: String
    let account: Account?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case title
        case post
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// API response wrapper for journal entries
typealias JournalResponse = APIResponse<[JournalEntry]>

/// Payload for creating/updating journal entries
struct JournalEntryPayload: Codable {
    let title: String
    let post: String
}

// MARK: - Day Entries (Mood Tracking)

/// Mood rating enum for type-safe mood handling
enum MoodRating: Int, CaseIterable, Codable {
    case bad = 1
    case okay = 2
    case great = 3

    var emoji: String {
        switch self {
        case .bad: return "😞"
        case .okay: return "😐"
        case .great: return "😊"
        }
    }

    var label: String {
        switch self {
        case .bad: return "Bad"
        case .okay: return "Okay"
        case .great: return "Great"
        }
    }

    var color: String {
        switch self {
        case .bad: return "red"
        case .okay: return "yellow"
        case .great: return "green"
        }
    }

    init?(rate: Int) {
        self.init(rawValue: rate)
    }
}

/// Day entry representing a mood rating for a specific date
struct DayEntry: Codable, Identifiable, Hashable {
    let id: Int
    let rate: Int
    let comment: String?
    let date: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case rate
        case comment
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension DayEntry {
    /// Emoji representation of mood rating
    var moodEmoji: String {
        MoodRating(rate: rate)?.emoji ?? "😐"
    }

    /// Human-readable mood description
    var moodDescription: String {
        switch rate {
        case 1: return "Bad day"
        case 2: return "Okay day"
        case 3: return "Great day"
        default: return "Day"
        }
    }

    /// MoodRating enum value
    var moodRating: MoodRating? {
        MoodRating(rate: rate)
    }

    /// Whether entry has a comment
    var hasComment: Bool {
        comment != nil && !(comment?.isEmpty ?? true)
    }

    /// Formatted date for display
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Check if this is today's entry
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Check if entry was edited
    var wasEdited: Bool {
        createdAt != updatedAt
    }

    /// SwiftUI Color for mood visual indicator
    var moodColor: Color {
        switch rate {
        case 1: return .red
        case 2: return .orange
        case 3: return .green
        default: return .gray
        }
    }
}

/// API response wrapper for day entries
typealias DayEntriesResponse = APIResponse<[DayEntry]>

/// Single day entry response wrapper
struct DayEntrySingleResponse: Codable {
    let data: DayEntry
}

/// Payload for creating day entries
struct DayEntryCreatePayload: Codable {
    let date: String  // Format: "yyyy-MM-dd"
    let rate: Int
    let comment: String?
}

/// Payload for updating day entries
struct DayEntryUpdatePayload: Codable {
    let rate: Int
    let comment: String?
}

struct ContactsResponse: Codable {
    let data: [Contact]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}

struct ContactApiResponse: Codable {
    let data: Contact
}

struct ContactSingleResponse: Codable {
    let data: Contact
}

struct ContactFieldsResponse: Codable {
    let data: [ContactField]
}

struct ContactFieldApiResponse: Codable {
    let data: ContactField
}

struct ContactFieldCreatePayload: Codable {
    let contactId: Int
    let contactFieldTypeId: Int
    let data: String
    let label: String?
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case contactFieldTypeId = "contact_field_type_id"
        case data
        case label
    }
}

struct ContactFieldUpdatePayload: Codable {
    let contactFieldTypeId: Int
    let data: String
    let label: String?
    
    enum CodingKeys: String, CodingKey {
        case contactFieldTypeId = "contact_field_type_id"
        case data
        case label
    }
}

struct RelationshipsResponse: Codable {
    let data: [Relationship]
}

struct RelationshipTypesResponse: Codable {
    let data: [RelationshipType]
}

struct RelationshipCreatePayload: Codable {
    let contactIs: Int
    let relationshipTypeId: Int
    let ofContact: Int

    enum CodingKeys: String, CodingKey {
        case contactIs = "contact_is"
        case relationshipTypeId = "relationship_type_id"
        case ofContact = "of_contact"
    }
}

struct RelationshipUpdatePayload: Codable {
    let relationshipTypeId: Int

    enum CodingKeys: String, CodingKey {
        case relationshipTypeId = "relationship_type_id"
    }
}

struct RelationshipSingleResponse: Codable {
    let data: Relationship
}

struct RelationshipDeleteResponse: Codable {
    let deleted: Bool
    let id: Int
}

struct PaginationLinks: Codable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}

struct PaginationMeta: Codable {
    let currentPage: Int
    let from: Int?
    let lastPage: Int
    let perPage: Int
    let to: Int?
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case perPage = "per_page"
        case to
        case total
    }
}

/// Contact field representing different types of contact information (matches Monica API structure)
struct ContactField: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let content: String
    let contactFieldType: ContactFieldTypeObject
    let labels: [ContactFieldLabel]
    let account: Account
    let contact: RelatedContact
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for easy access
    var data: String { content }
    var contactId: Int { contact.id }
    var label: String? { 
        // Get the first non-empty label, or nil if none
        labels.first?.label?.isEmpty == false ? labels.first?.label : nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case object
        case content
        case contactFieldType = "contact_field_type"
        case labels
        case account
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Contact field type object from Monica API
struct ContactFieldTypeObject: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let name: String
    let fontawesomeIcon: String
    let `protocol`: String?
    let delible: Bool
    let type: String? // Optional because some contact field types (e.g., LinkedIn) return null
    let account: Account
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case object
        case name
        case fontawesomeIcon = "fontawesome_icon"
        case `protocol`
        case delible
        case type
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Contact field label from Monica API
struct ContactFieldLabel: Codable, Identifiable {
    let id: Int
    let object: String
    let type: String?
    let label: String?
    let account: Account
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case type
        case label
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Extension to provide backwards compatibility and UI helpers
extension ContactField {
    enum ContactFieldType: String, Codable, CaseIterable {
        case email = "email"
        case phone = "phone"
        case address = "address"
        case website = "website"
        case social = "social"
        case other = "other"
        
        var label: String {
            switch self {
            case .email: return "Email"
            case .phone: return "Phone"
            case .address: return "Address"
            case .website: return "Website"
            case .social: return "Social"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .email: return "envelope"
            case .phone: return "phone"
            case .address: return "location"
            case .website: return "globe"
            case .social: return "person.2"
            case .other: return "info.circle"
            }
        }
        
        var typeId: Int {
            switch self {
            case .email: return 29  // Updated based on API response
            case .phone: return 30
            case .address: return 31
            case .website: return 32
            case .social: return 33
            case .other: return 34
            }
        }
        
        var isActionable: Bool {
            switch self {
            case .email, .phone, .website: return true
            case .address, .social, .other: return false
            }
        }
        
        func getActionURL(for data: String) -> URL? {
            switch self {
            case .email:
                return URL(string: "mailto:\(data)")
            case .phone:
                let cleanPhone = data.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return URL(string: "tel:\(cleanPhone)")
            case .website:
                if data.hasPrefix("http") {
                    return URL(string: data)
                } else {
                    return URL(string: "https://\(data)")
                }
            case .address, .social, .other:
                return nil
            }
        }
    }
    
    // Computed property to get the simplified type for UI
    var contactFieldTypeEnum: ContactFieldType {
        guard let typeString = contactFieldType.type else { return .other }
        return ContactFieldType(rawValue: typeString) ?? .other
    }
}

/// Represents a relationship between two contacts (matches actual Monica API structure)
struct Relationship: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let contactIs: RelatedContact
    let relationshipType: RelationshipType
    let ofContact: RelatedContact
    let url: String
    let account: Account
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case object
        case contactIs = "contact_is"
        case relationshipType = "relationship_type"
        case ofContact = "of_contact"
        case url
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Relationship type definition (matches actual Monica API structure)
struct RelationshipType: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String
    let nameReverseRelationship: String
    let relationshipTypeGroupId: Int
    let delible: Bool
    let account: Account
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case nameReverseRelationship = "name_reverse_relationship"
        case relationshipTypeGroupId = "relationship_type_group_id"
        case delible
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Relationship type group definition
struct RelationshipTypeGroup: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String
    let delible: Bool
    let account: Account
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case delible
        case account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RelationshipTypeGroupsResponse: Codable {
    let data: [RelationshipTypeGroup]
}

/// Related contact information in relationship context (matches actual Monica API structure)
struct RelatedContact: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let hashId: String
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let completeName: String
    let initials: String
    let gender: String
    let genderType: String
    let isStarred: Bool
    let isPartial: Bool
    let isActive: Bool
    let isDead: Bool
    let isMe: Bool
    let information: ContactInformation
    let url: String
    let account: Account
    
    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return "\(completeName) (\(nickname))"
        }
        return completeName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case object
        case hashId = "hash_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
        case completeName = "complete_name"
        case initials
        case gender
        case genderType = "gender_type"
        case isStarred = "is_starred"
        case isPartial = "is_partial"
        case isActive = "is_active"
        case isDead = "is_dead"
        case isMe = "is_me"
        case information
        case url
        case account
    }
}

/// Contact information structure from API
struct ContactInformation: Codable {
    let relationships: RelationshipGroups?
    let dates: ContactDates?
    let career: CareerInfo?
    let avatar: AvatarInfo
    let foodPreferences: String?
    let howYouMet: HowYouMet?
    
    enum CodingKeys: String, CodingKey {
        case relationships
        case dates
        case career
        case avatar
        case foodPreferences = "food_preferences"
        case howYouMet = "how_you_met"
    }
}

/// Relationship groups structure
struct RelationshipGroups: Codable {
    let love: RelationshipGroup?
    let family: RelationshipGroup?
    let friend: RelationshipGroup?
    let work: RelationshipGroup?
}

/// Relationship group with total count and contacts
struct RelationshipGroup: Codable {
    let total: Int
    let contacts: [RelationshipContact]
}

/// Relationship contact structure (different from RelatedContact)
struct RelationshipContact: Codable {
    let relationship: RelationshipInfo
    let contact: RelatedContact
}

/// Relationship info structure
struct RelationshipInfo: Codable {
    let id: Int
    let uuid: String
    let name: String
}

/// Contact dates structure
struct ContactDates: Codable {
    let birthdate: DateInfo?
    let deceasedDate: DateInfo?
    
    enum CodingKeys: String, CodingKey {
        case birthdate
        case deceasedDate = "deceased_date"
    }
}

/// Career information structure
struct CareerInfo: Codable {
    let job: String?
    let company: String?
}

/// How you met structure
struct HowYouMet: Codable {
    let generalInformation: String?
    let firstMetDate: DateInfo?
    // Remove recursive reference to break the cycle
    // let firstMetThroughContact: RelatedContact?
    
    enum CodingKeys: String, CodingKey {
        case generalInformation = "general_information"
        case firstMetDate = "first_met_date"
        // case firstMetThroughContact = "first_met_through_contact"
    }
}

/// Date information structure
struct DateInfo: Codable {
    let isAgeBased: Bool?
    let isYearUnknown: Bool?
    let date: Date?
    
    enum CodingKeys: String, CodingKey {
        case isAgeBased = "is_age_based"
        case isYearUnknown = "is_year_unknown"
        case date
    }
}

/// Avatar information structure
struct AvatarInfo: Codable {
    let url: String?
    let source: String?
    let defaultAvatarColor: String

    enum CodingKeys: String, CodingKey {
        case url
        case source
        case defaultAvatarColor = "default_avatar_color"
    }
}

/// Account information structure
struct Account: Codable, Hashable {
    let id: Int
}

/// Contact update payload - only contains fields that can be updated via API
/// Note: email, phone, address are now managed via ContactFields API
struct ContactUpdatePayload: Codable {
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let genderId: Int?
    let birthdateDay: Int?
    let birthdateMonth: Int?
    let birthdateYear: Int?
    let birthdateIsAgeBased: Bool?
    let isBirthdateKnown: Bool
    let birthdateAge: Int?
    let isPartial: Bool?
    let isDeceased: Bool
    let deceasedDate: String?
    let deceasedDateIsAgeBased: Bool?
    let deceasedDateIsYearUnknown: Bool?
    let deceasedDateAge: Int?
    let isDeceasedDateKnown: Bool
    let company: String?
    let jobTitle: String?
    let notes: String?
    let description: String?
    let gender: String?
    let isStarred: Bool?
    let foodPreferences: String?
    let howYouMetGeneralInformation: String?
    let firstMetDate: String?
    let stayInTouchFrequency: String?
    let stayInTouchTriggerDate: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
        case genderId = "gender_id"
        case birthdateDay = "birthdate_day"
        case birthdateMonth = "birthdate_month"
        case birthdateYear = "birthdate_year"
        case birthdateIsAgeBased = "birthdate_is_age_based"
        case isBirthdateKnown = "is_birthdate_known"
        case birthdateAge = "birthdate_age"
        case isPartial = "is_partial"
        case isDeceased = "is_deceased"
        case deceasedDate = "deceased_date"
        case deceasedDateIsAgeBased = "deceased_date_is_age_based"
        case deceasedDateIsYearUnknown = "deceased_date_is_year_unknown"
        case deceasedDateAge = "deceased_date_age"
        case isDeceasedDateKnown = "is_deceased_date_known"
        case company
        case jobTitle = "job_title"
        case notes
        case description
        case gender
        case isStarred = "is_starred"
        case foodPreferences = "food_preferences"
        case howYouMetGeneralInformation = "how_you_met_general_information"
        case firstMetDate = "first_met_date"
        case stayInTouchFrequency = "stay_in_touch_frequency"
        case stayInTouchTriggerDate = "stay_in_touch_trigger_date"
    }
}

struct ContactStarUpdatePayload: Codable {
    let isStarred: Bool

    enum CodingKeys: String, CodingKey {
        case isStarred = "is_starred"
    }
}

/// Contact creation payload - contains fields needed for creating a new contact via API
struct ContactCreatePayload: Codable {
    let firstName: String
    let lastName: String?
    let nickname: String?
    let genderId: Int?
    let gender: String?
    let birthdateDay: Int?
    let birthdateMonth: Int?
    let birthdateYear: Int?
    let birthdateIsAgeBased: Bool
    let isBirthdateKnown: Bool
    let isPartial: Bool
    let isDeceased: Bool
    let isDeceasedDateKnown: Bool
    let company: String?
    let jobTitle: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case nickname
        case genderId = "gender_id"
        case gender
        case birthdateDay = "birthdate_day"
        case birthdateMonth = "birthdate_month"
        case birthdateYear = "birthdate_year"
        case birthdateIsAgeBased = "birthdate_is_age_based"
        case isBirthdateKnown = "is_birthdate_known"
        case isPartial = "is_partial"
        case isDeceased = "is_deceased"
        case isDeceasedDateKnown = "is_deceased_date_known"
        case company
        case jobTitle = "job_title"
        case description
    }
}

// MARK: - Phone Calls

/// Phone call record with a contact
struct PhoneCall: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let calledAt: Date
    let content: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias PhoneCallsResponse = APIResponse<[PhoneCall]>

struct PhoneCallSingleResponse: Codable {
    let data: PhoneCall
}

struct PhoneCallCreatePayload: Codable {
    let contactId: Int
    let calledAt: String
    let content: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
    }
}

// MARK: - Contact Field Types

/// Contact field type (e.g., Phone, Email, Twitter, etc.)
struct ContactFieldType: Codable, Identifiable {
    let id: Int
    let uuid: String?
    let name: String
    let fontawesomeIcon: String?
    let `protocol`: String?
    let delible: Bool
    let type: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case fontawesomeIcon = "fontawesome_icon"
        case `protocol`
        case delible
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias ContactFieldTypesResponse = APIResponse<[ContactFieldType]>

// MARK: - Conversations

/// Conversation record (SMS, social media, etc.)
/// Monica API returns nested objects for contact, contact_field_type, and messages
struct Conversation: Codable, Identifiable {
    let id: Int
    let happenedAt: Date
    let content: String?  // May be nil - actual content is in messages
    let createdAt: Date
    let updatedAt: Date

    // Nested objects from API
    let contact: ConversationContact?
    let contactFieldType: ConversationContactFieldType?

    // Messages embedded in API response
    let messages: [ConversationMessage]

    // Computed properties for backwards compatibility
    var contactId: Int {
        contact?.id ?? 0
    }

    var contactFieldTypeId: Int {
        contactFieldType?.id ?? 0
    }

    /// Check if conversation has messages
    var hasMessages: Bool {
        !messages.isEmpty
    }

    /// Check if this is a quick log (no messages)
    var isQuickLog: Bool {
        !hasMessages
    }

    /// Get combined content from all messages
    var combinedMessageContent: String? {
        guard !messages.isEmpty else { return nil }
        return messages.map { $0.content }.joined(separator: "\n\n")
    }

    /// Alias for combined message content (backwards compat)
    var notes: String? {
        combinedMessageContent
    }

    /// Check if conversation has notes (via messages)
    var hasNotes: Bool {
        hasMessages
    }

    enum CodingKeys: String, CodingKey {
        case id
        case happenedAt = "happened_at"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contact
        case contactFieldType = "contact_field_type"
        case messages
    }

    // Memberwise initializer for tests and previews
    init(id: Int, contactId: Int, happenedAt: Date, contactFieldTypeId: Int, content: String?, createdAt: Date, updatedAt: Date, messages: [ConversationMessage] = []) {
        self.id = id
        self.happenedAt = happenedAt
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contact = ConversationContact(id: contactId)
        self.contactFieldType = ConversationContactFieldType(id: contactFieldTypeId, name: "Unknown")
        self.messages = messages
    }
}

/// Nested contact object in conversation response
struct ConversationContact: Codable {
    let id: Int

    init(id: Int) {
        self.id = id
    }
}

/// Nested contact field type object in conversation response
struct ConversationContactFieldType: Codable {
    let id: Int
    let name: String?

    init(id: Int, name: String?) {
        self.id = id
        self.name = name
    }
}

/// Message within a conversation
/// Fetched via GET /conversations/:id/messages
struct ConversationMessage: Codable, Identifiable {
    let id: Int
    let writtenAt: Date
    let writtenByMe: Bool
    let content: String
    let createdAt: Date
    let updatedAt: Date

    // Nested contact object (same as conversation)
    let contact: ConversationContact?

    enum CodingKeys: String, CodingKey {
        case id
        case writtenAt = "written_at"
        case writtenByMe = "written_by_me"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contact
    }

    init(id: Int, writtenAt: Date, writtenByMe: Bool, content: String, createdAt: Date, updatedAt: Date, contact: ConversationContact? = nil) {
        self.id = id
        self.writtenAt = writtenAt
        self.writtenByMe = writtenByMe
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contact = contact
    }
}

typealias ConversationMessagesResponse = APIResponse<[ConversationMessage]>

typealias ConversationsResponse = APIResponse<[Conversation]>

struct ConversationSingleResponse: Codable {
    let data: Conversation
}

struct ConversationCreatePayload: Codable {
    let contactId: Int
    let happenedAt: String
    let contactFieldTypeId: Int
    let content: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case content
    }
}

/// Request payload for updating existing conversations
struct ConversationUpdatePayload: Codable {
    let happenedAt: String?
    let contactFieldTypeId: Int?
    let content: String?

    enum CodingKeys: String, CodingKey {
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case content
    }
}

// MARK: - Debts

/// Minimal contact info embedded in Debt response
/// Matches ContactShort resource from Monica API
struct DebtContact: Codable, Identifiable {
    let id: Int
    let uuid: String?
    let hashId: String?
    let firstName: String?
    let lastName: String?
    let completeName: String
    let initials: String?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case hashId = "hash_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case completeName = "complete_name"
        case initials
    }
}

/// Debt tracking between user and contact
/// API: Monica v4.x /api/debts
struct Debt: Codable, Identifiable {
    let id: Int
    let uuid: String?
    let inDebt: String           // "yes" = they owe me, "no" = I owe them
    let status: String           // "inprogress" or "completed"
    let amount: Double           // Raw numeric amount
    let value: String?           // Formatted decimal string (e.g., "50.00")
    let amountWithCurrency: String?  // Display string (e.g., "$50.00")
    let reason: String?
    let contact: DebtContact?    // Nested contact for global view
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case inDebt = "in_debt"
        case status
        case amount
        case value
        case amountWithCurrency = "amount_with_currency"
        case reason
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        inDebt = try container.decode(String.self, forKey: .inDebt)
        status = try container.decode(String.self, forKey: .status)

        // Handle amount as either Double or String
        if let doubleAmount = try? container.decode(Double.self, forKey: .amount) {
            amount = doubleAmount
        } else if let stringAmount = try? container.decode(String.self, forKey: .amount),
                  let parsedAmount = Double(stringAmount) {
            amount = parsedAmount
        } else {
            amount = 0.0
        }

        value = try container.decodeIfPresent(String.self, forKey: .value)
        amountWithCurrency = try container.decodeIfPresent(String.self, forKey: .amountWithCurrency)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        contact = try container.decodeIfPresent(DebtContact.self, forKey: .contact)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

typealias DebtsResponse = APIResponse<[Debt]>

struct DebtSingleResponse: Codable {
    let data: Debt
}

struct DebtCreatePayload: Codable {
    let contactId: Int
    let inDebt: String           // "yes" or "no"
    let status: String           // "inprogress" or "completed"
    let amount: Double
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case reason
    }
}

struct DebtUpdatePayload: Codable {
    let contactId: Int           // Required by API
    let inDebt: String?          // Can update direction
    let status: String?
    let amount: Double?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case reason
    }
}

// MARK: - Life Events

/// Life event category (Work & Education, Family & Relationships, etc.)
struct LifeEventCategory: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let coreMonicaData: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coreMonicaData = "core_monica_data"
    }

    /// Icon for the category
    var icon: String {
        switch name.lowercased() {
        case let n where n.contains("work") || n.contains("education"):
            return "briefcase.fill"
        case let n where n.contains("family") || n.contains("relationship"):
            return "heart.fill"
        case let n where n.contains("home") || n.contains("living"):
            return "house.fill"
        case let n where n.contains("health") || n.contains("wellness"):
            return "heart.text.square.fill"
        case let n where n.contains("travel") || n.contains("experience"):
            return "airplane"
        default:
            return "star.fill"
        }
    }

    /// Color for the category
    var color: String {
        switch name.lowercased() {
        case let n where n.contains("work") || n.contains("education"):
            return "blue"
        case let n where n.contains("family") || n.contains("relationship"):
            return "pink"
        case let n where n.contains("home") || n.contains("living"):
            return "green"
        case let n where n.contains("health") || n.contains("wellness"):
            return "red"
        case let n where n.contains("travel") || n.contains("experience"):
            return "orange"
        default:
            return "purple"
        }
    }
}

typealias LifeEventCategoriesResponse = APIResponse<[LifeEventCategory]>

/// Life event type (e.g., New Job, Marriage, Graduation)
struct LifeEventType: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let coreMonicaData: Bool?
    let lifeEventCategoryId: Int?
    let lifeEventCategory: LifeEventCategory?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coreMonicaData = "core_monica_data"
        case lifeEventCategoryId = "life_event_category_id"
        case lifeEventCategory = "life_event_category"
    }

    /// Display name for the type
    var displayName: String {
        // Convert snake_case to Title Case
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Icon for the event type
    var icon: String {
        let lowercaseName = name.lowercased()
        switch lowercaseName {
        case let n where n.contains("job") || n.contains("promotion"):
            return "briefcase.fill"
        case let n where n.contains("graduation") || n.contains("degree"):
            return "graduationcap.fill"
        case let n where n.contains("retirement"):
            return "beach.umbrella.fill"
        case let n where n.contains("marriage") || n.contains("wedding"):
            return "heart.fill"
        case let n where n.contains("divorce"):
            return "heart.slash.fill"
        case let n where n.contains("child") || n.contains("birth") || n.contains("baby"):
            return "figure.and.child.holdinghands"
        case let n where n.contains("engaged"):
            return "ring"
        case let n where n.contains("move") || n.contains("house") || n.contains("home"):
            return "house.fill"
        case let n where n.contains("travel") || n.contains("trip"):
            return "airplane"
        case let n where n.contains("health") || n.contains("hospital") || n.contains("surgery"):
            return "cross.case.fill"
        case let n where n.contains("publish"):
            return "book.fill"
        case let n where n.contains("hobby"):
            return "paintpalette.fill"
        case let n where n.contains("goal") || n.contains("achievement"):
            return "trophy.fill"
        default:
            return "star.fill"
        }
    }

    /// Default life event types when API doesn't provide them
    static let defaultTypes: [LifeEventType] = {
        // Work & Education category (id: 1)
        let workCategory = LifeEventCategory(id: 1, name: "Work & Education", coreMonicaData: true)
        // Family & Relationships category (id: 2)
        let familyCategory = LifeEventCategory(id: 2, name: "Family & Relationships", coreMonicaData: true)
        // Home & Living category (id: 3)
        let homeCategory = LifeEventCategory(id: 3, name: "Home & Living", coreMonicaData: true)
        // Health & Wellness category (id: 4)
        let healthCategory = LifeEventCategory(id: 4, name: "Health & Wellness", coreMonicaData: true)
        // Travel & Experiences category (id: 5)
        let travelCategory = LifeEventCategory(id: 5, name: "Travel & Experiences", coreMonicaData: true)

        return [
            // Work & Education
            LifeEventType(id: 1, name: "New job", coreMonicaData: true, lifeEventCategoryId: 1, lifeEventCategory: workCategory),
            LifeEventType(id: 2, name: "Promotion", coreMonicaData: true, lifeEventCategoryId: 1, lifeEventCategory: workCategory),
            LifeEventType(id: 3, name: "Retirement", coreMonicaData: true, lifeEventCategoryId: 1, lifeEventCategory: workCategory),
            LifeEventType(id: 4, name: "Graduation", coreMonicaData: true, lifeEventCategoryId: 1, lifeEventCategory: workCategory),
            LifeEventType(id: 5, name: "Published work", coreMonicaData: true, lifeEventCategoryId: 1, lifeEventCategory: workCategory),

            // Family & Relationships
            LifeEventType(id: 6, name: "Marriage", coreMonicaData: true, lifeEventCategoryId: 2, lifeEventCategory: familyCategory),
            LifeEventType(id: 7, name: "Engaged", coreMonicaData: true, lifeEventCategoryId: 2, lifeEventCategory: familyCategory),
            LifeEventType(id: 8, name: "Divorce", coreMonicaData: true, lifeEventCategoryId: 2, lifeEventCategory: familyCategory),
            LifeEventType(id: 9, name: "New child", coreMonicaData: true, lifeEventCategoryId: 2, lifeEventCategory: familyCategory),
            LifeEventType(id: 10, name: "New relationship", coreMonicaData: true, lifeEventCategoryId: 2, lifeEventCategory: familyCategory),

            // Home & Living
            LifeEventType(id: 11, name: "Moved", coreMonicaData: true, lifeEventCategoryId: 3, lifeEventCategory: homeCategory),
            LifeEventType(id: 12, name: "Bought house", coreMonicaData: true, lifeEventCategoryId: 3, lifeEventCategory: homeCategory),
            LifeEventType(id: 13, name: "New roommate", coreMonicaData: true, lifeEventCategoryId: 3, lifeEventCategory: homeCategory),

            // Health & Wellness
            LifeEventType(id: 14, name: "Hospitalization", coreMonicaData: true, lifeEventCategoryId: 4, lifeEventCategory: healthCategory),
            LifeEventType(id: 15, name: "Surgery", coreMonicaData: true, lifeEventCategoryId: 4, lifeEventCategory: healthCategory),
            LifeEventType(id: 16, name: "Started therapy", coreMonicaData: true, lifeEventCategoryId: 4, lifeEventCategory: healthCategory),

            // Travel & Experiences
            LifeEventType(id: 17, name: "Traveled", coreMonicaData: true, lifeEventCategoryId: 5, lifeEventCategory: travelCategory),
            LifeEventType(id: 18, name: "Started hobby", coreMonicaData: true, lifeEventCategoryId: 5, lifeEventCategory: travelCategory),
            LifeEventType(id: 19, name: "Achieved goal", coreMonicaData: true, lifeEventCategoryId: 5, lifeEventCategory: travelCategory),
        ]
    }()
}

typealias LifeEventTypesResponse = APIResponse<[LifeEventType]>

/// Life event for a contact
struct LifeEvent: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let lifeEventTypeId: Int
    let lifeEventType: LifeEventType?
    let happenedAt: Date
    let name: String
    let note: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case lifeEventTypeId = "life_event_type_id"
        case lifeEventType = "life_event_type"
        case happenedAt = "happened_at"
        case name
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Icon for display based on event type or name
    var icon: String {
        lifeEventType?.icon ?? "star.fill"
    }

    /// Category name if available
    var categoryName: String? {
        lifeEventType?.lifeEventCategory?.name
    }

    /// How long ago the event happened
    var timeAgo: String {
        let interval = Date().timeIntervalSince(happenedAt)
        let days = Int(interval / 86400)

        if days < 1 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s") ago"
        } else {
            let years = days / 365
            return "\(years) year\(years == 1 ? "" : "s") ago"
        }
    }

    /// Year of the event for grouping
    var year: Int {
        Calendar.current.component(.year, from: happenedAt)
    }

    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: happenedAt)
    }
}

typealias LifeEventsResponse = APIResponse<[LifeEvent]>

struct LifeEventSingleResponse: Codable {
    let data: LifeEvent
}

struct LifeEventCreatePayload: Codable {
    let contactId: Int
    let lifeEventTypeId: Int
    let name: String
    let happenedAt: String
    let note: String?
    let hasReminder: Bool
    let happenedAtMonthUnknown: Bool
    let happenedAtDayUnknown: Bool

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case lifeEventTypeId = "life_event_type_id"
        case name
        case happenedAt = "happened_at"
        case note
        case hasReminder = "has_reminder"
        case happenedAtMonthUnknown = "happened_at_month_unknown"
        case happenedAtDayUnknown = "happened_at_day_unknown"
    }
}

struct LifeEventUpdatePayload: Codable {
    let lifeEventTypeId: Int?
    let name: String?
    let happenedAt: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case lifeEventTypeId = "life_event_type_id"
        case name
        case happenedAt = "happened_at"
        case note
    }
}

// MARK: - Photos

/// Photo attached to a contact
struct Photo: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let originalFilename: String
    let newFilename: String
    let filesize: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case originalFilename = "original_filename"
        case newFilename = "new_filename"
        case filesize
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias PhotosResponse = APIResponse<[Photo]>

// MARK: - Documents

/// Document attached to a contact
struct Document: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let originalFilename: String
    let newFilename: String
    let filesize: Int
    let type: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case originalFilename = "original_filename"
        case newFilename = "new_filename"
        case filesize
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias DocumentsResponse = APIResponse<[Document]>