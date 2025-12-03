import Foundation
import SwiftUI

/// ViewModel for creating and editing day entries (mood ratings)
@MainActor
class DayEntryViewModel: ObservableObject {
    // MARK: - Form State
    @Published var selectedMood: MoodRating?
    @Published var comment: String = ""
    @Published var selectedDate: Date = Date()

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaved = false

    // MARK: - Edit Mode
    @Published var editingEntry: DayEntry?
    var isEditMode: Bool { editingEntry != nil }

    // MARK: - Dependencies
    private let apiClient: MonicaAPIClient

    // MARK: - Validation
    var isValid: Bool {
        selectedMood != nil && !isDateInFuture
    }

    var isDateInFuture: Bool {
        Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: Date())
    }

    var validationError: String? {
        if selectedMood == nil {
            return "Please select a mood rating"
        }
        if isDateInFuture {
            return "Cannot rate a future date"
        }
        return nil
    }

    // MARK: - Init
    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Load Entry for Editing
    func loadEntry(_ entry: DayEntry) {
        editingEntry = entry
        selectedMood = MoodRating(rate: entry.rate)
        comment = entry.comment ?? ""
        selectedDate = entry.date
    }

    // MARK: - Reset Form
    func resetForm() {
        selectedMood = nil
        comment = ""
        selectedDate = Date()
        editingEntry = nil
        errorMessage = nil
        isSaved = false
    }

    // MARK: - Save Day Entry
    func saveDayEntry() async -> DayEntry? {
        guard isValid else {
            errorMessage = validationError
            return nil
        }

        guard let mood = selectedMood else {
            errorMessage = "Please select a mood rating"
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let savedEntry: DayEntry

            if let existingEntry = editingEntry {
                // Update existing entry
                savedEntry = try await updateDayEntry(id: existingEntry.id, rate: mood.rawValue, comment: comment.isEmpty ? nil : comment)
                print("✅ Updated day entry \(existingEntry.id)")
            } else {
                // Create new entry
                savedEntry = try await createDayEntry(date: selectedDate, rate: mood.rawValue, comment: comment.isEmpty ? nil : comment)
                print("✅ Created new day entry for \(selectedDate)")
            }

            isSaved = true
            isLoading = false
            return savedEntry
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("❌ Failed to save day entry: \(error)")
            isLoading = false
            return nil
        }
    }

    // MARK: - API Methods
    private func createDayEntry(date: Date, rate: Int, comment: String?) async throws -> DayEntry {
        return try await apiClient.createDayEntry(date: date, rate: rate, comment: comment)
    }

    private func updateDayEntry(id: Int, rate: Int, comment: String?) async throws -> DayEntry {
        return try await apiClient.updateDayEntry(id: id, rate: rate, comment: comment)
    }

    func deleteDayEntry(id: Int) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await apiClient.deleteDayEntry(id: id)
            print("✅ Deleted day entry \(id)")
            isLoading = false
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            print("❌ Failed to delete day entry: \(error)")
            isLoading = false
            throw error
        }
    }
}
