import Foundation

/// Gender-specific relationship name mappings
/// The Monica API returns generic reverse relationship names (e.g., "child")
/// This helper provides gender-specific display names (e.g., "son", "daughter")
struct GenderedRelationshipName {
    let generic: String
    let male: String
    let female: String
    let neutral: String

    /// Get the appropriate display name based on gender
    /// - Parameter gender: The contact's gender string (e.g., "male", "female", "Man", "Woman")
    /// - Returns: Gender-specific name or neutral fallback
    func displayName(for gender: String?) -> String {
        guard let gender = gender?.lowercased() else {
            return neutral
        }

        switch gender {
        case "male", "man", "m":
            return male
        case "female", "woman", "f":
            return female
        default:
            return neutral
        }
    }
}

/// Static mappings for common relationship types
enum GenderMappings {
    /// Map of generic relationship names to their gendered variants
    static let mappings: [String: GenderedRelationshipName] = [
        // Family relationships
        "child": GenderedRelationshipName(
            generic: "child",
            male: "son",
            female: "daughter",
            neutral: "child"
        ),
        "parent": GenderedRelationshipName(
            generic: "parent",
            male: "father",
            female: "mother",
            neutral: "parent"
        ),
        "sibling": GenderedRelationshipName(
            generic: "sibling",
            male: "brother",
            female: "sister",
            neutral: "sibling"
        ),
        "grandchild": GenderedRelationshipName(
            generic: "grandchild",
            male: "grandson",
            female: "granddaughter",
            neutral: "grandchild"
        ),
        "grandparent": GenderedRelationshipName(
            generic: "grandparent",
            male: "grandfather",
            female: "grandmother",
            neutral: "grandparent"
        ),
        "uncle/aunt": GenderedRelationshipName(
            generic: "uncle/aunt",
            male: "uncle",
            female: "aunt",
            neutral: "uncle/aunt"
        ),
        "aunt/uncle": GenderedRelationshipName(
            generic: "aunt/uncle",
            male: "uncle",
            female: "aunt",
            neutral: "aunt/uncle"
        ),
        "nephew/niece": GenderedRelationshipName(
            generic: "nephew/niece",
            male: "nephew",
            female: "niece",
            neutral: "nephew/niece"
        ),
        "niece/nephew": GenderedRelationshipName(
            generic: "niece/nephew",
            male: "nephew",
            female: "niece",
            neutral: "niece/nephew"
        ),

        // Love relationships
        "spouse": GenderedRelationshipName(
            generic: "spouse",
            male: "husband",
            female: "wife",
            neutral: "spouse"
        ),
        "partner": GenderedRelationshipName(
            generic: "partner",
            male: "partner",
            female: "partner",
            neutral: "partner"
        ),
        "ex-spouse": GenderedRelationshipName(
            generic: "ex-spouse",
            male: "ex-husband",
            female: "ex-wife",
            neutral: "ex-spouse"
        ),
        "ex-partner": GenderedRelationshipName(
            generic: "ex-partner",
            male: "ex-partner",
            female: "ex-partner",
            neutral: "ex-partner"
        ),

        // Gender-neutral relationships (same for all genders)
        "cousin": GenderedRelationshipName(
            generic: "cousin",
            male: "cousin",
            female: "cousin",
            neutral: "cousin"
        ),
        "friend": GenderedRelationshipName(
            generic: "friend",
            male: "friend",
            female: "friend",
            neutral: "friend"
        ),
        "best friend": GenderedRelationshipName(
            generic: "best friend",
            male: "best friend",
            female: "best friend",
            neutral: "best friend"
        ),
        "colleague": GenderedRelationshipName(
            generic: "colleague",
            male: "colleague",
            female: "colleague",
            neutral: "colleague"
        ),
        "boss": GenderedRelationshipName(
            generic: "boss",
            male: "boss",
            female: "boss",
            neutral: "boss"
        ),
        "mentor": GenderedRelationshipName(
            generic: "mentor",
            male: "mentor",
            female: "mentor",
            neutral: "mentor"
        ),
        "mentee": GenderedRelationshipName(
            generic: "mentee",
            male: "mentee",
            female: "mentee",
            neutral: "mentee"
        ),
        "godparent": GenderedRelationshipName(
            generic: "godparent",
            male: "godfather",
            female: "godmother",
            neutral: "godparent"
        ),
        "godchild": GenderedRelationshipName(
            generic: "godchild",
            male: "godson",
            female: "goddaughter",
            neutral: "godchild"
        ),
        "stepparent": GenderedRelationshipName(
            generic: "stepparent",
            male: "stepfather",
            female: "stepmother",
            neutral: "stepparent"
        ),
        "stepchild": GenderedRelationshipName(
            generic: "stepchild",
            male: "stepson",
            female: "stepdaughter",
            neutral: "stepchild"
        ),
        "half-sibling": GenderedRelationshipName(
            generic: "half-sibling",
            male: "half-brother",
            female: "half-sister",
            neutral: "half-sibling"
        ),
        "step-sibling": GenderedRelationshipName(
            generic: "step-sibling",
            male: "stepbrother",
            female: "stepsister",
            neutral: "step-sibling"
        ),
        "in-law": GenderedRelationshipName(
            generic: "in-law",
            male: "brother-in-law",
            female: "sister-in-law",
            neutral: "in-law"
        ),
        "parent-in-law": GenderedRelationshipName(
            generic: "parent-in-law",
            male: "father-in-law",
            female: "mother-in-law",
            neutral: "parent-in-law"
        ),
        "child-in-law": GenderedRelationshipName(
            generic: "child-in-law",
            male: "son-in-law",
            female: "daughter-in-law",
            neutral: "child-in-law"
        )
    ]

    /// Get the gender-specific display name for a relationship type
    /// - Parameters:
    ///   - genericName: The generic relationship name from the API
    ///   - gender: The contact's gender
    /// - Returns: Gender-appropriate display name
    static func displayName(for genericName: String, gender: String?) -> String {
        let lowercaseName = genericName.lowercased()

        // Try exact match first
        if let mapping = mappings[lowercaseName] {
            return mapping.displayName(for: gender)
        }

        // Try partial match for compound names
        for (key, mapping) in mappings {
            if lowercaseName.contains(key) {
                return mapping.displayName(for: gender)
            }
        }

        // No mapping found, return original name capitalized
        return genericName.capitalized
    }
}
