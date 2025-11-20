import Foundation

/// Protocol defining the Monica API client interface
protocol MonicaAPIClientProtocol {
    // MARK: - Authentication
    func testConnection() async throws
    
    // MARK: - Contacts
    func listContacts(page: Int, perPage: Int, query: String?) async throws -> APIResponse<[Contact]>
    func getContact(id: Int) async throws -> APIResponse<Contact>
    
    // MARK: - Activities
    func listActivities(contactId: Int?, page: Int, perPage: Int) async throws -> APIResponse<[Activity]>
    func getActivity(id: Int) async throws -> Activity
    func getActivities(for contactId: Int, limit: Int) async throws -> APIResponse<[Activity]>
    func createActivity(for contactId: Int, activityTypeId: Int, summary: String?, description: String?, happenedAt: Date?) async throws -> Activity
    func updateActivity(id: Int, activityTypeId: Int?, summary: String?, description: String?, happenedAt: Date?) async throws -> Activity
    func deleteActivity(id: Int) async throws
    
    // MARK: - Notes
    func listNotes(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Note]>
    func getNote(id: Int) async throws -> Note
    func getNotes(for contactId: Int, limit: Int) async throws -> APIResponse<[Note]>
    func createNote(for contactId: Int, note: Note) async throws -> APIResponse<Note>
    func updateNote(_ note: Note) async throws -> APIResponse<Note>
    func deleteNote(id: Int) async throws

    // MARK: - Tasks
    func listTasks(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Task]>
    func getTask(id: Int) async throws -> Task
    func getTasks(for contactId: Int, limit: Int) async throws -> APIResponse<[Task]>
    func updateTask(_ task: Task) async throws -> APIResponse<Task>
    
    // MARK: - Gifts
    func listGifts(contactId: Int, page: Int, perPage: Int) async throws -> APIResponse<[Gift]>
    func getGift(id: Int) async throws -> Gift
    
    // MARK: - Tags
    func listTags() async throws -> APIResponse<[Tag]>
    func getTag(id: Int) async throws -> Tag
}

/// Comprehensive Monica API client implementation
class MonicaAPIClient: MonicaAPIClientProtocol {
    
    private let baseURL: String
    private let apiToken: String
    private let session: URLSession
    private let cacheService: CacheService
    
    init(baseURL: String, apiToken: String, cacheService: CacheService = CacheService()) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/$", with: "")
        self.apiToken = apiToken
        self.cacheService = cacheService
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.defaultTimeout
        config.timeoutIntervalForResource = Constants.API.defaultTimeout * 2
        config.httpAdditionalHeaders = [
            Constants.API.Headers.userAgent: Constants.App.userAgent
        ]
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Private Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: "\(baseURL)/api\(endpoint)") else {
            throw MonicaAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: Constants.API.Headers.authorization)
        request.setValue(Constants.API.ContentTypes.json, forHTTPHeaderField: Constants.API.Headers.accept)
        
        if let body = body {
            request.httpBody = body
            request.setValue(Constants.API.ContentTypes.json, forHTTPHeaderField: Constants.API.Headers.contentType)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MonicaAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard !data.isEmpty else {
                    throw MonicaAPIError.noData
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try multiple date formats
                    let formatters = [
                        ISO8601DateFormatter(),
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'" },
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" },
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd HH:mm:ss" }
                    ]
                    
                    for formatter in formatters {
                        if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ??
                                     (formatter as? DateFormatter)?.date(from: dateString) {
                            return date
                        }
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
                }
                
                do {
                    return try decoder.decode(responseType, from: data)
                } catch let decodingError as DecodingError {
                    throw MonicaAPIError.decodingError(decodingError)
                }
                
            case 401:
                throw MonicaAPIError.unauthorized
            case 403:
                throw MonicaAPIError.forbidden
            case 404:
                throw MonicaAPIError.notFound
            case 429:
                throw MonicaAPIError.rateLimited
            case 400...499:
                let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let message = errorMessage?["message"] as? String ?? "Bad request"
                throw MonicaAPIError.badRequest(message)
            case 500...599:
                throw MonicaAPIError.serverError(httpResponse.statusCode)
            default:
                throw MonicaAPIError.invalidResponse
            }
            
        } catch let error as MonicaAPIError {
            throw error
        } catch {
            throw MonicaAPIError.networkError(error)
        }
    }
    
    // MARK: - Authentication
    
    func testConnection() async throws {
        let _: [String: Any] = try await makeRequest(
            endpoint: Constants.API.Endpoints.me,
            responseType: [String: Any].self
        )
    }
    
    // MARK: - Contacts
    
    func listContacts(page: Int = 1, perPage: Int = Constants.Pagination.defaultPageSize, query: String? = nil) async throws -> APIResponse<[Contact]> {
        var endpoint = "\(Constants.API.Endpoints.contacts)?page=\(page)&limit=\(perPage)"
        
        if let query = query, !query.trimmed.isEmpty {
            endpoint += "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        
        let response: APIResponse<[Contact]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Contact]>.self
        )
        
        // Cache the results
        if query == nil {
            cacheService.cacheContacts(response.data)
        }
        
        return response
    }
    
    func getContact(id: Int) async throws -> APIResponse<Contact> {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.contacts)/\(id)",
            responseType: APIResponse<Contact>.self
        )
    }
    
    // MARK: - Activities
    
    func listActivities(contactId: Int? = nil, page: Int = 1, perPage: Int = Constants.Pagination.defaultPageSize) async throws -> APIResponse<[Activity]> {
        var endpoint = "\(Constants.API.Endpoints.activities)?page=\(page)&limit=\(perPage)"
        
        if let contactId = contactId {
            endpoint += "&contact_id=\(contactId)"
        }
        
        let response: APIResponse<[Activity]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Activity]>.self
        )
        
        // Cache the results for specific contact
        if let contactId = contactId {
            cacheService.cacheActivities(response.data, for: contactId)
        }
        
        return response
    }
    
    func getActivity(id: Int) async throws -> Activity {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.activities)/\(id)",
            responseType: Activity.self
        )
    }
    
    func getActivities(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[Activity]> {
        let endpoint = "\(Constants.API.Endpoints.activities)?contact_id=\(contactId)&limit=\(limit)"
        
        let response: APIResponse<[Activity]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Activity]>.self
        )
        
        cacheService.cacheActivities(response.data, for: contactId)
        return response
    }
    
    func createActivity(for contactId: Int, activityTypeId: Int, summary: String?, description: String?, happenedAt: Date?) async throws -> Activity {
        let payload = ActivityCreatePayload(
            activityTypeId: activityTypeId,
            summary: summary,
            description: description,
            happenedAt: happenedAt,
            contacts: [contactId]
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        
        let responseData = try await makeRequest(endpoint: "/activities", method: "POST", body: data)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(ActivitySingleResponse.self, from: responseData)
        return response.data
    }
    
    func updateActivity(id: Int, activityTypeId: Int?, summary: String?, description: String?, happenedAt: Date?) async throws -> Activity {
        let payload = ActivityUpdatePayload(
            activityTypeId: activityTypeId,
            summary: summary,
            description: description,
            happenedAt: happenedAt
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        
        let responseData = try await makeRequest(endpoint: "/activities/\(id)", method: "PUT", body: data)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(ActivitySingleResponse.self, from: responseData)
        return response.data
    }
    
    func deleteActivity(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/activities/\(id)", method: "DELETE")
    }
    
    // MARK: - Notes
    
    func listNotes(contactId: Int, page: Int = 1, perPage: Int = Constants.Pagination.defaultPageSize) async throws -> APIResponse<[Note]> {
        let endpoint = "\(Constants.API.Endpoints.notes)?contact_id=\(contactId)&page=\(page)&limit=\(perPage)"
        
        let response: APIResponse<[Note]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Note]>.self
        )
        
        cacheService.cacheNotes(response.data, for: contactId)
        return response
    }
    
    func getNote(id: Int) async throws -> Note {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.notes)/\(id)",
            responseType: Note.self
        )
    }
    
    func getNotes(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[Note]> {
        let endpoint = "\(Constants.API.Endpoints.notes)?contact_id=\(contactId)&limit=\(limit)"
        
        let response: APIResponse<[Note]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Note]>.self
        )
        
        cacheService.cacheNotes(response.data, for: contactId)
        return response
    }
    
    func createNote(for contactId: Int, note: Note) async throws -> APIResponse<Note> {
        var request = URLRequest(url: URL(string: "\(baseURL)/\(Constants.API.Endpoints.notes)")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "contact_id": contactId,
            "title": note.title ?? "",
            "body": note.body,
            "is_favorite": note.isFavorite
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return try await makeRequest(
            request: request,
            responseType: APIResponse<Note>.self
        )
    }
    
    func updateNote(_ note: Note) async throws -> APIResponse<Note> {
        var request = URLRequest(url: URL(string: "\(baseURL)/\(Constants.API.Endpoints.notes)/\(note.id)")!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "title": note.title ?? "",
            "body": note.body,
            "is_favorite": note.isFavorite
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return try await makeRequest(
            request: request,
            responseType: APIResponse<Note>.self
        )
    }

    func deleteNote(id: Int) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/\(Constants.API.Endpoints.notes)/\(id)")!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Tasks
    
    func listTasks(contactId: Int, page: Int = 1, perPage: Int = Constants.Pagination.defaultPageSize) async throws -> APIResponse<[Task]> {
        let endpoint = "\(Constants.API.Endpoints.tasks)?contact_id=\(contactId)&page=\(page)&limit=\(perPage)"
        
        let response: APIResponse<[Task]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Task]>.self
        )
        
        cacheService.cacheTasks(response.data, for: contactId)
        return response
    }
    
    func getTask(id: Int) async throws -> Task {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.tasks)/\(id)",
            responseType: Task.self
        )
    }
    
    func getTasks(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[Task]> {
        let endpoint = "\(Constants.API.Endpoints.tasks)?contact_id=\(contactId)&limit=\(limit)"
        
        let response: APIResponse<[Task]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Task]>.self
        )
        
        cacheService.cacheTasks(response.data, for: contactId)
        return response
    }
    
    func updateTask(_ task: Task) async throws -> APIResponse<Task> {
        var request = URLRequest(url: URL(string: "\(baseURL)/\(Constants.API.Endpoints.tasks)/\(task.id)")!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "title": task.title,
            "description": task.description ?? "",
            "is_completed": task.isCompleted,
            "priority": task.priority.rawValue,
            "due_date": task.dueDate?.iso8601String
        ].compactMapValues { $0 }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return try await makeRequest(
            request: request,
            responseType: APIResponse<Task>.self
        )
    }
    
    // MARK: - Gifts
    
    func listGifts(contactId: Int, page: Int = 1, perPage: Int = Constants.Pagination.defaultPageSize) async throws -> APIResponse<[Gift]> {
        let endpoint = "\(Constants.API.Endpoints.gifts)?contact_id=\(contactId)&page=\(page)&limit=\(perPage)"
        
        let response: APIResponse<[Gift]> = try await makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[Gift]>.self
        )
        
        cacheService.cacheGifts(response.data, for: contactId)
        return response
    }
    
    func getGift(id: Int) async throws -> Gift {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.gifts)/\(id)",
            responseType: Gift.self
        )
    }
    
    // MARK: - Tags
    
    func listTags() async throws -> APIResponse<[Tag]> {
        let response: APIResponse<[Tag]> = try await makeRequest(
            endpoint: Constants.API.Endpoints.tags,
            responseType: APIResponse<[Tag]>.self
        )
        
        cacheService.cacheTags(response.data)
        return response
    }
    
    func getTag(id: Int) async throws -> Tag {
        return try await makeRequest(
            endpoint: "\(Constants.API.Endpoints.tags)/\(id)",
            responseType: Tag.self
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func makeRequest<T: Codable>(
        request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MonicaAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard !data.isEmpty else {
                    throw MonicaAPIError.noData
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try multiple date formats
                    let formatters = [
                        ISO8601DateFormatter(),
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'" },
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" },
                        DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd HH:mm:ss" }
                    ]
                    
                    for formatter in formatters {
                        if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ??
                                     (formatter as? DateFormatter)?.date(from: dateString) {
                            return date
                        }
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
                }
                
                do {
                    return try decoder.decode(responseType, from: data)
                } catch let decodingError as DecodingError {
                    throw MonicaAPIError.decodingError(decodingError)
                }
                
            case 401:
                throw MonicaAPIError.unauthorized
            case 403:
                throw MonicaAPIError.forbidden
            case 404:
                throw MonicaAPIError.notFound
            case 429:
                throw MonicaAPIError.rateLimited
            case 400...499:
                throw MonicaAPIError.badRequest
            case 500...599:
                throw MonicaAPIError.serverError
            default:
                throw MonicaAPIError.unknown
            }
            
        } catch let error as MonicaAPIError {
            throw error
        } catch {
            throw MonicaAPIError.networkError(error)
        }
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Helper Extensions
private extension DateFormatter {
    func apply(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self)
        return self
    }
}