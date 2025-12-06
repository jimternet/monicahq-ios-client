import Foundation

/// Service wrapper for relationship-related API operations
/// Provides a clean interface to MonicaAPIClient relationship methods
final class RelationshipAPIService {
    private let apiClient: MonicaAPIClient

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Relationship CRUD

    /// Fetch all relationships for a contact
    func fetchRelationships(for contactId: Int) async throws -> [Relationship] {
        try await apiClient.fetchContactRelationships(contactId: contactId)
    }

    /// Create a new relationship between two contacts
    /// - Parameters:
    ///   - sourceContactId: The contact who "is" the relationship (e.g., John)
    ///   - targetContactId: The contact "of" whom the relationship exists (e.g., Jane)
    ///   - relationshipTypeId: The type of relationship (e.g., father, spouse)
    /// - Returns: The created relationship
    /// - Note: Monica API automatically creates the reverse relationship
    func createRelationship(
        sourceContactId: Int,
        targetContactId: Int,
        relationshipTypeId: Int
    ) async throws -> Relationship {
        try await apiClient.createRelationship(
            contactIs: sourceContactId,
            ofContact: targetContactId,
            relationshipTypeId: relationshipTypeId
        )
    }

    /// Update an existing relationship's type
    /// - Parameters:
    ///   - relationshipId: The relationship to update
    ///   - relationshipTypeId: The new relationship type
    /// - Returns: The updated relationship
    func updateRelationship(
        relationshipId: Int,
        relationshipTypeId: Int
    ) async throws -> Relationship {
        try await apiClient.updateRelationship(
            relationshipId: relationshipId,
            relationshipTypeId: relationshipTypeId
        )
    }

    /// Delete a relationship
    /// - Parameter relationshipId: The relationship to delete
    func deleteRelationship(relationshipId: Int) async throws {
        try await apiClient.deleteRelationship(relationshipId: relationshipId)
    }

    // MARK: - Relationship Types

    /// Fetch all available relationship types
    func fetchRelationshipTypes() async throws -> [RelationshipType] {
        try await apiClient.fetchRelationshipTypes()
    }

    /// Fetch relationship type groups (categories)
    func fetchRelationshipTypeGroups() async throws -> [RelationshipTypeGroup] {
        try await apiClient.fetchRelationshipTypeGroups()
    }

    // MARK: - Contact Search

    /// Search for contacts by name
    /// - Parameter query: Search query string
    /// - Returns: Matching contacts
    func searchContacts(query: String) async throws -> [Contact] {
        let response = try await apiClient.searchContacts(query: query)
        return response.data
    }

    /// Fetch a single contact by ID
    func fetchContact(id: Int) async throws -> Contact {
        try await apiClient.fetchSingleContact(id: id)
    }
}
