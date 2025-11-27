import Foundation
import SwiftUI

/// ViewModel for managing call log operations (Backend-only)
/// Based on Monica v4.x Call API (verified)
@MainActor
class CallLogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var callLogs: [CallLog] = []  // Using API model, not Core Data
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false

    // Form state for new/edit call log (Monica v4.x fields only)
    @Published var selectedDate = Date()
    @Published var selectedEmotionIds: Set<Int> = []  // Multiple emotions supported
    @Published var callDescription: String = ""
    @Published var whoInitiated: CallDirection = .me

    // Emotions loaded from API
    @Published var availableEmotions: [Emotion] = []
    @Published var isLoadingEmotions = false

    // MARK: - Dependencies

    private let apiService: CallLogAPIService
    private let contactId: Int

    // MARK: - Initialization

    init(contactId: Int, apiService: CallLogAPIService) {
        self.contactId = contactId
        self.apiService = apiService
    }

    // MARK: - Data Loading

    /// Load call logs for the contact from the API
    func loadCallLogs() async {
        isLoading = true
        errorMessage = nil

        do {
            callLogs = try await apiService.fetchCallLogs(for: contactId)
        } catch {
            errorMessage = "Failed to load call logs: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load call logs: \(error)")
        }

        isLoading = false
    }

    // MARK: - Create/Update Operations

    /// Save a new call log directly to API (Monica v4.x API fields)
    func saveCallLog() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.createCallLog(
                contactId: contactId,
                calledAt: selectedDate,
                content: callDescription.isEmpty ? nil : callDescription,
                contactCalled: whoInitiated.boolValue,
                emotionIds: Array(selectedEmotionIds)
            )

            // Refresh list from server
            await loadCallLogs()

            // Reset form
            resetForm()
        } catch {
            errorMessage = "Failed to save call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to save call log: \(error)")
        }

        isLoading = false
    }

    /// Update an existing call log directly via API (Monica v4.x API fields)
    func updateCallLog(_ callLog: CallLog) async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.updateCallLog(
                id: callLog.id,
                content: callDescription.isEmpty ? nil : callDescription,
                contactCalled: whoInitiated.boolValue,
                emotionIds: Array(selectedEmotionIds)
            )

            // Refresh list from server
            await loadCallLogs()
        } catch {
            errorMessage = "Failed to update call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to update call log: \(error)")
        }

        isLoading = false
    }

    // MARK: - Delete Operations

    /// Delete a call log directly via API
    func deleteCallLog(_ callLog: CallLog) async {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteCallLog(id: callLog.id)

            // Refresh list from server
            await loadCallLogs()
        } catch {
            errorMessage = "Failed to delete call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to delete call log: \(error)")
        }

        isLoading = false
    }

    // MARK: - Form Management

    /// Load call log data into form for editing
    func loadForEditing(_ callLog: CallLog) {
        selectedDate = callLog.calledAt

        // Extract emotion IDs from the emotions array
        if let emotions = callLog.emotions {
            selectedEmotionIds = Set(emotions.map { $0.id })
        } else {
            selectedEmotionIds = []
        }

        callDescription = callLog.content ?? ""
        whoInitiated = CallDirection(contactCalled: callLog.contactCalled)
    }

    /// Reset form to initial state
    func resetForm() {
        selectedDate = Date()
        selectedEmotionIds = []
        callDescription = ""
        whoInitiated = .me
    }

    /// Validate form inputs
    private func validateForm() -> Bool {
        // Date is always valid (can't be nil)
        // Notes are optional and don't need validation
        // Emotions are optional
        // Direction has a default value

        return true
    }

    // MARK: - Statistics

    /// Get call log statistics
    func getStatistics() -> (total: Int, withDetails: Int) {
        let withDetails = callLogs.filter { callLog in
            !(callLog.emotions?.isEmpty ?? true) || !(callLog.content?.isEmpty ?? true)
        }.count

        return (total: callLogs.count, withDetails: withDetails)
    }

    // MARK: - Emotion Loading

    /// Load available emotions from API
    func loadEmotions() async {
        // TODO: Implement EmotionService to fetch from /api/emotions
        // For now, use empty list (will be implemented in next step)
        isLoadingEmotions = true

        // Placeholder: In production, fetch from EmotionService
        availableEmotions = []

        isLoadingEmotions = false
    }

    // MARK: - Computed Properties

    /// Check if form is valid and has changes
    var canSave: Bool {
        // Always allow saving - even just timestamp is valid
        return true
    }

    /// Format date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }

        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: date)
        }
    }
}
