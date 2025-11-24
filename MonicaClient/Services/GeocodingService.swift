//
//  GeocodingService.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Geocoding Error

enum GeocodingError: LocalizedError {
    case geocodingFailed
    case noResults
    case invalidAddress

    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Unable to find location for this address"
        case .noResults:
            return "No results found for this address"
        case .invalidAddress:
            return "The address appears to be invalid"
        }
    }
}

// MARK: - Geocoding Service

/// Service for geocoding addresses and opening maps
final class GeocodingService {

    // MARK: - Singleton

    static let shared = GeocodingService()

    // MARK: - Private Properties

    private let geocoder = CLGeocoder()

    private init() {}

    // MARK: - Public Methods

    /// Geocode an address string to coordinates
    func geocodeAddress(_ address: Address) async throws -> CLLocationCoordinate2D {
        // If address already has coordinates, return them
        if let coordinate = address.coordinate {
            return coordinate
        }

        // Build geocodable string
        let addressString = address.geocodableString
        guard !addressString.isEmpty else {
            throw GeocodingError.invalidAddress
        }

        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)
            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                throw GeocodingError.noResults
            }
            return location.coordinate
        } catch {
            if (error as NSError).domain == kCLErrorDomain {
                throw GeocodingError.geocodingFailed
            }
            throw error
        }
    }

    /// Open Maps app with directions to the address
    func openDirections(to address: Address, contactName: String?) async throws {
        let coordinate: CLLocationCoordinate2D

        // Try to get coordinates
        if let existingCoordinate = address.coordinate {
            coordinate = existingCoordinate
        } else {
            coordinate = try await geocodeAddress(address)
        }

        // Create map item
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = contactName ?? address.displayLabel

        // Open in Maps with driving directions
        await MainActor.run {
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }

    /// Open Maps app centered on the address location
    func openMap(for address: Address, contactName: String?) async throws {
        let coordinate: CLLocationCoordinate2D

        // Try to get coordinates
        if let existingCoordinate = address.coordinate {
            coordinate = existingCoordinate
        } else {
            coordinate = try await geocodeAddress(address)
        }

        // Create map item
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = contactName ?? address.displayLabel

        // Open in Maps
        await MainActor.run {
            mapItem.openInMaps()
        }
    }
}
