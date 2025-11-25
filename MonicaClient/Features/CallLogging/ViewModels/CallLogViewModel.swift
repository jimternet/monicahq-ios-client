import Foundation
import SwiftUI
import CoreData

/// ViewModel for managing call log operations
@MainActor
class CallLogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var callLogs: [CallLogEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false

    // Form state for new/edit call log
    @Published var selectedDate = Date()
    @Published var duration: String = ""
    @Published var selectedEmotion: EmotionalState?
    @Published var notes: String = ""

    // MARK: - Dependencies

    private let storage: CallLogStorage
    private let contactId: Int

    // MARK: - Initialization

    init(contactId: Int, storage: CallLogStorage) {
        self.contactId = contactId
        self.storage = storage
    }

    // MARK: - Data Loading

    /// Load call logs for the contact
    func loadCallLogs() {
        isLoading = true

        // Fetch from local storage
        callLogs = storage.fetchCallLogs(for: contactId)

        isLoading = false
        print("📞 Loaded \(callLogs.count) call logs for contact \(contactId)")
    }

    // MARK: - Create/Update Operations

    /// Save a new call log
    func saveCallLog() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let durationInt = duration.isEmpty ? nil : Int(duration)

            _ = try storage.saveCallLog(
                contactId: contactId,
                calledAt: selectedDate,
                duration: durationInt,
                emotionalState: selectedEmotion,
                notes: notes.isEmpty ? nil : notes
            )

            // Refresh list
            loadCallLogs()

            // Reset form
            resetForm()

            print("✅ Call log saved successfully")
        } catch {
            errorMessage = "Failed to save call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to save call log: \(error)")
        }

        isLoading = false
    }

    /// Update an existing call log
    func updateCallLog(_ entity: CallLogEntity) async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let durationInt = duration.isEmpty ? nil : Int(duration)

            try storage.updateCallLog(
                entity,
                duration: durationInt,
                emotionalState: selectedEmotion,
                notes: notes.isEmpty ? nil : notes
            )

            // Refresh list
            loadCallLogs()

            print("✅ Call log updated successfully")
        } catch {
            errorMessage = "Failed to update call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to update call log: \(error)")
        }

        isLoading = false
    }

    // MARK: - Delete Operations

    /// Delete a call log
    func deleteCallLog(_ entity: CallLogEntity) async {
        isLoading = true
        errorMessage = nil

        do {
            try storage.deleteCallLog(entity)

            // Refresh list
            loadCallLogs()

            print("✅ Call log deleted successfully")
        } catch {
            errorMessage = "Failed to delete call log: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to delete call log: \(error)")
        }

        isLoading = false
    }

    // MARK: - Form Management

    /// Load call log data into form for editing
    func loadForEditing(_ entity: CallLogEntity) {
        if let calledAt = entity.calledAt {
            selectedDate = calledAt
        }

        if entity.duration > 0 {
            duration = String(entity.duration)
        } else {
            duration = ""
        }

        selectedEmotion = entity.emotion
        notes = entity.notes ?? ""
    }

    /// Reset form to initial state
    func resetForm() {
        selectedDate = Date()
        duration = ""
        selectedEmotion = nil
        notes = ""
    }

    /// Validate form inputs
    private func validateForm() -> Bool {
        // Date is always valid (can't be nil)

        // Duration is optional, but if provided must be a valid positive number
        if !duration.isEmpty {
            guard let durationInt = Int(duration), durationInt > 0 else {
                errorMessage = "Duration must be a positive number"
                showingError = true
                return false
            }
        }

        // Notes are optional and don't need validation

        return true
    }

    // MARK: - Statistics

    /// Get call log statistics
    func getStatistics() -> (total: Int, withDetails: Int, pending: Int) {
        let stats = storage.getStatistics()
        let withDetails = callLogs.filter { entity in
            (entity.duration > 0) || (entity.emotion != nil) || !(entity.notes?.isEmpty ?? true)
        }.count

        return (total: stats.total, withDetails: withDetails, pending: stats.pending)
    }

    // MARK: - Computed Properties

    /// Check if form is valid and has changes
    var canSave: Bool {
        // Always allow saving - even just timestamp is valid
        return true
    }

    /// Format duration for display
    func formatDuration(_ minutes: Int32) -> String {
        if minutes == 0 {
            return "Not recorded"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
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
