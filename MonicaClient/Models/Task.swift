import Foundation
import SwiftUI

/// To-do item or action item related to a contact
struct MonicaTask: Codable, Identifiable {
    let id: Int
    let contactId: Int?
    let title: String
    let description: String?
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case title
        case description
        case isCompleted = "completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// API response wrapper for tasks
typealias TasksResponse = APIResponse<[MonicaTask]>