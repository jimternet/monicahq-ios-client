import Foundation
import CoreData

class SyncManager {
    private let dataController: DataController
    private let authManager: AuthenticationManager
    
    init(dataController: DataController, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
    }
    
    @MainActor
    func syncContacts() async throws {
        guard let apiClient = authManager.currentAPIClient else {
            throw APIError.unauthorized
        }
        
        print("🔄 Starting basic contact sync...")
        let contacts = try await apiClient.fetchAllContacts()
        
        // Import basic contact data (not marked as detail synced)
        await dataController.importContacts(contacts, markAsDetailSynced: false)
        
        // Get cache statistics
        let stats = dataController.getCacheStatistics()
        print("📊 Cache stats: \(stats.total) total, \(stats.needingSync) need detail sync")
        
        // Sync details for a few contacts to start populating cache
        await syncContactDetailsInBackground(maxContacts: 5)
    }
    
    @MainActor
    func syncContactDetailsInBackground(maxContacts: Int = 10) async {
        guard let apiClient = authManager.currentAPIClient else {
            print("⚠️ No API client available for detail sync")
            return
        }
        
        let contactsNeedingSync = dataController.getContactsNeedingDetailSync(limit: maxContacts)
        guard !contactsNeedingSync.isEmpty else {
            print("✅ No contacts need detail sync")
            return
        }
        
        print("🔍 Syncing details for \(contactsNeedingSync.count) contacts...")
        
        for contact in contactsNeedingSync {
            do {
                print("  🔍 Fetching details and relationships for: \(contact.fullName)")
                let (detailedContact, relationships) = try await apiClient.fetchSingleContactWithRelationships(id: Int(contact.id))
                
                // Import the detailed contact data
                await dataController.importContacts([detailedContact], markAsDetailSynced: true)
                
                // Store relationships in the contact entity
                let fetchRequest = ContactEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %d", contact.id)
                
                if let savedContact = try? dataController.container.viewContext.fetch(fetchRequest).first {
                    savedContact.setRelationships(relationships)
                    dataController.save()
                    print("  ✅ Stored \(relationships.count) relationships for \(contact.fullName)")
                }
                
                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
            } catch {
                print("  ❌ Failed to sync details for contact \(contact.id): \(error)")
                // Mark as failed detail sync but don't retry immediately
                if error is APIError {
                    // If it's an API error, back off to avoid rate limits
                    break
                }
            }
        }
        
        let remainingStats = dataController.getCacheStatistics()
        print("📊 After detail sync: \(remainingStats.needingSync) contacts still need detail sync")
    }
    
    @MainActor
    func syncSingleContactDetails(id: Int32) async throws {
        guard let apiClient = authManager.currentAPIClient else {
            throw APIError.unauthorized
        }
        
        print("🔍 Syncing details and relationships for contact \(id)")
        let (detailedContact, relationships) = try await apiClient.fetchSingleContactWithRelationships(id: Int(id))
        await dataController.importContacts([detailedContact], markAsDetailSynced: true)
        
        // Store relationships in the contact entity
        let fetchRequest = ContactEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
        if let savedContact = try? dataController.container.viewContext.fetch(fetchRequest).first {
            savedContact.setRelationships(relationships)
            dataController.save()
            print("✅ Stored \(relationships.count) relationships for contact \(id)")
        }
    }
    
    @MainActor
    func syncSingleContact(id: Int) async throws {
        guard let apiClient = authManager.currentAPIClient else {
            throw APIError.unauthorized
        }
        
        let response = try await apiClient.fetchContacts(page: 1, limit: 1)
        if let contact = response.data.first(where: { $0.id == id }) {
            await dataController.importContacts([contact])
        }
    }
}