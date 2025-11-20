import Foundation
import SwiftUI

@MainActor
class ContactDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var contact: Contact?
    @Published var activities: [Activity] = []
    @Published var notes: [Note] = []
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var error: MonicaAPIError?
    
    // Pagination support
    @Published var isLoadingMoreActivities = false
    @Published var hasMoreActivities = false
    @Published var activitiesCurrentPage = 1
    @Published var isLoadingMoreNotes = false
    @Published var hasMoreNotes = false
    @Published var notesCurrentPage = 1
    @Published var isLoadingMoreTasks = false
    @Published var hasMoreTasks = false
    @Published var tasksCurrentPage = 1
    
    // MARK: - Dependencies
    private let contactId: Int
    private let apiClient: MonicaAPIClientProtocol
    
    // MARK: - Initialization
    init(contactId: Int, apiClient: MonicaAPIClientProtocol) {
        self.contactId = contactId
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Load contact details and related data
    func loadContact() async {
        isLoading = true
        error = nil
        
        do {
            // Load contact details
            let contactResponse = try await apiClient.getContact(id: contactId)
            contact = contactResponse.data
            
            // Load related data concurrently
            async let activitiesTask = loadActivities()
            async let notesTask = loadNotes()
            async let tasksTask = loadTasks()
            
            // Wait for all related data to load
            let (activitiesResult, notesResult, tasksResult) = await (activitiesTask, notesTask, tasksTask)
            
            // Handle results
            switch activitiesResult {
            case .success(let activities):
                self.activities = activities
            case .failure(let error):
                print("Failed to load activities: \(error.localizedDescription)")
            }
            
            switch notesResult {
            case .success(let notes):
                self.notes = notes
            case .failure(let error):
                print("Failed to load notes: \(error.localizedDescription)")
            }
            
            switch tasksResult {
            case .success(let tasks):
                self.tasks = tasks
            case .failure(let error):
                print("Failed to load tasks: \(error.localizedDescription)")
            }
            
        } catch {
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            } else {
                self.error = MonicaAPIError.networkError(error)
            }
        }
        
        isLoading = false
    }
    
    /// Refresh contact data
    func refresh() async {
        await loadContact()
    }
    
    /// Load more activities for pagination
    func loadMoreActivities() async {
        guard !isLoadingMoreActivities && hasMoreActivities else { return }
        
        isLoadingMoreActivities = true
        
        do {
            let nextPage = activitiesCurrentPage + 1
            let response = try await apiClient.listActivities(contactId: contactId, page: nextPage, perPage: 20)
            
            // Append new activities to existing list
            activities.append(contentsOf: response.data)
            activitiesCurrentPage = nextPage
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreActivities = nextPage < meta.lastPage
            } else {
                hasMoreActivities = response.data.count >= 20
            }
            
        } catch {
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            }
            print("Failed to load more activities: \(error.localizedDescription)")
        }
        
        isLoadingMoreActivities = false
    }
    
    /// Toggle task completion status
    func toggleTaskCompletion(_ task: Task) async {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        do {
            let updatedTask = Task(
                id: task.id,
                title: task.title,
                description: task.description,
                isCompleted: !task.isCompleted,
                priority: task.priority,
                dueDate: task.dueDate,
                completedAt: !task.isCompleted ? Date() : nil,
                createdAt: task.createdAt
            )
            
            // Update locally first for immediate UI feedback
            tasks[taskIndex] = updatedTask
            
            // Then update on server
            _ = try await apiClient.updateTask(updatedTask)
            
        } catch {
            // Revert local change if server update fails
            tasks[taskIndex] = task
            
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            } else {
                self.error = MonicaAPIError.networkError(error)
            }
        }
    }
    
    /// Add a new note for the contact
    func addNote(title: String, body: String) async {
        do {
            let note = Note(
                id: 0, // Will be assigned by server
                title: title,
                body: body,
                isFavorite: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let createdNote = try await apiClient.createNote(for: contactId, note: note)
            notes.insert(createdNote.data, at: 0)
            
        } catch {
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            } else {
                self.error = MonicaAPIError.networkError(error)
            }
        }
    }
    
    /// Mark a note as favorite
    func toggleNoteFavorite(_ note: Note) async {
        guard let noteIndex = notes.firstIndex(where: { $0.id == note.id }) else { return }
        
        do {
            let updatedNote = Note(
                id: note.id,
                title: note.title,
                body: note.body,
                isFavorite: !note.isFavorite,
                createdAt: note.createdAt,
                updatedAt: Date()
            )
            
            // Update locally first
            notes[noteIndex] = updatedNote
            
            // Then update on server
            _ = try await apiClient.updateNote(updatedNote)
            
        } catch {
            // Revert local change if server update fails
            notes[noteIndex] = note
            
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            } else {
                self.error = MonicaAPIError.networkError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadActivities() async -> Result<[Activity], MonicaAPIError> {
        do {
            activitiesCurrentPage = 1
            let response = try await apiClient.listActivities(contactId: contactId, page: 1, perPage: 20)
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreActivities = 1 < meta.lastPage
            } else {
                hasMoreActivities = response.data.count >= 20
            }
            
            return .success(response.data)
        } catch {
            if let apiError = error as? MonicaAPIError {
                return .failure(apiError)
            } else {
                return .failure(MonicaAPIError.networkError(error))
            }
        }
    }
    
    /// Load more notes for pagination
    func loadMoreNotes() async {
        guard !isLoadingMoreNotes && hasMoreNotes else { return }
        
        isLoadingMoreNotes = true
        
        do {
            let nextPage = notesCurrentPage + 1
            let response = try await apiClient.listNotes(contactId: contactId, page: nextPage, perPage: 20)
            
            // Append new notes to existing list
            notes.append(contentsOf: response.data)
            notesCurrentPage = nextPage
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreNotes = nextPage < meta.lastPage
            } else {
                hasMoreNotes = response.data.count >= 20
            }
            
        } catch {
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            }
            print("Failed to load more notes: \(error.localizedDescription)")
        }
        
        isLoadingMoreNotes = false
    }
    
    private func loadNotes() async -> Result<[Note], MonicaAPIError> {
        do {
            notesCurrentPage = 1
            let response = try await apiClient.listNotes(contactId: contactId, page: 1, perPage: 20)
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreNotes = 1 < meta.lastPage
            } else {
                hasMoreNotes = response.data.count >= 20
            }
            
            return .success(response.data)
        } catch {
            if let apiError = error as? MonicaAPIError {
                return .failure(apiError)
            } else {
                return .failure(MonicaAPIError.networkError(error))
            }
        }
    }
    
    /// Load more tasks for pagination
    func loadMoreTasks() async {
        guard !isLoadingMoreTasks && hasMoreTasks else { return }
        
        isLoadingMoreTasks = true
        
        do {
            let nextPage = tasksCurrentPage + 1
            let response = try await apiClient.listTasks(contactId: contactId, page: nextPage, perPage: 20)
            
            // Append new tasks to existing list
            tasks.append(contentsOf: response.data)
            tasksCurrentPage = nextPage
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreTasks = nextPage < meta.lastPage
            } else {
                hasMoreTasks = response.data.count >= 20
            }
            
        } catch {
            if let apiError = error as? MonicaAPIError {
                self.error = apiError
            }
            print("Failed to load more tasks: \(error.localizedDescription)")
        }
        
        isLoadingMoreTasks = false
    }
    
    private func loadTasks() async -> Result<[Task], MonicaAPIError> {
        do {
            tasksCurrentPage = 1
            let response = try await apiClient.listTasks(contactId: contactId, page: 1, perPage: 20)
            
            // Check if there are more pages
            if let meta = response.meta {
                hasMoreTasks = 1 < meta.lastPage
            } else {
                hasMoreTasks = response.data.count >= 20
            }
            
            return .success(response.data)
        } catch {
            if let apiError = error as? MonicaAPIError {
                return .failure(apiError)
            } else {
                return .failure(MonicaAPIError.networkError(error))
            }
        }
    }
}

// MARK: - Computed Properties
extension ContactDetailViewModel {
    
    var hasContent: Bool {
        contact != nil
    }
    
    var pendingTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    var favoriteNotesCount: Int {
        notes.filter { $0.isFavorite }.count
    }
    
    var recentActivitiesCount: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return activities.filter { $0.happenedAt >= oneWeekAgo }.count
    }
}