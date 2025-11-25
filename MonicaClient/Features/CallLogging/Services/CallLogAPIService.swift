import Foundation

/// API service for call logs (backed by Monica Activities API)
/// NOTE: This is a placeholder implementation. Full API integration will be completed
/// when MonicaAPIClient exposes generic request methods or we add call-specific endpoints.
@MainActor
class CallLogAPIService {
    private let apiClient: MonicaAPIClient
    private let activityTypeId: Int = 13 // "phone_call" activity type in Monica

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Placeholder Methods

    /// Create a call log on the server via Activities API
    /// TODO: Implement using MonicaAPIClient once activity creation methods are added
    func createCallLog(
        contactId: Int,
        calledAt: Date,
        duration: Int?,
        emotionalState: EmotionalState?,
        notes: String?
    ) async throws -> CallLog {
        // For MVP, we'll focus on local storage first
        // API sync will be handled by a background sync service
        throw APIError.invalidResponse
    }

    /// Fetch all call logs for a contact from the server
    /// TODO: Implement using MonicaAPIClient.fetchActivities with filtering
    func fetchCallLogs(for contactId: Int) async throws -> [CallLog] {
        // For MVP, we'll use local storage
        return []
    }

    /// Update a call log on the server
    /// TODO: Implement using MonicaAPIClient once activity update methods are added
    func updateCallLog(
        id: Int,
        duration: Int?,
        emotionalState: EmotionalState?,
        notes: String?
    ) async throws -> CallLog {
        throw APIError.invalidResponse
    }

    /// Delete a call log from the server
    /// TODO: Implement using MonicaAPIClient once activity delete methods are added
    func deleteCallLog(id: Int) async throws {
        // For MVP, local deletion only
    }

    // MARK: - Helper Methods

    /// Parse Activity JSON into CallLog model
    private func parseCallLogFromActivity(_ activity: Activity, contactId: Int) throws -> CallLog {
        // Parse metadata from description field
        var duration: Int?
        var emotionalState: EmotionalState?
        var notes: String?

        if let description = activity.description,
           let data = description.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let metadata = try? decoder.decode(CallMetadata.self, from: data) {
                duration = metadata.duration
                if let emotion = metadata.emotion {
                    emotionalState = EmotionalState(rawValue: emotion)
                }
                notes = metadata.notes
            }
        }

        // Use the provided contactId or extract from activity
        let finalContactId = activity.safeContacts.first?.id ?? contactId

        guard let happenedAt = activity.happenedAt else {
            throw APIError.invalidResponse
        }

        return CallLog(
            id: activity.id,
            contactId: finalContactId,
            calledAt: happenedAt,
            duration: duration,
            emotionalState: emotionalState,
            notes: notes,
            createdAt: activity.createdAt,
            updatedAt: activity.updatedAt
        )
    }
}
