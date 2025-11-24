//
//  GeocodingServiceTests.swift
//  MonicaClientTests
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import XCTest
import CoreLocation
@testable import MonicaClient

final class GeocodingServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: GeocodingService!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        sut = GeocodingService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - GeocodingError Tests

    func testGeocodingError_GeocodingFailed_HasCorrectDescription() {
        // Given
        let error = GeocodingError.geocodingFailed

        // Then
        XCTAssertEqual(error.errorDescription, "Unable to find location for this address")
    }

    func testGeocodingError_NoResults_HasCorrectDescription() {
        // Given
        let error = GeocodingError.noResults

        // Then
        XCTAssertEqual(error.errorDescription, "No results found for this address")
    }

    func testGeocodingError_InvalidAddress_HasCorrectDescription() {
        // Given
        let error = GeocodingError.invalidAddress

        // Then
        XCTAssertEqual(error.errorDescription, "The address appears to be invalid")
    }

    // MARK: - Geocoding Tests with Existing Coordinates

    func testGeocodeAddress_WhenAddressHasCoordinates_ReturnsExistingCoordinates() async throws {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: "Home",
            street: "123 Main St",
            city: "San Francisco",
            province: "CA",
            postalCode: "94102",
            country: nil,
            latitude: 37.7749,
            longitude: -122.4194,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When
        let coordinate = try await sut.geocodeAddress(address)

        // Then
        XCTAssertEqual(coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -122.4194, accuracy: 0.0001)
    }

    func testGeocodeAddress_WhenAddressIsEmpty_ThrowsInvalidAddressError() async {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: nil,
            city: nil,
            province: nil,
            postalCode: nil,
            country: nil,
            latitude: nil,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When/Then
        do {
            _ = try await sut.geocodeAddress(address)
            XCTFail("Expected invalidAddress error")
        } catch let error as GeocodingError {
            XCTAssertEqual(error, GeocodingError.invalidAddress)
        } catch {
            XCTFail("Expected GeocodingError.invalidAddress, got \(error)")
        }
    }

    // MARK: - Singleton Tests

    func testShared_ReturnsSameInstance() {
        // When
        let instance1 = GeocodingService.shared
        let instance2 = GeocodingService.shared

        // Then
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Integration Tests (Requires Network)
    // These tests require network access and may be flaky
    // They are commented out for CI/CD but can be run locally

    /*
    func testGeocodeAddress_WhenValidAddress_ReturnsCoordinates() async throws {
        // Given - Known address in San Francisco
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: "1 Infinite Loop",
            city: "Cupertino",
            province: "CA",
            postalCode: "95014",
            country: Country.unitedStates,
            latitude: nil,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When
        let coordinate = try await sut.geocodeAddress(address)

        // Then - Apple HQ approximate coordinates
        XCTAssertEqual(coordinate.latitude, 37.33, accuracy: 0.1)
        XCTAssertEqual(coordinate.longitude, -122.03, accuracy: 0.1)
    }
    */
}

// MARK: - Address Extension Tests

extension GeocodingServiceTests {

    func testAddressCoordinate_WhenLatLongPresent_ReturnsCoordinate() {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: nil,
            city: nil,
            province: nil,
            postalCode: nil,
            country: nil,
            latitude: 40.7128,
            longitude: -74.0060,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When
        let coordinate = address.coordinate

        // Then
        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate?.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(coordinate?.longitude, -74.0060, accuracy: 0.0001)
    }

    func testAddressCoordinate_WhenLatLongMissing_ReturnsNil() {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: nil,
            city: nil,
            province: nil,
            postalCode: nil,
            country: nil,
            latitude: nil,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When
        let coordinate = address.coordinate

        // Then
        XCTAssertNil(coordinate)
    }

    func testAddressHasCoordinates_WhenBothPresent_ReturnsTrue() {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: nil,
            city: nil,
            province: nil,
            postalCode: nil,
            country: nil,
            latitude: 40.7128,
            longitude: -74.0060,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // Then
        XCTAssertTrue(address.hasCoordinates)
    }

    func testAddressHasCoordinates_WhenOnlyLatitude_ReturnsFalse() {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: nil,
            street: nil,
            city: nil,
            province: nil,
            postalCode: nil,
            country: nil,
            latitude: 40.7128,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // Then
        XCTAssertFalse(address.hasCoordinates)
    }

    func testAddressGeocodableString_BuildsCorrectString() {
        // Given
        let address = Address(
            id: 1,
            object: "address",
            name: "Home",
            street: "123 Main St",
            city: "San Francisco",
            province: "CA",
            postalCode: "94102",
            country: Country.unitedStates,
            latitude: nil,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // When
        let geocodableString = address.geocodableString

        // Then
        XCTAssertTrue(geocodableString.contains("123 Main St"))
        XCTAssertTrue(geocodableString.contains("San Francisco"))
        XCTAssertTrue(geocodableString.contains("CA"))
        XCTAssertTrue(geocodableString.contains("94102"))
    }
}
