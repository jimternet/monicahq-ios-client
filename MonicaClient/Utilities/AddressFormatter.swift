//
//  AddressFormatter.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

/// Utility for formatting addresses for display
/// Handles international address format variations
enum AddressFormatter {

    /// Format an address for display
    /// Uses Western format (most common) with graceful handling of missing fields
    /// - Parameter address: The address to format
    /// - Returns: Multi-line formatted address string
    static func format(_ address: Address) -> String {
        var lines: [String] = []

        // Line 1: Street address
        if let street = address.street, !street.isEmpty {
            lines.append(street)
        }

        // Line 2: City, Province/State PostalCode
        var cityLine = buildCityLine(
            city: address.city,
            province: address.province,
            postalCode: address.postalCode
        )
        if !cityLine.isEmpty {
            lines.append(cityLine)
        }

        // Line 3: Country
        if let country = address.country?.name, !country.isEmpty {
            lines.append(country)
        }

        // If no lines, return placeholder
        if lines.isEmpty {
            return "No address details"
        }

        return lines.joined(separator: "\n")
    }

    /// Format an address as a single line for compact display
    /// - Parameter address: The address to format
    /// - Returns: Single-line formatted address string
    static func formatCompact(_ address: Address) -> String {
        var components: [String] = []

        if let street = address.street, !street.isEmpty {
            components.append(street)
        }
        if let city = address.city, !city.isEmpty {
            components.append(city)
        }
        if let province = address.province, !province.isEmpty {
            components.append(province)
        }
        if let country = address.country?.name, !country.isEmpty {
            components.append(country)
        }

        if components.isEmpty {
            return "No address details"
        }

        return components.joined(separator: ", ")
    }

    /// Build the city line with appropriate formatting
    private static func buildCityLine(city: String?, province: String?, postalCode: String?) -> String {
        var parts: [String] = []

        if let city = city, !city.isEmpty {
            parts.append(city)
        }

        if let province = province, !province.isEmpty {
            if parts.isEmpty {
                parts.append(province)
            } else {
                // City, Province format
                parts[parts.count - 1] += ", \(province)"
            }
        }

        if let postalCode = postalCode, !postalCode.isEmpty {
            if parts.isEmpty {
                parts.append(postalCode)
            } else {
                // Add postal code with space
                parts[parts.count - 1] += " \(postalCode)"
            }
        }

        return parts.joined(separator: " ")
    }

    /// Get the appropriate label for postal code based on country
    /// - Parameter country: The country, if known
    /// - Returns: Localized label for postal code field
    static func postalCodeLabel(for country: Country?) -> String {
        guard let country = country else { return "Postal Code" }
        return country.postalCodeLabel
    }

    /// Get the appropriate label for province/state based on country
    /// - Parameter country: The country, if known
    /// - Returns: Localized label for province field
    static func provinceLabel(for country: Country?) -> String {
        guard let country = country else { return "Province/State" }
        return country.provinceLabel
    }
}
