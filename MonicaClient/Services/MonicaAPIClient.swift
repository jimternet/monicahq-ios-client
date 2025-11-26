import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid API token or unauthorized access"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .decodingError:
            return "Failed to decode server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class MonicaAPIClient {
    private let baseURL: String
    private let apiToken: String
    private let session: URLSession
    
    init(baseURL: String, apiToken: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/$", with: "")
        self.apiToken = apiToken
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/api\(endpoint)") else {
            print("❌ Invalid URL: \(baseURL)/api\(endpoint)")
            throw APIError.invalidURL
        }

        print("🔗 Making request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("📡 Response status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                print("❌ Unauthorized - check your API token")
                throw APIError.unauthorized
            case 404:
                print("❌ 404 Not Found - check your API URL and endpoint")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                throw APIError.serverError(404)
            case 400...499:
                print("❌ Client error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                throw APIError.serverError(httpResponse.statusCode)
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.invalidResponse
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func testConnection() async throws {
        // Try current API first
        do {
            _ = try await makeRequest(endpoint: "/me")
        } catch {
            // If that fails, try v1 endpoint
            print("⚠️ /me failed, trying /account endpoint...")
            _ = try await makeRequest(endpoint: "/account")
        }
    }
    
    func fetchContacts(page: Int = 1, limit: Int = 100) async throws -> ContactsResponse {
        // Request avatar information by including the 'with' parameter
        // This may or may not work depending on Monica API version, but it's worth trying
        let data = try await makeRequest(endpoint: "/contacts?page=\(page)&limit=\(limit)&with=information")

        print("📥 Fetching contacts with avatar information - page: \(page), limit: \(limit)")
        
        // Print raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw response preview: \(String(jsonString.prefix(500)))")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(ContactsResponse.self, from: data)
            print("✅ Decoded \(response.data.count) contacts")
            return response
        } catch {
            print("❌ Decoding error: \(error)")
            
            // Try to decode as a simple structure to see what we got
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Response structure: \(json.keys)")
            }
            
            throw APIError.decodingError
        }
    }
    
    func fetchAllContacts() async throws -> [Contact] {
        var allContacts: [Contact] = []
        var currentPage = 1
        var hasMorePages = true
        
        print("🔄 Starting to fetch all contacts (basic data only)...")
        
        while hasMorePages {
            let response = try await fetchContacts(page: currentPage, limit: 100)
            allContacts.append(contentsOf: response.data)
            
            print("📊 Page \(currentPage): Got \(response.data.count) contacts (Total so far: \(allContacts.count))")
            
            if let meta = response.meta {
                hasMorePages = currentPage < meta.lastPage
                currentPage += 1
            } else {
                hasMorePages = false
            }
        }
        
        print("✅ Finished fetching basic contact data. Total contacts: \(allContacts.count)")
        return allContacts
    }

    func searchContacts(query: String, limit: Int = 50) async throws -> ContactsResponse {
        // URL encode the search query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.invalidResponse
        }

        let data = try await makeRequest(endpoint: "/contacts?query=\(encodedQuery)&limit=\(limit)")

        print("🔍 Searching contacts with query: '\(query)'")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ContactsResponse.self, from: data)
            print("✅ Found \(response.data.count) contacts matching '\(query)'")
            return response
        } catch {
            print("❌ Failed to decode search results: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    func fetchSingleContact(id: Int) async throws -> Contact {
        let data = try await makeRequest(endpoint: "/contacts/\(id)")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as ContactResponse first (in case it's wrapped)
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let contactData = json["data"] as? [String: Any] {
                let contactJson = try JSONSerialization.data(withJSONObject: contactData)
                return try decoder.decode(Contact.self, from: contactJson)
            } else {
                // Try direct decode
                return try decoder.decode(Contact.self, from: data)
            }
        } catch {
            print("❌ Failed to decode single contact \(id): \(error)")
            throw APIError.decodingError
        }
    }
    
    func fetchSingleContactWithRelationships(id: Int) async throws -> (contact: Contact, relationships: [Relationship]) {
        // Fetch contact and relationships in parallel for better performance
        async let contactData = fetchSingleContact(id: id)
        async let relationshipsData = fetchContactRelationships(contactId: id)
        
        do {
            let contact = try await contactData
            let relationships = try await relationshipsData
            
            print("✅ Fetched contact \(id) with \(relationships.count) relationships")
            return (contact: contact, relationships: relationships)
        } catch {
            print("❌ Failed to fetch contact \(id) with relationships: \(error)")
            // If relationships fail, still return the contact with empty relationships
            let contact = try await contactData
            return (contact: contact, relationships: [])
        }
    }
    
    func createContact(_ contact: Contact) async throws -> Contact {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(contact)
        
        let data = try await makeRequest(endpoint: "/contacts", method: "POST", body: body)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Contact.self, from: data)
    }
    
    func updateContact(_ contact: Contact) async throws -> Contact {
        // Create update payload with only basic contact fields
        // Note: email, phone, address are now managed via ContactFields API
        let updatePayload = ContactUpdatePayload(
            firstName: contact.firstName?.isEmpty == true ? nil : contact.firstName,
            lastName: contact.lastName?.isEmpty == true ? nil : contact.lastName,
            nickname: contact.nickname?.isEmpty == true ? nil : contact.nickname,
            genderId: nil, // We don't currently manage gender IDs
            birthdateDay: contact.birthdate.map { Calendar.current.component(.day, from: $0) },
            birthdateMonth: contact.birthdate.map { Calendar.current.component(.month, from: $0) },
            birthdateYear: contact.birthdate.map { Calendar.current.component(.year, from: $0) },
            birthdateIsAgeBased: false, // We use exact dates, not age-based
            isBirthdateKnown: contact.birthdate != nil,
            birthdateAge: nil, // We don't use age-based birthdate
            isPartial: false, // Full contacts, not partial
            isDeceased: contact.isDead,
            deceasedDate: nil, // We don't currently track deceased dates
            deceasedDateIsAgeBased: false,
            deceasedDateIsYearUnknown: false,
            deceasedDateAge: nil,
            isDeceasedDateKnown: false,
            company: contact.company?.isEmpty == true ? nil : contact.company,
            jobTitle: contact.jobTitle?.isEmpty == true ? nil : contact.jobTitle,
            notes: contact.notes?.isEmpty == true ? nil : contact.notes,
            description: contact.description?.isEmpty == true ? nil : contact.description,
            gender: contact.gender?.isEmpty == true ? nil : contact.gender,
            isStarred: contact.isStarred,
            foodPreferences: nil,
            howYouMetGeneralInformation: nil,
            firstMetDate: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil
        )
        return try await updateContact(id: contact.id, payload: updatePayload)
    }

    // New method that accepts a payload directly
    func updateContact(id: Int, payload: ContactUpdatePayload) async throws -> Contact {

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Make it easier to read in logs
        let body = try encoder.encode(payload)

        // Debug logging to see what we're sending
        if let jsonString = String(data: body, encoding: .utf8) {
            print("📤 Sending update payload: \(jsonString)")

            // Also log individual field values for debugging
            print("📊 Field values:")
            print("   - isBirthdateKnown: \(payload.isBirthdateKnown)")
            print("   - isDeceased: \(payload.isDeceased)")
            print("   - isDeceasedDateKnown: \(payload.isDeceasedDateKnown)")
            print("   - birthdateDay: \(payload.birthdateDay?.description ?? "nil")")
            print("   - birthdateMonth: \(payload.birthdateMonth?.description ?? "nil")")
            print("   - birthdateYear: \(payload.birthdateYear?.description ?? "nil")")
            print("   - firstName: \(payload.firstName ?? "nil")")
            print("   - lastName: \(payload.lastName ?? "nil")")
        }

        let data = try await makeRequest(endpoint: "/contacts/\(id)", method: "PUT", body: body)
        
        // Debug: Log the raw response to see what we're getting back
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw API response: \(responseString.prefix(500))")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as a wrapped response first
            if let responseString = String(data: data, encoding: .utf8), 
               responseString.contains("\"data\":") {
                print("📦 Detected wrapped response, decoding ContactApiResponse")
                let wrappedResponse = try decoder.decode(ContactApiResponse.self, from: data)
                return wrappedResponse.data
            } else {
                // Fallback to direct Contact decoding
                return try decoder.decode(Contact.self, from: data)
            }
        } catch {
            print("❌ Failed to decode response as Contact: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Full response for debugging: \(responseString)")
            }
            throw APIError.decodingError
        }
    }
    
    func deleteContact(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/contacts/\(id)", method: "DELETE")
    }
    
    func toggleContactStar(contactId: Int, isStarred: Bool) async throws -> Contact {
        let payload = ContactStarUpdatePayload(isStarred: isStarred)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(payload)

        let endpoint = "/contacts/\(contactId)"
        let responseData = try await makeRequest(endpoint: endpoint, method: "PUT", body: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(ContactSingleResponse.self, from: responseData)
        return response.data
    }

    // Update work information via /contacts/{id}/work endpoint
    func updateContactWork(contactId: Int, jobTitle: String?, company: String?) async throws {
        struct WorkUpdatePayload: Codable {
            let job: String?
            let company: String?
        }

        let payload = WorkUpdatePayload(job: jobTitle, company: company)
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)

        print("📤 Updating work info for contact \(contactId): job=\(jobTitle ?? "nil"), company=\(company ?? "nil")")
        _ = try await makeRequest(endpoint: "/contacts/\(contactId)/work", method: "PUT", body: body)
        print("✅ Work info updated successfully")
    }

    // MARK: - Contact Fields CRUD Operations
    
    /// Get all contact fields for a specific contact
    func getContactFields(contactId: Int) async throws -> [ContactField] {
        let data = try await makeRequest(endpoint: "/contacts/\(contactId)/contactfields", method: "GET")
        
        // First, let's see what the raw response looks like
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw contact fields response: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as wrapped response first
            let response = try decoder.decode(ContactFieldsResponse.self, from: data)
            print("✅ Successfully decoded as ContactFieldsResponse with \(response.data.count) fields")
            return response.data
        } catch {
            print("❌ Failed to decode as ContactFieldsResponse: \(error)")
            
            // Try to decode directly as array
            do {
                let directArray = try decoder.decode([ContactField].self, from: data)
                print("✅ Successfully decoded as direct array with \(directArray.count) fields")
                return directArray
            } catch {
                print("❌ Failed to decode as direct array: \(error)")
                
                // If it's an empty response, return empty array
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("📊 Response structure: \(json.keys.sorted())")
                    if let dataArray = json["data"] as? [[String: Any]] {
                        print("📊 Found data array with \(dataArray.count) items")
                    }
                } else if data.isEmpty {
                    print("📄 Empty response, returning empty array")
                    return []
                }
                
                throw APIError.decodingError
            }
        }
    }
    
    /// Create a new contact field
    func createContactField(contactId: Int, type: ContactField.ContactFieldType, data: String, label: String? = nil) async throws -> ContactField {
        let payload = ContactFieldCreatePayload(
            contactId: contactId,
            contactFieldTypeId: type.typeId,
            data: data,
            label: label
        )
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)
        
        print("📤 Creating contact field: \(type.label) = \(data)")
        
        let responseData = try await makeRequest(endpoint: "/contacts/\(contactId)/contactfields", method: "POST", body: body)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(ContactFieldApiResponse.self, from: responseData)
            return response.data
        } catch {
            print("❌ Failed to decode created contact field: \(error)")
            throw APIError.decodingError
        }
    }
    
    /// Update an existing contact field
    func updateContactField(contactId: Int, fieldId: Int, type: ContactField.ContactFieldType, data: String, label: String? = nil) async throws -> ContactField {
        let payload = ContactFieldUpdatePayload(
            contactFieldTypeId: type.typeId,
            data: data,
            label: label
        )
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)
        
        print("📤 Updating contact field \(fieldId): \(type.label) = \(data)")
        
        let responseData = try await makeRequest(endpoint: "/contacts/\(contactId)/contactfields/\(fieldId)", method: "PUT", body: body)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(ContactFieldApiResponse.self, from: responseData)
            return response.data
        } catch {
            print("❌ Failed to decode updated contact field: \(error)")
            throw APIError.decodingError
        }
    }
    
    /// Delete a contact field
    func deleteContactField(contactId: Int, fieldId: Int) async throws {
        print("🗑️ Deleting contact field \(fieldId)")
        _ = try await makeRequest(endpoint: "/contacts/\(contactId)/contactfields/\(fieldId)", method: "DELETE")
    }
    
    func fetchContactRelationships(contactId: Int) async throws -> [Relationship] {
        let data = try await makeRequest(endpoint: "/contacts/\(contactId)/relationships")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RelationshipsResponse.self, from: data)
            print("✅ Decoded \(response.data.count) relationships for contact \(contactId)")
            return response.data
        } catch {
            print("❌ Failed to decode relationships for contact \(contactId): \(error)")
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    func fetchRelationshipTypes() async throws -> [RelationshipType] {
        var allTypes: [RelationshipType] = []
        var currentPage = 1
        var hasMorePages = true

        while hasMorePages {
            let data = try await makeRequest(endpoint: "/relationshiptypes?page=\(currentPage)&limit=100")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let response = try decoder.decode(RelationshipTypesResponse.self, from: data)
                allTypes.append(contentsOf: response.data)
                print("✅ Fetched page \(currentPage): \(response.data.count) relationship types")

                // Check if there are more pages
                hasMorePages = response.data.count >= 100
                currentPage += 1
            } catch {
                print("❌ Failed to decode relationship types: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(jsonString.prefix(500))")
                }
                throw APIError.decodingError
            }
        }

        print("✅ Fetched total of \(allTypes.count) relationship types across all pages")
        return allTypes
    }

    func fetchRelationshipTypeGroups() async throws -> [RelationshipTypeGroup] {
        let data = try await makeRequest(endpoint: "/relationshiptypegroups")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RelationshipTypeGroupsResponse.self, from: data)
            print("✅ Fetched \(response.data.count) relationship type groups")
            return response.data
        } catch {
            print("❌ Failed to decode relationship type groups: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    func createRelationship(contactIs: Int, ofContact: Int, relationshipTypeId: Int) async throws -> Relationship {
        let payload = RelationshipCreatePayload(
            contactIs: contactIs,
            relationshipTypeId: relationshipTypeId,
            ofContact: ofContact
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(payload)

        print("📤 Creating relationship: contact \(contactIs) is type \(relationshipTypeId) of contact \(ofContact)")
        let data = try await makeRequest(endpoint: "/relationships", method: "POST", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RelationshipSingleResponse.self, from: data)
            print("✅ Created relationship \(response.data.id)")
            return response.data
        } catch {
            print("❌ Failed to decode created relationship: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    func updateRelationship(relationshipId: Int, relationshipTypeId: Int) async throws -> Relationship {
        let payload = RelationshipUpdatePayload(relationshipTypeId: relationshipTypeId)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(payload)

        print("📤 Updating relationship \(relationshipId) to type \(relationshipTypeId)")
        let data = try await makeRequest(endpoint: "/relationships/\(relationshipId)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RelationshipSingleResponse.self, from: data)
            print("✅ Updated relationship \(response.data.id)")
            return response.data
        } catch {
            print("❌ Failed to decode updated relationship: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    func deleteRelationship(relationshipId: Int) async throws {
        print("🗑️ Deleting relationship \(relationshipId)")
        _ = try await makeRequest(endpoint: "/relationships/\(relationshipId)", method: "DELETE")
        print("✅ Deleted relationship \(relationshipId)")
    }

    func fetchNotesRaw() async throws -> Data {
        return try await makeRequest(endpoint: "/notes")
    }
    
    func fetchContactNotesRaw(contactId: Int) async throws -> Data {
        return try await makeRequest(endpoint: "/contacts/\(contactId)/notes")
    }
    
    func fetchGenders() async throws -> [Gender] {
        let data = try await makeRequest(endpoint: "/genders")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let response = try decoder.decode(GendersResponse.self, from: data)
            print("✅ Fetched \(response.data.count) genders")
            return response.data
        } catch {
            print("❌ Failed to decode genders: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchTagsRaw() async throws -> Data {
        return try await makeRequest(endpoint: "/tags")
    }

    // MARK: - Journal Methods

    func fetchJournalEntries(page: Int = 1, limit: Int = 50) async throws -> JournalResponse {
        let data = try await makeRequest(endpoint: "/journal?page=\(page)&limit=\(limit)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let response = try decoder.decode(JournalResponse.self, from: data)
            print("✅ Fetched \(response.data.count) journal entries")
            return response
        } catch {
            print("❌ Failed to decode journal entries: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchSingleJournalEntry(id: Int) async throws -> JournalEntry {
        let data = try await makeRequest(endpoint: "/journal/\(id)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try wrapped response first
        if let responseString = String(data: data, encoding: .utf8), responseString.contains("\"data\":") {
            struct JournalEntryApiResponse: Codable {
                let data: JournalEntry
            }
            do {
                let wrappedResponse = try decoder.decode(JournalEntryApiResponse.self, from: data)
                print("✅ Fetched journal entry \(id)")
                return wrappedResponse.data
            } catch {
                print("❌ Failed to decode wrapped journal entry: \(error)")
            }
        }

        // Try direct response
        do {
            let entry = try decoder.decode(JournalEntry.self, from: data)
            print("✅ Fetched journal entry \(id)")
            return entry
        } catch {
            print("❌ Failed to decode journal entry: \(error)")
            throw APIError.decodingError
        }
    }

    func createJournalEntry(title: String, post: String) async throws -> JournalEntry {
        let payload = JournalEntryPayload(title: title, post: post)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(payload)

        let data = try await makeRequest(endpoint: "/journal", method: "POST", body: jsonData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try wrapped response first
        if let responseString = String(data: data, encoding: .utf8), responseString.contains("\"data\":") {
            struct JournalEntryApiResponse: Codable {
                let data: JournalEntry
            }
            do {
                let wrappedResponse = try decoder.decode(JournalEntryApiResponse.self, from: data)
                print("✅ Created journal entry")
                return wrappedResponse.data
            } catch {
                print("❌ Failed to decode wrapped journal entry: \(error)")
            }
        }

        // Try direct response
        do {
            let entry = try decoder.decode(JournalEntry.self, from: data)
            print("✅ Created journal entry")
            return entry
        } catch {
            print("❌ Failed to decode journal entry: \(error)")
            throw APIError.decodingError
        }
    }

    func updateJournalEntry(id: Int, title: String, post: String) async throws -> JournalEntry {
        let payload = JournalEntryPayload(title: title, post: post)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(payload)

        let data = try await makeRequest(endpoint: "/journal/\(id)", method: "PUT", body: jsonData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try wrapped response first
        if let responseString = String(data: data, encoding: .utf8), responseString.contains("\"data\":") {
            struct JournalEntryApiResponse: Codable {
                let data: JournalEntry
            }
            do {
                let wrappedResponse = try decoder.decode(JournalEntryApiResponse.self, from: data)
                print("✅ Updated journal entry \(id)")
                return wrappedResponse.data
            } catch {
                print("❌ Failed to decode wrapped journal entry: \(error)")
            }
        }

        // Try direct response
        do {
            let entry = try decoder.decode(JournalEntry.self, from: data)
            print("✅ Updated journal entry \(id)")
            return entry
        } catch {
            print("❌ Failed to decode journal entry: \(error)")
            throw APIError.decodingError
        }
    }

    func deleteJournalEntry(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/journal/\(id)", method: "DELETE")
        print("✅ Deleted journal entry \(id)")
    }

    func fetchTags() async throws -> [Tag] {
        let data = try await makeRequest(endpoint: "/tags")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let response = try decoder.decode(TagsResponse.self, from: data)
            print("✅ Fetched \(response.data.count) tags")
            return response.data
        } catch {
            print("❌ Failed to decode tags: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchContactTags(contactId: Int) async throws -> [Tag] {
        let data = try await makeRequest(endpoint: "/contacts/\(contactId)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let response = try decoder.decode(ContactSingleResponse.self, from: data)
            let tags = response.data.tags ?? []
            print("✅ Fetched \(tags.count) tags for contact \(contactId)")
            return tags
        } catch {
            print("❌ Failed to decode contact tags: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchActivitiesRaw() async throws -> Data {
        return try await makeRequest(endpoint: "/activities")
    }

    func fetchActivities(page: Int = 1, limit: Int = 100) async throws -> APIResponse<[Activity]> {
        let endpoint = "/activities?page=\(page)&limit=\(limit)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try multiple date formats
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            // Try various formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd"
            ]

            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        do {
            let response = try decoder.decode(APIResponse<[Activity]>.self, from: data)
            print("✅ Fetched \(response.data.count) activities")
            return response
        } catch {
            print("❌ Failed to decode activities: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchContactActivitiesRaw(contactId: Int) async throws -> Data {
        // Try contact-specific endpoint first, fall back to all activities
        return try await makeRequest(endpoint: "/contacts/\(contactId)/activities")
    }
    
    func fetchTasksRaw() async throws -> Data {
        return try await makeRequest(endpoint: "/tasks")
    }
    
    func fetchContactTasksRaw(contactId: Int) async throws -> Data {
        // Try contact-specific endpoint first, fall back to all tasks
        do {
            return try await makeRequest(endpoint: "/contacts/\(contactId)/tasks")
        } catch {
            print("⚠️ Contact-specific tasks endpoint failed, trying all tasks...")
            return try await makeRequest(endpoint: "/tasks")
        }
    }

    // MARK: - Notes CRUD

    func getNotes(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[Note]> {
        let endpoint = "/contacts/\(contactId)/notes?limit=\(limit)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Note]>.self, from: data)
    }

    func createNote(for contactId: Int, note: Note) async throws -> Note {
        let body = [
            "contact_id": contactId,
            "body": note.body,
            "is_favorited": note.isFavorited ? 1 : 0
        ] as [String: Any]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/notes", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Monica API returns a direct note object (not wrapped)
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            // If that fails, try wrapped formats
            if let wrappedResponse = try? decoder.decode(APIResponse<Note>.self, from: data) {
                return wrappedResponse.data
            }

            if let singleResponse = try? decoder.decode(NoteSingleResponse.self, from: data) {
                return singleResponse.data
            }

            // Re-throw the original error with response data for debugging
            print("Failed to decode note. Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw error
        }
    }

    func updateNote(_ note: Note) async throws -> Note {
        let body = [
            "contact_id": note.contactId,
            "body": note.body,
            "is_favorited": note.isFavorited ? 1 : 0
        ] as [String: Any]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/notes/\(note.id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Monica API returns a direct note object (not wrapped)
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            // If that fails, try wrapped formats
            if let wrappedResponse = try? decoder.decode(APIResponse<Note>.self, from: data) {
                return wrappedResponse.data
            }

            if let singleResponse = try? decoder.decode(NoteSingleResponse.self, from: data) {
                return singleResponse.data
            }

            // Re-throw the original error with response data for debugging
            print("Failed to decode note. Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw error
        }
    }

    func deleteNote(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/notes/\(id)", method: "DELETE")
    }

    // MARK: - Phone Calls CRUD

    func getPhoneCalls(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[PhoneCall]> {
        let endpoint = "/calls?contact_id=\(contactId)&limit=\(limit)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[PhoneCall]>.self, from: data)
    }

    func createPhoneCall(for contactId: Int, calledAt: Date, content: String?) async throws -> APIResponse<PhoneCall> {
        let formatter = ISO8601DateFormatter()
        let body = [
            "contact_id": contactId,
            "called_at": formatter.string(from: calledAt),
            "content": content ?? ""
        ] as [String: Any]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/calls", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<PhoneCall>.self, from: data)
    }

    func deletePhoneCall(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/calls/\(id)", method: "DELETE")
    }

    // MARK: - Conversations CRUD

    func getConversations(for contactId: Int, limit: Int = 10) async throws -> APIResponse<[Conversation]> {
        let endpoint = "/conversations?contact_id=\(contactId)&limit=\(limit)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Conversation]>.self, from: data)
    }

    func createConversation(for contactId: Int, happenedAt: Date, content: String?) async throws -> APIResponse<Conversation> {
        let formatter = ISO8601DateFormatter()
        let body = [
            "contact_id": contactId,
            "happened_at": formatter.string(from: happenedAt),
            "content": content ?? ""
        ] as [String: Any]

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/conversations", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Conversation>.self, from: data)
    }

    func deleteConversation(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/conversations/\(id)", method: "DELETE")
    }

    // MARK: - Reminders CRUD

    func getReminders(for contactId: Int) async throws -> APIResponse<[Reminder]> {
        let endpoint = "/reminders?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Reminder]>.self, from: data)
    }

    func createReminder(for contactId: Int, title: String, description: String?, frequency: String?, nextExpectedDate: Date?) async throws -> APIResponse<Reminder> {
        var body: [String: Any] = [
            "contact_id": contactId,
            "title": title
        ]

        if let description = description {
            body["description"] = description
        }
        if let frequency = frequency {
            body["frequency"] = frequency
        }
        if let nextExpectedDate = nextExpectedDate {
            let formatter = ISO8601DateFormatter()
            body["next_expected_date"] = formatter.string(from: nextExpectedDate)
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/reminders", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Reminder>.self, from: data)
    }

    func updateReminder(id: Int, title: String?, description: String?, frequency: String?, nextExpectedDate: Date?) async throws -> APIResponse<Reminder> {
        var body: [String: Any] = [:]

        if let title = title {
            body["title"] = title
        }
        if let description = description {
            body["description"] = description
        }
        if let frequency = frequency {
            body["frequency"] = frequency
        }
        if let nextExpectedDate = nextExpectedDate {
            let formatter = ISO8601DateFormatter()
            body["next_expected_date"] = formatter.string(from: nextExpectedDate)
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/reminders/\(id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Reminder>.self, from: data)
    }

    // MARK: - Tasks CRUD

    func getTasks(for contactId: Int) async throws -> APIResponse<[MonicaTask]> {
        let endpoint = "/tasks?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[MonicaTask]>.self, from: data)
    }

    func createTask(for contactId: Int, title: String, description: String?, isCompleted: Bool) async throws -> APIResponse<MonicaTask> {
        var body: [String: Any] = [
            "contact_id": contactId,
            "title": title,
            "completed": isCompleted
        ]

        if let description = description {
            body["description"] = description
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/tasks", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<MonicaTask>.self, from: data)
    }

    func updateTask(id: Int, title: String?, description: String?, isCompleted: Bool?) async throws -> APIResponse<MonicaTask> {
        var body: [String: Any] = [:]

        if let title = title {
            body["title"] = title
        }
        if let description = description {
            body["description"] = description
        }
        if let isCompleted = isCompleted {
            body["completed"] = isCompleted
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/tasks/\(id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<MonicaTask>.self, from: data)
    }

    func deleteTask(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/tasks/\(id)", method: "DELETE")
    }

    // MARK: - Gifts CRUD

    func getGifts(for contactId: Int) async throws -> APIResponse<[Gift]> {
        let endpoint = "/gifts?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Gift]>.self, from: data)
    }

    func createGift(for contactId: Int, name: String, comment: String?, isAnIdea: Bool, hasBeenOffered: Bool, url: String?, value: Double?) async throws -> APIResponse<Gift> {
        // Determine status based on flags
        let status: String
        if isAnIdea {
            status = "idea"
        } else if hasBeenOffered {
            status = "offered"
        } else {
            status = "received"
        }

        var body: [String: Any] = [
            "contact_id": contactId,
            "name": name,
            "status": status
        ]

        if let comment = comment {
            body["comment"] = comment
        }
        if let url = url {
            body["url"] = url
        }
        if let value = value {
            body["value"] = value
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/gifts", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Gift>.self, from: data)
    }

    func updateGift(id: Int, name: String?, comment: String?, isAnIdea: Bool?, hasBeenOffered: Bool?, url: String?, value: Double?) async throws -> APIResponse<Gift> {
        var body: [String: Any] = [:]

        if let name = name {
            body["name"] = name
        }
        if let comment = comment {
            body["comment"] = comment
        }
        // Convert boolean flags to status field
        if let isAnIdea = isAnIdea, let hasBeenOffered = hasBeenOffered {
            let status: String
            if isAnIdea {
                status = "idea"
            } else if hasBeenOffered {
                status = "offered"
            } else {
                status = "received"
            }
            body["status"] = status
        }
        if let url = url {
            body["url"] = url
        }
        if let value = value {
            body["value"] = value
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/gifts/\(id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Gift>.self, from: data)
    }

    func deleteGift(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/gifts/\(id)", method: "DELETE")
    }

    // MARK: - Debts CRUD

    func getDebts(for contactId: Int) async throws -> APIResponse<[Debt]> {
        let endpoint = "/debts?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Debt]>.self, from: data)
    }

    func createDebt(for contactId: Int, inDebt: Bool, status: String, amount: Double, reason: String?) async throws -> APIResponse<Debt> {
        var body: [String: Any] = [
            "contact_id": contactId,
            "in_debt": inDebt,
            "status": status,
            "amount": amount
        ]

        if let reason = reason {
            body["reason"] = reason
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/debts", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Debt>.self, from: data)
    }

    func updateDebt(id: Int, status: String?, amount: Double?, reason: String?) async throws -> APIResponse<Debt> {
        var body: [String: Any] = [:]

        if let status = status {
            body["status"] = status
        }
        if let amount = amount {
            body["amount"] = amount
        }
        if let reason = reason {
            body["reason"] = reason
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/debts/\(id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Debt>.self, from: data)
    }

    func deleteDebt(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/debts/\(id)", method: "DELETE")
    }

    // MARK: - Addresses CRUD

    func getAddresses(for contactId: Int) async throws -> APIResponse<[Address]> {
        let endpoint = "/addresses?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Address]>.self, from: data)
    }

    func createAddress(for contactId: Int, name: String?, street: String?, city: String?, province: String?, postalCode: String?, countryId: Int?) async throws -> APIResponse<Address> {
        var body: [String: Any] = [
            "contact_id": contactId
        ]

        if let name = name { body["name"] = name }
        if let street = street { body["street"] = street }
        if let city = city { body["city"] = city }
        if let province = province { body["province"] = province }
        if let postalCode = postalCode { body["postal_code"] = postalCode }
        if let countryId = countryId { body["country_id"] = countryId }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/addresses", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Address>.self, from: data)
    }

    func updateAddress(id: Int, name: String?, street: String?, city: String?, province: String?, postalCode: String?, countryId: Int?) async throws -> APIResponse<Address> {
        var body: [String: Any] = [:]

        if let name = name { body["name"] = name }
        if let street = street { body["street"] = street }
        if let city = city { body["city"] = city }
        if let province = province { body["province"] = province }
        if let postalCode = postalCode { body["postal_code"] = postalCode }
        if let countryId = countryId { body["country_id"] = countryId }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/addresses/\(id)", method: "PUT", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<Address>.self, from: data)
    }

    func deleteAddress(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/addresses/\(id)", method: "DELETE")
    }

    // MARK: - Life Events CRUD

    func getLifeEvents(for contactId: Int) async throws -> APIResponse<[LifeEvent]> {
        let endpoint = "/lifeevents?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[LifeEvent]>.self, from: data)
    }

    func createLifeEvent(for contactId: Int, lifeEventTypeId: Int, name: String, happenedAt: Date, note: String?) async throws -> APIResponse<LifeEvent> {
        let formatter = ISO8601DateFormatter()
        var body: [String: Any] = [
            "contact_id": contactId,
            "life_event_type_id": lifeEventTypeId,
            "name": name,
            "happened_at": formatter.string(from: happenedAt)
        ]

        if let note = note {
            body["note"] = note
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let data = try await makeRequest(endpoint: "/lifeevents", method: "POST", body: bodyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<LifeEvent>.self, from: data)
    }

    func deleteLifeEvent(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/lifeevents/\(id)", method: "DELETE")
    }

    // MARK: - Photos

    func getPhotos(for contactId: Int) async throws -> APIResponse<[Photo]> {
        let endpoint = "/photos?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Photo]>.self, from: data)
    }

    func deletePhoto(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/photos/\(id)", method: "DELETE")
    }

    // MARK: - Documents

    func getDocuments(for contactId: Int) async throws -> APIResponse<[Document]> {
        let endpoint = "/documents?contact_id=\(contactId)"
        let data = try await makeRequest(endpoint: endpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(APIResponse<[Document]>.self, from: data)
    }

    func deleteDocument(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/documents/\(id)", method: "DELETE")
    }

    // MARK: - Reminders

    func fetchReminders(page: Int = 1, limit: Int = 100) async throws -> RemindersResponse {
        let data = try await makeRequest(endpoint: "/reminders?page=\(page)&limit=\(limit)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RemindersResponse.self, from: data)
            print("✅ Fetched \(response.data.count) reminders")
            return response
        } catch {
            print("❌ Failed to decode reminders: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchUpcomingReminders(month: Int) async throws -> RemindersResponse {
        let data = try await makeRequest(endpoint: "/reminders/upcoming/\(month)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RemindersResponse.self, from: data)
            print("✅ Fetched \(response.data.count) upcoming reminders for month \(month)")
            return response
        } catch {
            print("❌ Failed to decode upcoming reminders: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchReminder(id: Int) async throws -> Reminder {
        let data = try await makeRequest(endpoint: "/reminders/\(id)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ReminderSingleResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode reminder: \(error)")
            throw APIError.decodingError
        }
    }

    func fetchReminders(for contactId: Int) async throws -> RemindersResponse {
        let data = try await makeRequest(endpoint: "/contacts/\(contactId)/reminders")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(RemindersResponse.self, from: data)
            print("✅ Fetched \(response.data.count) reminders for contact \(contactId)")
            return response
        } catch {
            print("❌ Failed to decode contact reminders: \(error)")
            throw APIError.decodingError
        }
    }

    func createReminder(contactId: Int, title: String, initialDate: Date, frequencyType: String, frequencyNumber: Int? = nil, description: String? = nil) async throws -> Reminder {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: initialDate)

        let payload = ReminderCreatePayload(
            contactId: contactId,
            initialDate: dateString,
            frequencyType: frequencyType,
            frequencyNumber: frequencyNumber,
            title: title,
            description: description
        )

        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)

        let data = try await makeRequest(endpoint: "/reminders", method: "POST", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ReminderSingleResponse.self, from: data)
            print("✅ Created reminder: \(response.data.title)")
            return response.data
        } catch {
            print("❌ Failed to decode created reminder: \(error)")
            throw APIError.decodingError
        }
    }

    func updateReminder(id: Int, title: String? = nil, initialDate: Date? = nil, frequencyType: String? = nil, frequencyNumber: Int? = nil, description: String? = nil) async throws -> Reminder {
        var dateString: String?
        if let date = initialDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateString = dateFormatter.string(from: date)
        }

        let payload = ReminderUpdatePayload(
            initialDate: dateString,
            frequencyType: frequencyType,
            frequencyNumber: frequencyNumber,
            title: title,
            description: description
        )

        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)

        let data = try await makeRequest(endpoint: "/reminders/\(id)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(ReminderSingleResponse.self, from: data)
            print("✅ Updated reminder: \(response.data.title)")
            return response.data
        } catch {
            print("❌ Failed to decode updated reminder: \(error)")
            throw APIError.decodingError
        }
    }

    func deleteReminder(id: Int) async throws {
        _ = try await makeRequest(endpoint: "/reminders/\(id)", method: "DELETE")
        print("✅ Deleted reminder \(id)")
    }

    // MARK: - Address Methods

    /// Fetch all addresses for a contact
    func fetchAddresses(contactId: Int) async throws -> [Address] {
        let data = try await makeRequest(endpoint: "/contacts/\(contactId)/addresses")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(AddressListResponse.self, from: data)
            print("✅ Fetched \(response.data.count) addresses for contact \(contactId)")
            return response.data
        } catch {
            print("❌ Address decoding error: \(error)")
            throw APIError.decodingError
        }
    }

    /// Create a new address for a contact
    func createAddress(contactId: Int, request: AddressCreateRequest) async throws -> Address {
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        // Monica API uses POST /api/addresses with contact_id in body
        let data = try await makeRequest(endpoint: "/addresses", method: "POST", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(AddressResponse.self, from: data)
            print("✅ Created address for contact \(contactId)")
            return response.data
        } catch {
            print("❌ Address creation decoding error: \(error)")
            throw APIError.decodingError
        }
    }

    /// Update an existing address
    func updateAddress(addressId: Int, request: AddressUpdateRequest) async throws -> Address {
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        let data = try await makeRequest(endpoint: "/addresses/\(addressId)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(AddressResponse.self, from: data)
            print("✅ Updated address \(addressId)")
            return response.data
        } catch {
            print("❌ Address update decoding error: \(error)")
            throw APIError.decodingError
        }
    }

    /// Delete an address
    func deleteAddress(addressId: Int) async throws {
        _ = try await makeRequest(endpoint: "/addresses/\(addressId)", method: "DELETE")
        print("✅ Deleted address \(addressId)")
    }

    // MARK: - Country Methods

    /// Fetch all available countries
    func fetchCountries() async throws -> [Country] {
        let data = try await makeRequest(endpoint: "/countries")

        let decoder = JSONDecoder()

        // Try standard array format first
        do {
            let response = try decoder.decode(CountryListResponse.self, from: data)
            print("✅ Fetched \(response.data.count) countries")
            return response.data
        } catch {
            print("⚠️ Standard countries format failed, trying dictionary format...")
        }

        // Monica API sometimes returns countries as a dictionary keyed by ID
        // e.g., { "data": { "1": { "id": 1, "name": "...", ... }, "2": { ... } } }
        do {
            struct CountryDictResponse: Codable {
                let data: [String: Country]
            }
            let response = try decoder.decode(CountryDictResponse.self, from: data)
            let countries = Array(response.data.values).sorted { $0.name < $1.name }
            print("✅ Fetched \(countries.count) countries (dictionary format)")
            return countries
        } catch {
            print("❌ Countries decoding error: \(error)")
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw countries response: \(responseString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

}
