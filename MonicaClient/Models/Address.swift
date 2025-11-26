//
//  Address.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Address Model

/// Represents a physical location associated with a contact
struct Address: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let country: Country?
    let latitude: Double?
    let longitude: Double?
    let contact: ContactReference?
    let account: AccountReference?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, object, name, street, city, province
        case postalCode = "postal_code"
        case country, latitude, longitude, contact, account
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Address Computed Properties

extension Address {
    /// Returns true if address has valid coordinates for map display
    var hasCoordinates: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return lat != 0 && lon != 0
    }

    /// Returns CLLocationCoordinate2D for MapKit
    var coordinate: CLLocationCoordinate2D? {
        guard hasCoordinates,
              let lat = latitude,
              let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Returns formatted address string for display
    var formattedAddress: String {
        AddressFormatter.format(self)
    }

    /// Returns display label (name or default)
    var displayLabel: String {
        name ?? "Address"
    }

    /// Returns string suitable for geocoding
    var geocodableString: String {
        [street, city, province, postalCode, country?.name]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

// MARK: - Supporting Types

/// Lightweight reference to parent contact
struct ContactReference: Codable, Hashable {
    let id: Int
}

/// Lightweight reference to parent account
struct AccountReference: Codable, Hashable {
    let id: Int
}

// MARK: - Request Models

/// Request body for creating a new address
struct AddressCreateRequest: Codable {
    let contactId: Int
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let country: String?  // Country ISO code (e.g., "US", "GB")

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case name, street, city, province
        case postalCode = "postal_code"
        case country
    }

    init(contactId: Int,
         name: String? = nil,
         street: String? = nil,
         city: String? = nil,
         province: String? = nil,
         postalCode: String? = nil,
         country: String? = nil) {
        self.contactId = contactId
        self.name = name
        self.street = street
        self.city = city
        self.province = province
        self.postalCode = postalCode
        self.country = country
    }
}

/// Request body for updating an existing address
struct AddressUpdateRequest: Codable {
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let country: String?  // Country ISO code (e.g., "US", "GB")

    enum CodingKeys: String, CodingKey {
        case name, street, city, province
        case postalCode = "postal_code"
        case country
    }

    init(name: String? = nil,
         street: String? = nil,
         city: String? = nil,
         province: String? = nil,
         postalCode: String? = nil,
         country: String? = nil) {
        self.name = name
        self.street = street
        self.city = city
        self.province = province
        self.postalCode = postalCode
        self.country = country
    }
}

// MARK: - Response Wrappers

/// Single address response from API
struct AddressResponse: Codable {
    let data: Address
}

/// List of addresses response from API
struct AddressListResponse: Codable {
    let data: [Address]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}

// Note: PaginationLinks and PaginationMeta are defined in Contact.swift
