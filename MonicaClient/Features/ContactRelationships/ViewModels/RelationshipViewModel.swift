import Foundation
import SwiftUI

/// ViewModel for managing contact relationships
/// Handles state management, caching, and validation for relationship operations
@MainActor
final class RelationshipViewModel: ObservableObject {
    // MARK: - Published State

    /// Current relationships for the active contact
    @Published var relationships: [Relationship] = []

    /// Available relationship types (cached)
    @Published var relationshipTypes: [RelationshipType] = []

    /// Relationship type groups/categories (cached)
    @Published var relationshipTypeGroups: [RelationshipTypeGroup] = []

    /// Contact search results
    @Published var searchResults: [Contact] = []

    /// Loading states
    @Published var isLoadingRelationships = false
    @Published var isLoadingTypes = false
    @Published var isSearching = false
    @Published var isSaving = false

    /// Error state
    @Published var error: Error?
    @Published var validationError: RelationshipValidationError?

    // MARK: - Private Properties

    private let apiService: RelationshipAPIService
    private var currentContactId: Int?
    private var typesLoaded = false

    // MARK: - Initialization

    init(apiService: RelationshipAPIService) {
        self.apiService = apiService
    }

    // MARK: - Relationship Type Loading & Caching

    /// Load and cache relationship types (call once on first use)
    func loadRelationshipTypesIfNeeded() async {
        guard !typesLoaded else { return }

        isLoadingTypes = true
        error = nil

        do {
            async let typesTask = apiService.fetchRelationshipTypes()
            async let groupsTask = apiService.fetchRelationshipTypeGroups()

            let (types, groups) = try await (typesTask, groupsTask)
            relationshipTypes = types
            relationshipTypeGroups = groups
            typesLoaded = true
        } catch {
            self.error = error
            print("Failed to load relationship types: \(error)")
        }

        isLoadingTypes = false
    }

    /// Force reload relationship types
    func reloadRelationshipTypes() async {
        typesLoaded = false
        await loadRelationshipTypesIfNeeded()
    }

    // MARK: - Relationship Type Grouping

    /// Get relationship types grouped by category
    var groupedRelationshipTypes: [(RelationshipCategory, [RelationshipType])] {
        var grouped: [Int: [RelationshipType]] = [:]

        for type in relationshipTypes {
            let groupId = type.relationshipTypeGroupId
            grouped[groupId, default: []].append(type)
        }

        // Map group IDs to categories and sort
        var result: [(RelationshipCategory, [RelationshipType])] = []

        for group in relationshipTypeGroups {
            let category = RelationshipCategory(groupName: group.name)
            if let types = grouped[group.id], !types.isEmpty {
                // Sort types alphabetically within each group
                let sortedTypes = types.sorted { $0.name < $1.name }
                result.append((category, sortedTypes))
            }
        }

        // Sort categories by display order
        let categoryOrder: [RelationshipCategory] = [.family, .love, .friend, .work, .other]
        result.sort { lhs, rhs in
            let lhsIndex = categoryOrder.firstIndex(of: lhs.0) ?? categoryOrder.count
            let rhsIndex = categoryOrder.firstIndex(of: rhs.0) ?? categoryOrder.count
            return lhsIndex < rhsIndex
        }

        return result
    }

    /// Get category for a relationship type
    func category(for relationshipType: RelationshipType) -> RelationshipCategory {
        guard let group = relationshipTypeGroups.first(where: { $0.id == relationshipType.relationshipTypeGroupId }) else {
            return .other
        }
        return RelationshipCategory(groupName: group.name)
    }

    // MARK: - Gender-Aware Display Names

    /// Get the display name for a relationship type, considering the contact's gender
    /// - Parameters:
    ///   - relationshipType: The relationship type
    ///   - gender: The related contact's gender
    /// - Returns: Gender-appropriate display name
    func displayName(for relationshipType: RelationshipType, gender: String?) -> String {
        GenderMappings.displayName(for: relationshipType.name, gender: gender)
    }

    /// Get the reverse relationship display name
    /// - Parameters:
    ///   - relationshipType: The relationship type
    ///   - gender: The source contact's gender (for reverse direction)
    /// - Returns: Gender-appropriate reverse relationship name
    func reverseDisplayName(for relationshipType: RelationshipType, gender: String?) -> String {
        GenderMappings.displayName(for: relationshipType.nameReverseRelationship, gender: gender)
    }

    // MARK: - Relationship Loading

    /// Load relationships for a contact
    func loadRelationships(for contactId: Int) async {
        currentContactId = contactId
        isLoadingRelationships = true
        error = nil

        do {
            relationships = try await apiService.fetchRelationships(for: contactId)
        } catch {
            self.error = error
            print("Failed to load relationships: \(error)")
        }

        isLoadingRelationships = false
    }

    /// Refresh relationships for the current contact
    func refreshRelationships() async {
        guard let contactId = currentContactId else { return }
        await loadRelationships(for: contactId)
    }

    // MARK: - Relationship Grouping for Display

    /// Get relationships grouped by category for display
    var groupedRelationships: [(RelationshipCategory, [Relationship])] {
        var grouped: [RelationshipCategory: [Relationship]] = [:]

        for relationship in relationships {
            let category = category(for: relationship.relationshipType)
            grouped[category, default: []].append(relationship)
        }

        // Sort and return
        let categoryOrder: [RelationshipCategory] = [.family, .love, .friend, .work, .other]
        return categoryOrder.compactMap { category in
            guard let relationships = grouped[category], !relationships.isEmpty else {
                return nil
            }
            return (category, relationships)
        }
    }

    // MARK: - CRUD Operations

    /// Create a new relationship
    /// - Parameters:
    ///   - sourceContactId: The contact initiating the relationship
    ///   - targetContactId: The target contact
    ///   - relationshipTypeId: The type of relationship
    /// - Returns: The created relationship, or nil if validation failed
    @discardableResult
    func createRelationship(
        sourceContactId: Int,
        targetContactId: Int,
        relationshipTypeId: Int
    ) async -> Relationship? {
        // Validation
        validationError = nil

        // Check for self-relationship
        if sourceContactId == targetContactId {
            validationError = .selfRelationship
            return nil
        }

        // Check for duplicate
        if isDuplicateRelationship(sourceContactId: sourceContactId, targetContactId: targetContactId, relationshipTypeId: relationshipTypeId) {
            validationError = .duplicateRelationship
            return nil
        }

        // Check valid type
        guard relationshipTypes.contains(where: { $0.id == relationshipTypeId }) else {
            validationError = .invalidRelationshipType
            return nil
        }

        isSaving = true
        error = nil

        do {
            let relationship = try await apiService.createRelationship(
                sourceContactId: sourceContactId,
                targetContactId: targetContactId,
                relationshipTypeId: relationshipTypeId
            )

            // Refresh relationships to include the new one
            await refreshRelationships()

            isSaving = false
            return relationship
        } catch {
            self.error = error
            print("Failed to create relationship: \(error)")
            isSaving = false
            return nil
        }
    }

    /// Update an existing relationship's type
    /// - Parameters:
    ///   - relationshipId: The relationship to update
    ///   - relationshipTypeId: The new type
    /// - Returns: The updated relationship, or nil if failed
    @discardableResult
    func updateRelationship(
        relationshipId: Int,
        relationshipTypeId: Int
    ) async -> Relationship? {
        validationError = nil

        guard relationshipTypes.contains(where: { $0.id == relationshipTypeId }) else {
            validationError = .invalidRelationshipType
            return nil
        }

        isSaving = true
        error = nil

        do {
            let relationship = try await apiService.updateRelationship(
                relationshipId: relationshipId,
                relationshipTypeId: relationshipTypeId
            )

            // Refresh relationships
            await refreshRelationships()

            isSaving = false
            return relationship
        } catch {
            self.error = error
            print("Failed to update relationship: \(error)")
            isSaving = false
            return nil
        }
    }

    /// Delete a relationship
    /// - Parameter relationshipId: The relationship to delete
    /// - Returns: True if successful
    @discardableResult
    func deleteRelationship(relationshipId: Int) async -> Bool {
        isSaving = true
        error = nil

        do {
            try await apiService.deleteRelationship(relationshipId: relationshipId)

            // Refresh relationships
            await refreshRelationships()

            isSaving = false
            return true
        } catch {
            self.error = error
            print("Failed to delete relationship: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Contact Search

    /// Search for contacts to add as relationships
    /// - Parameters:
    ///   - query: Search query
    ///   - excludeContactId: Contact ID to exclude from results (usually current contact)
    func searchContacts(query: String, excludeContactId: Int? = nil) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            var results = try await apiService.searchContacts(query: query)

            // Exclude the current contact from results
            if let excludeId = excludeContactId {
                results = results.filter { $0.id != excludeId }
            }

            searchResults = results
        } catch {
            print("Contact search failed: \(error)")
            searchResults = []
        }

        isSearching = false
    }

    /// Clear search results
    func clearSearchResults() {
        searchResults = []
    }

    // MARK: - Validation Helpers

    /// Check if a relationship would be a duplicate
    private func isDuplicateRelationship(
        sourceContactId: Int,
        targetContactId: Int,
        relationshipTypeId: Int
    ) -> Bool {
        relationships.contains { relationship in
            relationship.contactIs.id == sourceContactId &&
            relationship.ofContact.id == targetContactId &&
            relationship.relationshipType.id == relationshipTypeId
        }
    }

    /// Check if a relationship exists between two contacts (any type)
    func hasExistingRelationship(with contactId: Int) -> Bool {
        relationships.contains { relationship in
            relationship.ofContact.id == contactId
        }
    }

    // MARK: - Error Handling

    /// Clear all errors
    func clearErrors() {
        error = nil
        validationError = nil
    }
}
