import Foundation

class NotesManager {
    private let apiClient: MonicaAPIClient
    
    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }
    
    func fetchNotes() async throws -> [Note] {
        let data = try await apiClient.fetchNotesRaw()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(NotesResponse.self, from: data)
            print("✅ Decoded \(response.data.count) notes")
            return response.data
        } catch {
            print("❌ Failed to decode notes: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }
    
    func fetchContactNotes(contactId: Int) async throws -> [Note] {
        // Filter notes by contact ID from all notes
        let allNotes = try await fetchNotes()
        return allNotes.filter { $0.contactId == contactId }
    }
}