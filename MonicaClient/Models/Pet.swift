import Foundation

/// Pet category from Monica API (e.g., Dog, Cat, Bird)
/// Note: Monica v4.x doesn't have a /petcategories endpoint.
/// Categories are instance-specific and must be discovered from existing pets
/// or by using a predefined list that matches the user's Monica database.
struct PetCategory: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?  // Optional - API may not always return name
    let isCommon: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isCommon = "is_common"
    }

    /// Standard pet category names (used for display in picker)
    /// Note: IDs vary by Monica instance - these are just the common category NAMES
    static let standardCategoryNames = [
        "Dog", "Cat", "Bird", "Fish", "Small pet", "Rabbit", "Reptile", "Horse", "Other"
    ]

    /// Cache of discovered categories from the user's Monica instance
    /// Maps category name (lowercase) to PetCategory with correct ID
    private static var discoveredCategories: [String: PetCategory] = [:]

    /// Register a discovered category from API response
    static func registerDiscovered(_ category: PetCategory) {
        guard let name = category.name, !name.isEmpty else { return }
        let key = name.lowercased()
        // Only update if we don't have this category or if this one has more complete info
        if discoveredCategories[key] == nil {
            discoveredCategories[key] = category
            print("🐾 Discovered pet category: \(name) (id=\(category.id))")
        }
    }

    /// Get all discovered categories, sorted by name
    static func getDiscoveredCategories() -> [PetCategory] {
        Array(discoveredCategories.values).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    /// Look up a discovered category by name
    static func fromName(_ name: String) -> PetCategory? {
        discoveredCategories[name.lowercased()]
    }

    /// Check if we have discovered any categories yet
    static var hasDiscoveredCategories: Bool {
        !discoveredCategories.isEmpty
    }

    /// Clear discovered categories (for testing/refresh)
    static func clearDiscoveredCategories() {
        discoveredCategories.removeAll()
    }

    /// Resolved name - uses name directly from API response
    var resolvedName: String {
        if let n = name, !n.isEmpty {
            return n
        }
        return "Other"
    }

    /// SF Symbol icon for pet type
    var icon: String {
        switch resolvedName.lowercased() {
        case "dog": return "dog"
        case "cat": return "cat"
        case "bird": return "bird"
        case "fish": return "fish"
        case "rabbit": return "hare"
        case "hamster", "small pet": return "hare"
        case "reptile": return "lizard"
        case "horse": return "hare"
        default: return "pawprint"
        }
    }

    /// Emoji representation for pet type
    var emoji: String {
        switch resolvedName.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        case "fish": return "🐟"
        case "rabbit": return "🐰"
        case "hamster", "small pet": return "🐹"
        case "reptile": return "🦎"
        case "horse": return "🐴"
        default: return "🐾"
        }
    }
}

/// Pet belonging to a contact
/// API: Monica v4.x /api/pets and /api/contacts/{id}/pets
struct Pet: Codable, Identifiable {
    let id: Int
    let name: String?
    let petCategory: PetCategory?
    let contact: PetContact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case petCategory = "pet_category"
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Display name with fallback logic
    var displayName: String {
        if let petName = name, !petName.isEmpty {
            return petName
        }
        return petCategory?.resolvedName ?? "Pet"
    }

    /// Icon from category (uses resolvedName for lookup)
    var icon: String {
        petCategory?.icon ?? "pawprint"
    }

    /// Emoji from category (uses resolvedName for lookup)
    var emoji: String {
        petCategory?.emoji ?? "🐾"
    }

    /// Category name for display
    var categoryName: String {
        petCategory?.resolvedName ?? "Other"
    }

    /// Memberwise initializer for previews
    init(id: Int, name: String?, petCategory: PetCategory?, contact: PetContact?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.petCategory = petCategory
        self.contact = contact
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Nested contact info in Pet response
struct PetContact: Codable {
    let id: Int
}

// MARK: - API Response Types

typealias PetsResponse = APIResponse<[Pet]>
typealias PetCategoriesResponse = APIResponse<[PetCategory]>

struct PetSingleResponse: Codable {
    let data: Pet
}

// MARK: - API Payload Types

struct PetCreatePayload: Codable {
    let contactId: Int
    let petCategoryId: Int
    let name: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case petCategoryId = "pet_category_id"
        case name
    }
}

struct PetUpdatePayload: Codable {
    let contactId: Int
    let petCategoryId: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case petCategoryId = "pet_category_id"
        case name
    }
}
