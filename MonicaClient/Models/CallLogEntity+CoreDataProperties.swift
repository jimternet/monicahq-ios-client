import Foundation
import CoreData

extension CallLogEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CallLogEntity> {
        return NSFetchRequest<CallLogEntity>(entityName: "CallLogEntity")
    }

    @NSManaged public var id: Int32
    @NSManaged public var contactId: Int32
    @NSManaged public var calledAt: Date?
    @NSManaged public var content: String?            // Call notes/description (matches Monica v4.x 'content' field)
    @NSManaged public var contactCalled: Bool         // Direction: true = they called me, false = I called them
    @NSManaged public var emotionsJSON: String?       // JSON array of emotion IDs for sync
    @NSManaged public var syncStatus: String?
    @NSManaged public var syncError: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastSyncAttempt: Date?
    @NSManaged public var isMarkedDeleted: Bool

}

extension CallLogEntity: Identifiable {

    /// Computed property to get CallDirection enum from boolean
    var callDirection: CallDirection {
        return CallDirection(contactCalled: contactCalled)
    }

    /// Set call direction from enum
    func setCallDirection(_ direction: CallDirection) {
        self.contactCalled = direction.boolValue
    }

    /// Parse emotions from JSON string
    var emotions: [Int] {
        guard let json = emotionsJSON,
              let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return array
    }

    /// Set emotions from array
    func setEmotions(_ emotionIds: [Int]) {
        guard let data = try? JSONEncoder().encode(emotionIds),
              let json = String(data: data, encoding: .utf8) else {
            emotionsJSON = nil
            return
        }
        emotionsJSON = json
    }

    /// Check if sync is needed
    var needsSync: Bool {
        return syncStatus == "pending" || syncStatus == "failed"
    }

    /// Check if sync is in progress
    var isSyncing: Bool {
        return syncStatus == "syncing"
    }

    /// Check if successfully synced
    var isSynced: Bool {
        return syncStatus == "synced"
    }
}
