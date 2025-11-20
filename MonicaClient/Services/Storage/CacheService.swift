import Foundation

/// In-memory caching service for contact data and API responses
class CacheService: ObservableObject {
    
    private var contactsCache: [Contact] = []
    private var activitiesCache: [Int: [Activity]] = [:]
    private var notesCache: [Int: [Note]] = [:]
    private var tasksCache: [Int: [Task]] = [:]
    private var giftsCache: [Int: [Gift]] = [:]
    private var tagsCache: [Tag] = []
    
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    private let queue = DispatchQueue(label: "com.monicahq.cache", attributes: .concurrent)
    
    // MARK: - Contacts Cache
    
    func cacheContacts(_ contacts: [Contact]) {
        queue.async(flags: .barrier) {
            self.contactsCache = contacts
            self.setCacheTimestamp(for: "contacts")
        }
    }
    
    func getCachedContacts() -> [Contact]? {
        return queue.sync {
            guard isCacheValid(for: "contacts") else { return nil }
            return contactsCache
        }
    }
    
    func addOrUpdateContact(_ contact: Contact) {
        queue.async(flags: .barrier) {
            if let index = self.contactsCache.firstIndex(where: { $0.id == contact.id }) {
                self.contactsCache[index] = contact
            } else {
                self.contactsCache.append(contact)
            }
            self.setCacheTimestamp(for: "contacts")
        }
    }
    
    func removeContact(withId id: Int) {
        queue.async(flags: .barrier) {
            self.contactsCache.removeAll { $0.id == id }
            self.setCacheTimestamp(for: "contacts")
        }
    }
    
    // MARK: - Activities Cache
    
    func cacheActivities(_ activities: [Activity], for contactId: Int) {
        queue.async(flags: .barrier) {
            self.activitiesCache[contactId] = activities
            self.setCacheTimestamp(for: "activities_\(contactId)")
        }
    }
    
    func getCachedActivities(for contactId: Int) -> [Activity]? {
        return queue.sync {
            guard isCacheValid(for: "activities_\(contactId)") else { return nil }
            return activitiesCache[contactId]
        }
    }
    
    // MARK: - Notes Cache
    
    func cacheNotes(_ notes: [Note], for contactId: Int) {
        queue.async(flags: .barrier) {
            self.notesCache[contactId] = notes
            self.setCacheTimestamp(for: "notes_\(contactId)")
        }
    }
    
    func getCachedNotes(for contactId: Int) -> [Note]? {
        return queue.sync {
            guard isCacheValid(for: "notes_\(contactId)") else { return nil }
            return notesCache[contactId]
        }
    }
    
    // MARK: - Tasks Cache
    
    func cacheTasks(_ tasks: [Task], for contactId: Int) {
        queue.async(flags: .barrier) {
            self.tasksCache[contactId] = tasks
            self.setCacheTimestamp(for: "tasks_\(contactId)")
        }
    }
    
    func getCachedTasks(for contactId: Int) -> [Task]? {
        return queue.sync {
            guard isCacheValid(for: "tasks_\(contactId)") else { return nil }
            return tasksCache[contactId]
        }
    }
    
    // MARK: - Gifts Cache
    
    func cacheGifts(_ gifts: [Gift], for contactId: Int) {
        queue.async(flags: .barrier) {
            self.giftsCache[contactId] = gifts
            self.setCacheTimestamp(for: "gifts_\(contactId)")
        }
    }
    
    func getCachedGifts(for contactId: Int) -> [Gift]? {
        return queue.sync {
            guard isCacheValid(for: "gifts_\(contactId)") else { return nil }
            return giftsCache[contactId]
        }
    }
    
    // MARK: - Tags Cache
    
    func cacheTags(_ tags: [Tag]) {
        queue.async(flags: .barrier) {
            self.tagsCache = tags
            self.setCacheTimestamp(for: "tags")
        }
    }
    
    func getCachedTags() -> [Tag]? {
        return queue.sync {
            guard isCacheValid(for: "tags") else { return nil }
            return tagsCache
        }
    }
    
    // MARK: - Cache Management
    
    private func setCacheTimestamp(for key: String) {
        cacheTimestamps[key] = Date()
    }
    
    private func isCacheValid(for key: String) -> Bool {
        guard let timestamp = cacheTimestamps[key] else { return false }
        return Date().timeIntervalSince(timestamp) < cacheExpirationTime
    }
    
    func invalidateCache(for key: String) {
        queue.async(flags: .barrier) {
            self.cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    func clearAllCache() {
        queue.async(flags: .barrier) {
            self.contactsCache.removeAll()
            self.activitiesCache.removeAll()
            self.notesCache.removeAll()
            self.tasksCache.removeAll()
            self.giftsCache.removeAll()
            self.tagsCache.removeAll()
            self.cacheTimestamps.removeAll()
        }
    }
    
    func getCacheSize() -> Int {
        return queue.sync {
            let contactsSize = contactsCache.count
            let activitiesSize = activitiesCache.values.reduce(0) { $0 + $1.count }
            let notesSize = notesCache.values.reduce(0) { $0 + $1.count }
            let tasksSize = tasksCache.values.reduce(0) { $0 + $1.count }
            let giftsSize = giftsCache.values.reduce(0) { $0 + $1.count }
            let tagsSize = tagsCache.count
            
            return contactsSize + activitiesSize + notesSize + tasksSize + giftsSize + tagsSize
        }
    }
    
    func getCacheStatistics() -> [String: Any] {
        return queue.sync {
            return [
                "contacts": contactsCache.count,
                "activities": activitiesCache.mapValues { $0.count },
                "notes": notesCache.mapValues { $0.count },
                "tasks": tasksCache.mapValues { $0.count },
                "gifts": giftsCache.mapValues { $0.count },
                "tags": tagsCache.count,
                "totalSize": getCacheSize(),
                "cacheTimestamps": cacheTimestamps
            ]
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Alias for clearAllCache for backwards compatibility
    func clearCache() {
        clearAllCache()
    }
}