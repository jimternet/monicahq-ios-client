//
//  AddressFormViewModelTests.swift
//  MonicaClientTests
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import XCTest
@testable import MonicaClient

@MainActor
final class AddressFormViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: AddressFormViewModel!
    var mockAPIClient: MockFormAPIClient!
    var mockCacheService: MockFormCacheService!

    // MARK: - Setup/Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockFormAPIClient()
        mockCacheService = MockFormCacheService()
        sut = AddressFormViewModel(
            contactId: 1,
            apiClient: mockAPIClient,
            cacheService: mockCacheService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        mockCacheService = nil
        try await super.tearDown()
    }

    // MARK: - Validation Tests

    func testIsValid_WhenAllFieldsEmpty_ReturnsFalse() {
        // Given
        sut.street = ""
        sut.city = ""
        sut.selectedCountry = nil

        // Then
        XCTAssertFalse(sut.isValid)
    }

    func testIsValid_WhenStreetFilled_ReturnsTrue() {
        // Given
        sut.street = "123 Main St"
        sut.city = ""
        sut.selectedCountry = nil

        // Then
        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_WhenCityFilled_ReturnsTrue() {
        // Given
        sut.street = ""
        sut.city = "San Francisco"
        sut.selectedCountry = nil

        // Then
        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_WhenCountrySelected_ReturnsTrue() {
        // Given
        sut.street = ""
        sut.city = ""
        sut.selectedCountry = Country.unitedStates

        // Then
        XCTAssertTrue(sut.isValid)
    }

    func testIsValid_WhenOnlyWhitespace_ReturnsFalse() {
        // Given
        sut.street = "   "
        sut.city = "  "
        sut.selectedCountry = nil

        // Then
        XCTAssertFalse(sut.isValid)
    }

    // MARK: - Load Countries Tests

    func testLoadCountries_WhenCacheHit_UsesCache() async {
        // Given
        mockCacheService.stubbedCountries = Country.previewCountries

        // When
        await sut.loadCountries()

        // Then
        XCTAssertEqual(sut.countries.count, 4)
        XCTAssertFalse(sut.isLoadingCountries)
    }

    func testLoadCountries_WhenCacheMiss_FetchesFromAPI() async {
        // Given
        mockCacheService.stubbedCountries = nil
        mockAPIClient.stubbedCountries = [Country.unitedStates]

        // When
        await sut.loadCountries()

        // Then
        XCTAssertEqual(sut.countries.count, 1)
        XCTAssertTrue(mockCacheService.setCountriesCalled)
    }

    func testLoadCountries_WhenAPIFails_ContinuesWithEmptyList() async {
        // Given
        mockCacheService.stubbedCountries = nil
        mockAPIClient.shouldThrowError = true

        // When
        await sut.loadCountries()

        // Then
        XCTAssertEqual(sut.countries.count, 0)
        XCTAssertFalse(sut.isLoadingCountries)
    }

    // MARK: - Save Tests

    func testSave_WhenValid_ReturnsAddress() async {
        // Given
        sut.street = "123 Main St"
        sut.city = "San Francisco"
        let expectedAddress = createTestAddress()
        mockAPIClient.stubbedCreatedAddress = expectedAddress

        // When
        let result = await sut.save()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, expectedAddress.id)
        XCTAssertEqual(sut.state, .success)
    }

    func testSave_WhenInvalid_SetsError() async {
        // Given
        sut.street = ""
        sut.city = ""
        sut.selectedCountry = nil

        // When
        let result = await sut.save()

        // Then
        XCTAssertNil(result)
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
    }

    func testSave_WhenAPIFails_SetsError() async {
        // Given
        sut.street = "123 Main St"
        mockAPIClient.shouldThrowError = true

        // When
        let result = await sut.save()

        // Then
        XCTAssertNil(result)
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Edit Mode Tests

    func testEditMode_PrePopulatesFields() async {
        // Given
        let existingAddress = createTestAddress()
        let editViewModel = AddressFormViewModel(
            contactId: 1,
            apiClient: mockAPIClient,
            cacheService: mockCacheService,
            mode: .edit(existingAddress)
        )

        // Then
        XCTAssertEqual(editViewModel.name, existingAddress.name)
        XCTAssertEqual(editViewModel.street, existingAddress.street)
        XCTAssertEqual(editViewModel.city, existingAddress.city)
        XCTAssertTrue(editViewModel.isEditMode)
    }

    func testEditMode_CallsUpdate() async {
        // Given
        let existingAddress = createTestAddress()
        let editViewModel = AddressFormViewModel(
            contactId: 1,
            apiClient: mockAPIClient,
            cacheService: mockCacheService,
            mode: .edit(existingAddress)
        )
        editViewModel.street = "456 New St"
        mockAPIClient.stubbedUpdatedAddress = existingAddress

        // When
        let result = await editViewModel.save()

        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockAPIClient.updateAddressCalled)
    }

    // MARK: - Country Label Tests

    func testPostalCodeLabel_ForUS_ReturnsZIPCode() {
        // Given
        sut.selectedCountry = Country.unitedStates

        // Then
        XCTAssertEqual(sut.postalCodeLabel, "ZIP Code")
    }

    func testPostalCodeLabel_ForUK_ReturnsPostcode() {
        // Given
        sut.selectedCountry = Country.unitedKingdom

        // Then
        XCTAssertEqual(sut.postalCodeLabel, "Postcode")
    }

    func testPostalCodeLabel_WhenNoCountry_ReturnsDefault() {
        // Given
        sut.selectedCountry = nil

        // Then
        XCTAssertEqual(sut.postalCodeLabel, "Postal Code")
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllFields() {
        // Given
        sut.name = "Home"
        sut.street = "123 Main St"
        sut.city = "San Francisco"
        sut.state = .error("Test error")

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.street, "")
        XCTAssertEqual(sut.city, "")
        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Helper Methods

    private func createTestAddress() -> Address {
        Address(
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
    }
}

// MARK: - Mock API Client for Form

class MockFormAPIClient: MonicaAPIClient {
    var stubbedCountries: [Country] = []
    var stubbedCreatedAddress: Address?
    var stubbedUpdatedAddress: Address?
    var shouldThrowError = false
    var updateAddressCalled = false

    init() {
        super.init(baseURL: "https://test.com", apiToken: "test-token")
    }

    override func fetchCountries() async throws -> [Country] {
        if shouldThrowError {
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
        return stubbedCountries
    }

    override func createAddress(contactId: Int, request: AddressCreateRequest) async throws -> Address {
        if shouldThrowError {
            throw APIError.serverError(500)
        }
        return stubbedCreatedAddress ?? Address(
            id: 1, object: "address", name: nil, street: nil, city: nil,
            province: nil, postalCode: nil, country: nil, latitude: nil,
            longitude: nil, contact: nil, account: nil, createdAt: nil, updatedAt: nil
        )
    }

    override func updateAddress(addressId: Int, request: AddressUpdateRequest) async throws -> Address {
        updateAddressCalled = true
        if shouldThrowError {
            throw APIError.serverError(500)
        }
        return stubbedUpdatedAddress ?? Address(
            id: addressId, object: "address", name: nil, street: nil, city: nil,
            province: nil, postalCode: nil, country: nil, latitude: nil,
            longitude: nil, contact: nil, account: nil, createdAt: nil, updatedAt: nil
        )
    }
}

// MARK: - Mock Cache Service for Form

class MockFormCacheService: CacheService {
    var stubbedCountries: [Country]?
    var setCountriesCalled = false

    override func getCountries() -> [Country]? {
        return stubbedCountries
    }

    override func setCountries(_ countries: [Country]) {
        setCountriesCalled = true
    }

    override func invalidateAddresses(for contactId: Int) {
        // No-op for form tests
    }
}
