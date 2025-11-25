import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var apiURL: String?
    @Published var apiToken: String?
    @Published var availableGenders: [Gender] = []
    @Published var availableRelationshipTypes: [RelationshipType] = []
    @Published var availableRelationshipTypeGroups: [RelationshipTypeGroup] = []
    @Published var availableTags: [Tag] = []

    private let keychainManager = KeychainManager()
    private var apiClient: MonicaAPIClient?
    
    init() {
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    func checkAuthenticationStatus() async {
        if let credentials = keychainManager.getCredentials() {
            self.apiURL = credentials.apiURL
            self.apiToken = credentials.apiToken
            self.apiClient = MonicaAPIClient(baseURL: credentials.apiURL, apiToken: credentials.apiToken)

            do {
                try await apiClient?.testConnection()
                self.isAuthenticated = true

                // Fetch configuration variables after successful authentication
                await fetchConfigurationVariables()
            } catch {
                self.isAuthenticated = false
                keychainManager.deleteCredentials()
            }
        } else {
            self.isAuthenticated = false
        }
    }
    
    func authenticate(apiURL: String, apiToken: String) async throws {
        let client = MonicaAPIClient(baseURL: apiURL, apiToken: apiToken)

        try await client.testConnection()

        keychainManager.saveCredentials(apiURL: apiURL, apiToken: apiToken)

        self.apiURL = apiURL
        self.apiToken = apiToken
        self.apiClient = client
        self.isAuthenticated = true

        // Fetch configuration variables after successful authentication
        await fetchConfigurationVariables()
    }
    
    func logout() {
        keychainManager.deleteCredentials()
        self.apiURL = nil
        self.apiToken = nil
        self.apiClient = nil
        self.isAuthenticated = false
        self.availableGenders = []
        self.availableRelationshipTypes = []
        self.availableRelationshipTypeGroups = []
        self.availableTags = []

        // Clear image cache on logout (001-003-avatar-authentication)
        AuthenticatedImageLoader.clearCache()
    }

    var currentAPIClient: MonicaAPIClient? {
        return apiClient
    }

    /// Fetch configuration variables (genders, relationship types, relationship type groups, tags) from the API
    /// These are system-wide configuration options that rarely change
    /// Can be called on login or manually via refreshConfigurationVariables()
    private func fetchConfigurationVariables() async {
        guard let apiClient = apiClient else { return }

        // Fetch genders
        do {
            let genders = try await apiClient.fetchGenders()
            self.availableGenders = genders
            print("✅ Loaded \(genders.count) genders")
        } catch {
            print("⚠️ Failed to load genders: \(error.localizedDescription)")
            // Don't fail authentication if genders can't be loaded
        }

        // Fetch relationship type groups first
        do {
            let groups = try await apiClient.fetchRelationshipTypeGroups()
            self.availableRelationshipTypeGroups = groups
            print("✅ Loaded \(groups.count) relationship type groups")
        } catch {
            print("⚠️ Failed to load relationship type groups: \(error.localizedDescription)")
            // Don't fail authentication if relationship type groups can't be loaded
        }

        // Fetch relationship types
        do {
            let types = try await apiClient.fetchRelationshipTypes()
            self.availableRelationshipTypes = types
            print("✅ Loaded \(types.count) relationship types")
        } catch {
            print("⚠️ Failed to load relationship types: \(error.localizedDescription)")
            // Don't fail authentication if relationship types can't be loaded
        }

        // Fetch tags
        do {
            let tags = try await apiClient.fetchTags()
            self.availableTags = tags
            print("✅ Loaded \(tags.count) tags")
        } catch {
            print("⚠️ Failed to load tags: \(error.localizedDescription)")
            // Don't fail authentication if tags can't be loaded
        }

        // Fetch and cache countries (used for address forms)
        do {
            let countries = try await apiClient.fetchCountries()
            CacheService.shared.setCountries(countries)
            print("✅ Loaded and cached \(countries.count) countries")
        } catch {
            print("⚠️ Failed to load countries: \(error.localizedDescription)")
            // Don't fail authentication if countries can't be loaded
        }
    }

    /// Manually refresh configuration variables
    /// Call this when user adds/modifies genders, relationship types, or tags in the web UI
    func refreshConfigurationVariables() async {
        print("🔄 Refreshing configuration variables...")
        await fetchConfigurationVariables()
        print("✅ Configuration variables refreshed")
    }
}