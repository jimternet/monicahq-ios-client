import Foundation

/// Activity type model for Monica API
struct ActivityType: Codable, Identifiable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
