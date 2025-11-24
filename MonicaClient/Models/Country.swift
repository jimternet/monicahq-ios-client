//
//  Country.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

// MARK: - Country Model

/// Represents a nation from a standardized list
struct Country: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String
    let iso: String

    enum CodingKeys: String, CodingKey {
        case id, object, name, iso
    }

    /// Convenience initializer for testing/previews
    init(id: Int, object: String = "country", name: String, iso: String) {
        self.id = id
        self.object = object
        self.name = name
        self.iso = iso
    }
}

// MARK: - Country Extensions

extension Country {
    /// Returns the country's flag emoji based on ISO code
    var flagEmoji: String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in iso.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(String(flagScalar))
            }
        }
        return emoji
    }

    /// Returns localized label for postal code field based on country
    var postalCodeLabel: String {
        switch iso.uppercased() {
        case "US":
            return "ZIP Code"
        case "GB", "UK":
            return "Postcode"
        case "CA":
            return "Postal Code"
        case "AU":
            return "Postcode"
        default:
            return "Postal Code"
        }
    }

    /// Returns localized label for province/state field based on country
    var provinceLabel: String {
        switch iso.uppercased() {
        case "US":
            return "State"
        case "GB", "UK":
            return "County"
        case "CA":
            return "Province"
        case "AU":
            return "State/Territory"
        default:
            return "Province/State"
        }
    }
}

// MARK: - Response Wrappers

/// List of countries response from API
struct CountryListResponse: Codable {
    let data: [Country]
}

// MARK: - Preview/Test Data

extension Country {
    static let unitedStates = Country(id: 1, name: "United States", iso: "US")
    static let canada = Country(id: 2, name: "Canada", iso: "CA")
    static let unitedKingdom = Country(id: 3, name: "United Kingdom", iso: "GB")
    static let australia = Country(id: 4, name: "Australia", iso: "AU")

    static let previewCountries: [Country] = [
        unitedStates, canada, unitedKingdom, australia
    ]
}
