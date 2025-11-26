import Foundation
import CoreData

/// Manages Core Data storage for call logs with offline queue support
/// Based on Monica v4.x Call API (verified)
@MainActor
class CallLogStorage: ObservableObject {
    private let dataController: DataController

    init(dataController: DataController) {
        self.dataController = dataController
    }

    // MARK: - Create

    /// Save a new call log to local storage (offline-first)
    /// Based on Monica v4.x API: called_at, content, contact_called, emotions
    func saveCallLog(
        contactId: Int,
        calledAt: Date,
        content: String? = nil,
        contactCalled: CallDirection = .me,
        emotionIds: [Int] = []
    ) throws -> CallLogEntity {
        let context = dataController.container.viewContext

        let entity = CallLogEntity(context: context)
        // Use negative timestamp for temporary local ID (will be replaced by server ID on sync)
        entity.id = Int32(-Int(Date().timeIntervalSince1970))
        entity.contactId = Int32(contactId)
        entity.calledAt = calledAt
        entity.content = content
        entity.setCallDirection(contactCalled)
        entity.setEmotions(emotionIds)
        entity.syncStatus = "pending"
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.isMarkedDeleted = false

        try context.save()
        print("✅ Saved call log locally (contactId=\(contactId), direction=\(contactCalled.displayName), emotions=\(emotionIds.count), pending sync)")

        return entity
    }

    // MARK: - Read

    /// Fetch all call logs for a contact, sorted by date (newest first)
    func fetchCallLogs(for contactId: Int) -> [CallLogEntity] {
        let request: NSFetchRequest<CallLogEntity> = CallLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "contactId == %d AND isMarkedDeleted == false", contactId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntity.calledAt, ascending: false)]

        do {
            return try dataController.container.viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch call logs: \(error)")
            return []
        }
    }

    /// Fetch call logs pending sync
    func fetchPendingSync() -> [CallLogEntity] {
        let request: NSFetchRequest<CallLogEntity> = CallLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CallLogEntity.createdAt, ascending: true)]

        do {
            let results = try dataController.container.viewContext.fetch(request)
            print("📋 Found \(results.count) call logs pending sync")
            return results
        } catch {
            print("❌ Failed to fetch pending call logs: \(error)")
            return []
        }
    }

    // MARK: - Update

    /// Update an existing call log
    /// Based on Monica v4.x API fields
    func updateCallLog(
        _ entity: CallLogEntity,
        content: String? = nil,
        contactCalled: CallDirection? = nil,
        emotionIds: [Int]? = nil
    ) throws {
        if let content = content {
            entity.content = content
        }
        if let contactCalled = contactCalled {
            entity.setCallDirection(contactCalled)
        }
        if let emotionIds = emotionIds {
            entity.setEmotions(emotionIds)
        }

        entity.updatedAt = Date()

        // If already synced, mark for re-sync
        if entity.syncStatus == "synced" {
            entity.syncStatus = "pending"
        }

        try dataController.container.viewContext.save()
        print("✅ Updated call log \(entity.id)")
    }

    /// Mark call log as successfully synced
    func markSynced(_ entity: CallLogEntity, serverId: Int) throws {
        entity.id = Int32(serverId)
        entity.syncStatus = "synced"
        entity.syncError = nil
        entity.lastSyncAttempt = Date()

        try dataController.container.viewContext.save()
        print("✅ Marked call log as synced (serverId=\(serverId))")
    }

    /// Mark call log sync as failed
    func markSyncFailed(_ entity: CallLogEntity, error: String) throws {
        entity.syncStatus = "failed"
        entity.syncError = error
        entity.lastSyncAttempt = Date()

        try dataController.container.viewContext.save()
        print("❌ Marked call log sync as failed: \(error)")
    }

    // MARK: - Delete

    /// Soft delete (mark for deletion, will be removed after sync)
    func deleteCallLog(_ entity: CallLogEntity) throws {
        entity.isMarkedDeleted = true
        entity.updatedAt = Date()

        if entity.syncStatus == "synced" {
            // Already synced, needs sync to delete on server
            entity.syncStatus = "pending"
        }

        try dataController.container.viewContext.save()
        print("✅ Soft-deleted call log \(entity.id)")
    }

    /// Hard delete (remove from local storage)
    func hardDeleteCallLog(_ entity: CallLogEntity) throws {
        dataController.container.viewContext.delete(entity)
        try dataController.container.viewContext.save()
        print("🗑️ Hard-deleted call log \(entity.id)")
    }

    // MARK: - Statistics

    /// Get statistics about call log storage
    func getStatistics() -> (total: Int, pending: Int, failed: Int) {
        let totalRequest: NSFetchRequest<CallLogEntity> = CallLogEntity.fetchRequest()
        totalRequest.predicate = NSPredicate(format: "isMarkedDeleted == false")

        let pendingRequest: NSFetchRequest<CallLogEntity> = CallLogEntity.fetchRequest()
        pendingRequest.predicate = NSPredicate(format: "syncStatus == %@", "pending")

        let failedRequest: NSFetchRequest<CallLogEntity> = CallLogEntity.fetchRequest()
        failedRequest.predicate = NSPredicate(format: "syncStatus == %@", "failed")

        do {
            let total = try dataController.container.viewContext.count(for: totalRequest)
            let pending = try dataController.container.viewContext.count(for: pendingRequest)
            let failed = try dataController.container.viewContext.count(for: failedRequest)

            return (total: total, pending: pending, failed: failed)
        } catch {
            print("❌ Failed to get call log statistics: \(error)")
            return (total: 0, pending: 0, failed: 0)
        }
    }
}
