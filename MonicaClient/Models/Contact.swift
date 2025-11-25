import Foundation

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

    // MARK: - Avatar Computed Properties (001-003-avatar-authentication)

    /// Determines if avatar image should be loaded from network
    var shouldLoadAvatar: Bool {
        guard let avatar = information?.avatar else { return false }
        // Only load if we have a URL and source is not default
        guard let url = avatar.url, !url.isEmpty else { return false }
        return avatar.sourceType != .default
    }

    /// Initials for fallback avatar display (uses API-provided or computes from name)
    var initialsForAvatar: String {
        // Prefer API-provided initials
        if !initials.isEmpty {
            return initials
        }
        // Fallback to computed
        return computedInitials
    }

    /// Color for initials avatar (uses API color or generates from name)
    var initialsColor: String {
        if let color = avatarColor, !color.isEmpty {
            return color
        }
        // Fallback to generated color
        return generateColorFromName()
    }

    /// Generate a deterministic color from contact name for initials avatar
    private func generateColorFromName() -> String {
        let name = completeName.lowercased()
        var hash: Int = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) + ((hash << 5) - hash)
        }
        let hue = abs(hash % 360)
        // Use HSL to generate pastel colors: saturation 45%, lightness 70%
        return "hsl(\(hue), 45%, 70%)"
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

/// Avatar source types from Monica API
enum AvatarSource: String, Codable {
    case `default` = "default"
    case photo = "photo"
    case gravatar = "gravatar"
    case adorable = "adorable"
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

    /// Parsed avatar source type
    var sourceType: AvatarSource {
        guard let source = source else { return .default }
        return AvatarSource(rawValue: source) ?? .default
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

// MARK: - Conversations

/// Conversation record (SMS, social media, etc.)
struct Conversation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?
    let content: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias ConversationsResponse = APIResponse<[Conversation]>

struct ConversationSingleResponse: Codable {
    let data: Conversation
}

struct ConversationCreatePayload: Codable {
    let contactId: Int
    let happenedAt: String
    let content: String?
    let contactFieldTypeId: Int?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case content
        case contactFieldTypeId = "contact_field_type_id"
    }
}

// MARK: - Debts

/// Debt tracking between user and contact
struct Debt: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let inDebt: Bool  // true = they owe you, false = you owe them
    let status: String
    let amount: Double
    let reason: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case reason
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

typealias DebtsResponse = APIResponse<[Debt]>

struct DebtSingleResponse: Codable {
    let data: Debt
}

struct DebtCreatePayload: Codable {
    let contactId: Int
    let inDebt: Bool
    let status: String
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
    let status: String?
    let amount: Double?
    let reason: String?
}

// MARK: - Life Events

/// Life event for a contact
struct LifeEvent: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let lifeEventTypeId: Int
    let happenedAt: Date
    let name: String
    let note: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case lifeEventTypeId = "life_event_type_id"
        case happenedAt = "happened_at"
        case name
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
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