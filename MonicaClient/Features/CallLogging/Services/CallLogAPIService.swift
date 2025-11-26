import Foundation

/// API service for call logs using Monica v4.x /api/calls endpoint
/// Based on verified Monica v4.x Call API structure
@MainActor
class CallLogAPIService {
    private let apiClient: MonicaAPIClient

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Call Log API Methods (Monica v4.x)

    /// Fetch all call logs for a contact from the server
    /// Uses GET /api/contacts/{id}/calls endpoint
    func fetchCallLogs(for contactId: Int) async throws -> [CallLog] {
        let endpoint = "/contacts/\(contactId)/calls"
        let data = try await apiClient.makeRequest(endpoint: endpoint, method: "GET")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(CallLogListResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode call logs: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Create a call log on the server via POST /api/calls endpoint
    /// Monica v4.x fields: contact_id, called_at, content, contact_called, emotions (array)
    func createCallLog(
        contactId: Int,
        calledAt: Date,
        content: String?,
        contactCalled: Bool,
        emotionIds: [Int]
    ) async throws -> CallLog {
        let payload = CallLogCreatePayload(
            contactId: contactId,
            calledAt: calledAt,
            content: content,
            contactCalled: contactCalled,
            emotions: emotionIds
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(payload)

        let data = try await apiClient.makeRequest(endpoint: "/calls", method: "POST", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(CallLogResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode created call log: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Update a call log on the server via PUT /api/calls/{id} endpoint
    /// Monica v4.x fields: content, contact_called, emotions (array)
    func updateCallLog(
        id: Int,
        content: String?,
        contactCalled: Bool?,
        emotionIds: [Int]?
    ) async throws -> CallLog {
        let payload = CallLogUpdatePayload(
            content: content,
            contactCalled: contactCalled,
            emotions: emotionIds
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(payload)

        let data = try await apiClient.makeRequest(endpoint: "/calls/\(id)", method: "PUT", body: body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let response = try decoder.decode(CallLogResponse.self, from: data)
            return response.data
        } catch {
            print("❌ Failed to decode updated call log: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))")
            }
            throw APIError.decodingError
        }
    }

    /// Delete a call log from the server via DELETE /api/calls/{id} endpoint
    func deleteCallLog(id: Int) async throws {
        _ = try await apiClient.makeRequest(endpoint: "/calls/\(id)", method: "DELETE")
    }
}

// MARK: - API Request/Response Models

/// Payload for creating a new call log (Monica v4.x)
private struct CallLogCreatePayload: Codable {
    let contactId: Int
    let calledAt: Date
    let content: String?
    let contactCalled: Bool
    let emotions: [Int]

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
        case contactCalled = "contact_called"
        case emotions
    }
}

/// Payload for updating a call log (Monica v4.x)
private struct CallLogUpdatePayload: Codable {
    let content: String?
    let contactCalled: Bool?
    let emotions: [Int]?

    enum CodingKeys: String, CodingKey {
        case content
        case contactCalled = "contact_called"
        case emotions
    }
}

/// API response wrapper for a single call log
private struct CallLogResponse: Codable {
    let data: CallLog
}

/// API response wrapper for a list of call logs
private struct CallLogListResponse: Codable {
    let data: [CallLog]
}

