import Foundation

/// Generic wrapper for all Monica API responses
struct APIResponse<T: Codable>: Codable {
    let data: T
    let meta: PaginationMeta?
    let links: PaginationLinks?
}