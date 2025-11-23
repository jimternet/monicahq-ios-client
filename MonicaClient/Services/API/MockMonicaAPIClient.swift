import Foundation

/// Mock implementation of MonicaAPIClient for previews and testing
class MockMonicaAPIClient: MonicaAPIClientProtocol {
    
    // MARK: - Authentication
    func testConnection() async throws {
        // Mock successful connection
    }
    
    // MARK: - Contacts
    func listContacts(page: Int, perPage: Int, query: String?) async throws -> APIResponse<[Contact]> {
        let mockContacts = [
            Contact(
                id: 1,
                firstName: "John",
                lastName: "Doe",
                nickname: "Johnny",
                email: "john.doe@example.com",
                phone: "+1 555-123-4567",
                birthdate: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
                address: "123 Main St, Anytown, ST 12345",
                company: "Tech Corp",
                jobTitle: "Software Engineer",
                notes: "Great friend from college",
                relationships: [],
                avatarURL: nil,
                description: "Great friend from college",
                contactFields: [
                    ContactField(
                        id: 1,
                        contactId: 1,
                        data: "john.doe@example.com",
                        contactFieldType: .email,
                        label: "Personal",
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    ContactField(
                        id: 2,
                        contactId: 1,
                        data: "+1 555-123-4567",
                        contactFieldType: .phone,
                        label: "Mobile",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        return APIResponse(
            data: mockContacts,
            meta: APIResponse.Meta(
                currentPage: page,
                totalPages: 1,
                perPage: perPage,
                total: mockContacts.count
            )
        )
    }
    
    func getContact(id: Int) async throws -> APIResponse<Contact> {
        let mockContact = Contact(
            id: id,
            firstName: "John",
            lastName: "Doe",
            nickname: "Johnny",
            email: "john.doe@example.com",
            phone: "+1 555-123-4567",
            birthdate: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
            address: "123 Main St, Anytown, ST 12345",
            company: "Tech Corp",
            jobTitle: "Software Engineer",
            notes: "Great friend from college",
            relationships: [],
            avatarURL: nil,
            description: "Great friend from college",
            contactFields: [
                ContactField(
                    id: 1,
                    contactId: id,
                    data: "john.doe@example.com",
                    contactFieldType: .email,
                    label: "Personal",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                ContactField(
                    id: 2,
                    contactId: id,
                    data: "+1 555-123-4567",
                    contactFieldType: .phone,
                    label: "Mobile",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                ContactField(
                    id: 3,
                    contactId: id,
                    data: "123 Main St, Anytown, ST 12345",
                    contactFieldType: .address,
                    label: "Home",
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return APIResponse(data: mockContact, meta: nil)
    }
    
    // MARK: - Activities
    func listActivities(contactId: Int?, page: Int, perPage: Int) async throws -> APIResponse<[Activity]> {
        return try await getActivities(for: contactId ?? 1, limit: perPage)
    }
    
    func getActivity(id: Int) async throws -> Activity {
        return Activity(
            id: id,
            summary: "Mock Activity",
            description: "This is a mock activity for testing",
            happenedAt: Date(),
            activityType: .meeting,
            participants: [],
            emotions: []
        )
    }
    
    func getActivities(for contactId: Int, limit: Int) async throws -> APIResponse<[Activity]> {
        let mockActivities = [
            Activity(
                id: 1,
                summary: "Phone call about project",
                description: "Discussed upcoming deadlines and milestones for the new feature release.",
                happenedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                activityType: .call,
                participants: [
                    Activity.Participant(id: 1, name: "John Doe")
                ],
                emotions: []
            ),
            Activity(
                id: 2,
                summary: "Coffee meeting",
                description: "Casual catch-up over coffee downtown.",
                happenedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                activityType: .meeting,
                participants: [
                    Activity.Participant(id: 1, name: "John Doe")
                ],
                emotions: []
            )
        ]
        
        return APIResponse(
            data: Array(mockActivities.prefix(limit)),
            meta: APIResponse.Meta(
                currentPage: 1,
                totalPages: 1,
                perPage: limit,
                total: mockActivities.count
            )
        )
    }
    
    // MARK: - Notes
    func listNotes(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Note]> {
        return try await getNotes(for: contactId, limit: perPage)
    }
    
    func getNote(id: Int) async throws -> Note {
        return Note(
            id: id,
            title: "Mock Note",
            body: "This is a mock note for testing",
            isFavorite: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func getNotes(for contactId: Int, limit: Int) async throws -> APIResponse<[Note]> {
        let mockNotes = [
            Note(
                id: 1,
                title: "Important Meeting Notes",
                body: "Discussed the quarterly goals and upcoming project deadlines. Need to follow up on the budget approval by next week.",
                isFavorite: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            Note(
                id: 2,
                title: "Personal Reminder",
                body: "Remember to send birthday wishes next month. Also, they mentioned wanting to visit the new restaurant downtown.",
                isFavorite: false,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            )
        ]
        
        return APIResponse(
            data: Array(mockNotes.prefix(limit)),
            meta: APIResponse.Meta(
                currentPage: 1,
                totalPages: 1,
                perPage: limit,
                total: mockNotes.count
            )
        )
    }
    
    func createNote(for contactId: Int, note: Note) async throws -> APIResponse<Note> {
        let createdNote = Note(
            id: Int.random(in: 1000...9999),
            title: note.title,
            body: note.body,
            isFavorite: note.isFavorite,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return APIResponse(data: createdNote, meta: nil)
    }
    
    func updateNote(_ note: Note) async throws -> APIResponse<Note> {
        let updatedNote = Note(
            id: note.id,
            title: note.title,
            body: note.body,
            isFavorite: note.isFavorite,
            createdAt: note.createdAt,
            updatedAt: Date()
        )
        
        return APIResponse(data: updatedNote, meta: nil)
    }
    
    // MARK: - Tasks
    func listTasks(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Task]> {
        return try await getTasks(for: contactId, limit: perPage)
    }
    
    func getTask(id: Int) async throws -> Task {
        return Task(
            id: id,
            title: "Mock Task",
            description: "This is a mock task for testing",
            isCompleted: false,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            completedAt: nil,
            createdAt: Date()
        )
    }
    
    func getTasks(for contactId: Int, limit: Int) async throws -> APIResponse<[Task]> {
        let mockTasks = [
            Task(
                id: 1,
                title: "Follow up on project proposal",
                description: "Send the updated proposal with revised timeline and budget estimates.",
                isCompleted: false,
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                completedAt: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            Task(
                id: 2,
                title: "Schedule coffee meeting",
                description: "Arrange a casual catch-up meeting for next week.",
                isCompleted: false,
                priority: .medium,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                completedAt: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            Task(
                id: 3,
                title: "Send birthday card",
                description: "Remember to send a birthday card before the 15th.",
                isCompleted: true,
                priority: .low,
                dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
            )
        ]
        
        return APIResponse(
            data: Array(mockTasks.prefix(limit)),
            meta: APIResponse.Meta(
                currentPage: 1,
                totalPages: 1,
                perPage: limit,
                total: mockTasks.count
            )
        )
    }
    
    func updateTask(_ task: Task) async throws -> APIResponse<Task> {
        return APIResponse(data: task, meta: nil)
    }
    
    // MARK: - Gifts
    func listGifts(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Gift]> {
        return APIResponse(
            data: [],
            meta: APIResponse.Meta(
                currentPage: page,
                totalPages: 1,
                perPage: perPage,
                total: 0
            )
        )
    }
    
    func getGift(id: Int) async throws -> Gift {
        return Gift(
            id: id,
            name: "Mock Gift",
            comment: "This is a mock gift",
            url: nil,
            value: "0",
            isIdea: false,
            hasBeenOffered: false,
            createdAt: Date()
        )
    }
    
    // MARK: - Tags
    func listTags() async throws -> APIResponse<[Tag]> {
        return APIResponse(
            data: [],
            meta: APIResponse.Meta(
                currentPage: 1,
                totalPages: 1,
                perPage: 10,
                total: 0
            )
        )
    }
    
    func getTag(id: Int) async throws -> Tag {
        return Tag(
            id: id,
            name: "Mock Tag",
            nameSlug: "mock-tag"
        )
    }
}