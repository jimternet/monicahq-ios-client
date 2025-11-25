import Foundation
import CoreData

extension CallLogEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CallLogEntity> {
        return NSFetchRequest<CallLogEntity>(entityName: "CallLogEntity")
    }

    @NSManaged public var id: Int32
    @NSManaged public var contactId: Int32
    @NSManaged public var calledAt: Date?
    @NSManaged public var duration: Int32
    @NSManaged public var emotionalState: String?
    @NSManaged public var notes: String?
    @NSManaged public var syncStatus: String?
    @NSManaged public var syncError: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastSyncAttempt: Date?
    @NSManaged public var isMarkedDeleted: Bool

}

extension CallLogEntity: Identifiable {

    /// Computed property to get EmotionalState enum from string
    var emotion: EmotionalState? {
        guard let stateString = emotionalState else { return nil }
        return EmotionalState(rawValue: stateString)
    }

    /// Set emotional state from enum
    func setEmotion(_ state: EmotionalState?) {
        self.emotionalState = state?.rawValue
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
