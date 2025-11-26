import CoreData
import Foundation

@MainActor
class DataController: ObservableObject {
    let container: NSPersistentContainer
    let authManager: AuthenticationManager
    @Published var isLoaded = false
    
    lazy var syncManager: SyncManager = {
        return SyncManager(dataController: self, authManager: self.authManager)
    }()
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        
        // Create the Core Data model programmatically to avoid Xcode project issues
        let model = Self.createDataModel()
        self.container = NSPersistentContainer(name: "MonicaClient", managedObjectModel: model)
        
        // Use persistent SQLite store that survives app rebuilds
        let storeURL = URL.documentsDirectory.appendingPathComponent("MonicaClient.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        print("📁 Using persistent store at: \(storeURL.path)")
        
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded with persistent SQLite store")
                print("Store URL: \(description.url?.path ?? "unknown")")
            }
            DispatchQueue.main.async {
                self?.isLoaded = true
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        print("✅ DataController initialized with persistent caching")
    }
    
    private static func createDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create ContactEntity
        let contactEntity = NSEntityDescription()
        contactEntity.name = "ContactEntity"
        contactEntity.managedObjectClassName = "ContactEntity"
        
        // Define all attributes with their types and optionality
        let attributes: [(String, NSAttributeType, Bool, Any?)] = [
            ("id", .integer32AttributeType, false, nil),
            ("firstName", .stringAttributeType, true, nil),
            ("lastName", .stringAttributeType, true, nil),
            ("nickname", .stringAttributeType, true, nil),
            ("email", .stringAttributeType, true, nil),
            ("phone", .stringAttributeType, true, nil),
            ("address", .stringAttributeType, true, nil),
            ("company", .stringAttributeType, true, nil),
            ("jobTitle", .stringAttributeType, true, nil),
            ("notes", .stringAttributeType, true, nil),
            ("birthdate", .dateAttributeType, true, nil),
            ("birthdateIsAgeBased", .booleanAttributeType, false, false),
            ("birthdateAge", .integer32AttributeType, false, 0),
            ("isBirthdateKnown", .booleanAttributeType, false, false),
            ("createdAt", .dateAttributeType, true, nil),
            ("updatedAt", .dateAttributeType, true, nil),
            ("lastSyncedAt", .dateAttributeType, true, nil),
            ("detailsSyncedAt", .dateAttributeType, true, nil),
            ("needsDetailSync", .booleanAttributeType, false, true),
            ("relationshipsJSON", .stringAttributeType, true, nil),
            ("avatarURL", .stringAttributeType, true, nil),
            ("avatarColor", .stringAttributeType, true, nil),
            ("isStarred", .booleanAttributeType, false, false),
            ("gender", .stringAttributeType, true, nil),
            ("genderType", .stringAttributeType, true, nil),
            ("howYouMet", .stringAttributeType, true, nil),
            ("stayInTouchFrequency", .integer32AttributeType, true, nil),
            ("stayInTouchTriggerDate", .dateAttributeType, true, nil),
            ("foodPreferences", .stringAttributeType, true, nil),
            ("contactDescription", .stringAttributeType, true, nil)
        ]
        
        for (name, type, isOptional, defaultValue) in attributes {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = isOptional

            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }

            contactEntity.properties.append(attribute)
        }

        // Create CallLogEntity
        let callLogEntity = NSEntityDescription()
        callLogEntity.name = "CallLogEntity"
        callLogEntity.managedObjectClassName = "CallLogEntity"

        // Add CallLogEntity attributes (verified against Monica v4.x source)
        let callLogAttributes: [(String, NSAttributeType, Bool, Any?)] = [
            ("id", .integer32AttributeType, false, 0),
            ("contactId", .integer32AttributeType, false, 0),
            ("calledAt", .dateAttributeType, true, nil),
            ("content", .stringAttributeType, true, nil),              // Call notes (Monica v4.x field name)
            ("contactCalled", .booleanAttributeType, false, false),    // Direction: true = they called me
            ("emotionsJSON", .stringAttributeType, true, nil),         // JSON array of emotion IDs
            ("syncStatus", .stringAttributeType, true, nil),
            ("syncError", .stringAttributeType, true, nil),
            ("lastSyncAttempt", .dateAttributeType, true, nil),
            ("isMarkedDeleted", .booleanAttributeType, false, false),
            ("createdAt", .dateAttributeType, true, nil),
            ("updatedAt", .dateAttributeType, true, nil)
        ]

        for (name, type, isOptional, defaultValue) in callLogAttributes {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = isOptional

            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }

            callLogEntity.properties.append(attribute)
        }

        model.entities = [contactEntity, callLogEntity]
        print("✅ Created Core Data model programmatically with \(contactEntity.properties.count) Contact attributes and \(callLogEntity.properties.count) CallLog attributes")

        return model
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func importContacts(_ contacts: [Contact], markAsDetailSynced: Bool = false) async {
        let context = container.viewContext
        
        print("💾 Importing \(contacts.count) contacts to Core Data...")
        
        for contact in contacts {
            let fetchRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", contact.id)
            
            do {
                let results = try context.fetch(fetchRequest)
                let entity = results.first ?? ContactEntity(context: context)
                let isNewEntity = results.isEmpty
                
                entity.id = Int32(contact.id)
                entity.firstName = contact.firstName
                entity.lastName = contact.lastName
                entity.nickname = contact.nickname
                entity.email = contact.email
                entity.phone = contact.phone
                // Extract birthdate from information.dates.birthdate.date structure (preferred) or legacy field
                let informationBirthdate = contact.information?.dates?.birthdate?.date
                let finalBirthdate = informationBirthdate ?? contact.birthdate
                entity.birthdate = finalBirthdate

                // Debug birthdate sync only when there's a mismatch
                #if DEBUG
                if informationBirthdate != contact.birthdate {
                    print("🎂 Birthdate mismatch for \(contact.completeName): info=\(informationBirthdate?.description ?? "nil"), legacy=\(contact.birthdate?.description ?? "nil")")
                }
                #endif
                entity.birthdateIsAgeBased = contact.birthdateIsAgeBased ?? false
                entity.birthdateAge = Int32(contact.birthdateAge ?? 0)
                entity.isBirthdateKnown = contact.isBirthdateKnown ?? false
                entity.address = contact.address
                entity.company = contact.company
                entity.jobTitle = contact.jobTitle
                entity.notes = contact.notes
                entity.avatarURL = contact.avatarURL
                entity.avatarColor = contact.avatarColor

                // Debug avatar sync
                if isNewEntity || entity.avatarURL != contact.avatarURL {
                    print("🖼️ Avatar sync for \(contact.completeName): URL=\(contact.avatarURL ?? "nil"), Color=\(contact.avatarColor ?? "nil")")
                }

                entity.isStarred = contact.isStarred
                entity.gender = contact.gender
                entity.genderType = contact.genderType
                entity.createdAt = contact.createdAt
                entity.updatedAt = contact.updatedAt
                entity.lastSyncedAt = Date()
                
                // Handle detailed sync tracking
                if markAsDetailSynced {
                    entity.detailsSyncedAt = Date()
                    entity.needsDetailSync = false
                    print("   ✅ Imported detailed: \(contact.firstName ?? "") \(contact.lastName ?? "")")
                } else if isNewEntity {
                    // New contacts need detail sync
                    entity.needsDetailSync = true
                    entity.detailsSyncedAt = nil
                    print("   ✅ Imported basic: \(contact.firstName ?? "") \(contact.lastName ?? "") [needs detail sync]")
                } else {
                    // Existing contact, check if it needs detail sync based on last update
                    if let lastDetailSync = entity.detailsSyncedAt,
                       contact.updatedAt > lastDetailSync {
                        entity.needsDetailSync = true
                        print("   🔄 Updated: \(contact.firstName ?? "") \(contact.lastName ?? "") [needs detail sync]")
                    } else {
                        // Keep existing needsDetailSync value if no update needed
                        print("   ✅ Updated basic: \(contact.firstName ?? "") \(contact.lastName ?? "") [cached details OK]")
                    }
                }
                
            } catch {
                print("   ❌ Failed to import contact \(contact.id): \(error)")
            }
        }
        
        save()
        print("💾 Core Data save completed")
    }
    
    func deleteContact(_ contact: ContactEntity) {
        container.viewContext.delete(contact)
        save()
    }
    
    func getContactsNeedingDetailSync(limit: Int = 10) -> [ContactEntity] {
        let fetchRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "needsDetailSync == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ContactEntity.lastSyncedAt, ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            print("📋 Found \(results.count) contacts needing detail sync")
            return results
        } catch {
            print("❌ Failed to fetch contacts needing detail sync: \(error)")
            return []
        }
    }
    
    func markContactAsDetailSynced(_ contactId: Int32) {
        let fetchRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", contactId)
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let contact = results.first {
                contact.detailsSyncedAt = Date()
                contact.needsDetailSync = false
                save()
                print("✅ Marked contact \(contactId) as detail synced")
            }
        } catch {
            print("❌ Failed to mark contact as detail synced: \(error)")
        }
    }
    
    func getCacheStatistics() -> (total: Int, needingSync: Int, lastSyncAge: TimeInterval?) {
        let totalRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        let needingSyncRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        needingSyncRequest.predicate = NSPredicate(format: "needsDetailSync == true")
        
        let lastSyncRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        lastSyncRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ContactEntity.detailsSyncedAt, ascending: false)]
        lastSyncRequest.fetchLimit = 1
        
        do {
            let total = try container.viewContext.count(for: totalRequest)
            let needingSync = try container.viewContext.count(for: needingSyncRequest)
            
            let lastSyncResults = try container.viewContext.fetch(lastSyncRequest)
            let lastSyncAge = lastSyncResults.first?.detailsSyncedAt?.timeIntervalSinceNow.magnitude
            
            return (total: total, needingSync: needingSync, lastSyncAge: lastSyncAge)
        } catch {
            print("❌ Failed to get cache statistics: \(error)")
            return (total: 0, needingSync: 0, lastSyncAge: nil)
        }
    }
    
    func clearAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ContactEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.viewContext.execute(deleteRequest)
            save()
            print("🗑️ Cleared all cached data")
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
    
    func clearDetailCache() {
        let fetchRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        
        do {
            let contacts = try container.viewContext.fetch(fetchRequest)
            for contact in contacts {
                contact.detailsSyncedAt = nil
                contact.needsDetailSync = true
            }
            save()
            print("🔄 Cleared detail cache - all contacts marked for re-sync")
        } catch {
            print("❌ Failed to clear detail cache: \(error)")
        }
    }
}