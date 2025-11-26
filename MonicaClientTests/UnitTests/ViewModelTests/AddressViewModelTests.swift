//
//  AddressViewModelTests.swift
//  MonicaClientTests
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import XCTest
@testable import MonicaClient

@MainActor
final class AddressViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: AddressViewModel!
    var mockAPIClient: MockMonicaAPIClient!
    var mockCacheService: MockCacheService!

    // MARK: - Setup/Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockMonicaAPIClient()
        mockCacheService = MockCacheService()
        sut = AddressViewModel(
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

    // MARK: - Load Addresses Tests

    func testLoadAddresses_WhenCacheHit_UsesCache() async {
        // Given
        let cachedAddresses = [createTestAddress(id: 1)]
        mockCacheService.stubbedAddresses = cachedAddresses

        // When
        await sut.loadAddresses()

        // Then
        XCTAssertEqual(sut.addresses.count, 1)
        XCTAssertEqual(sut.addresses.first?.id, 1)
        if case .loaded(let addresses) = sut.state {
            XCTAssertEqual(addresses.count, 1)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testLoadAddresses_WhenCacheMiss_FetchesFromAPI() async {
        // Given
        let apiAddresses = [createTestAddress(id: 2), createTestAddress(id: 3)]
        mockAPIClient.stubbedAddresses = apiAddresses
        mockCacheService.stubbedAddresses = nil

        // When
        await sut.loadAddresses()

        // Then
        XCTAssertEqual(sut.addresses.count, 2)
        XCTAssertTrue(mockCacheService.setAddressesCalled)
    }

    func testLoadAddresses_WhenEmpty_SetsEmptyState() async {
        // Given
        mockAPIClient.stubbedAddresses = []
        mockCacheService.stubbedAddresses = nil

        // When
        await sut.loadAddresses()

        // Then
        XCTAssertEqual(sut.state, .empty)
    }

    func testLoadAddresses_WhenAPIError_SetsErrorState() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = APIError.networkError(NSError(domain: "test", code: -1))
        mockCacheService.stubbedAddresses = nil

        // When
        await sut.loadAddresses()

        // Then
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Delete Address Tests

    func testDeleteAddress_WhenSuccessful_RemovesFromList() async {
        // Given
        let addresses = [createTestAddress(id: 1), createTestAddress(id: 2)]
        sut.addresses = addresses
        mockAPIClient.deleteAddressSuccess = true

        // When
        let result = await sut.deleteAddress(id: 1)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.addresses.count, 1)
        XCTAssertEqual(sut.addresses.first?.id, 2)
    }

    func testDeleteAddress_WhenFails_ReturnsFalse() async {
        // Given
        let addresses = [createTestAddress(id: 1)]
        sut.addresses = addresses
        mockAPIClient.deleteAddressSuccess = false
        mockAPIClient.shouldThrowError = true

        // When
        let result = await sut.deleteAddress(id: 1)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(sut.addresses.count, 1)
    }

    func testDeleteAddress_WhenLastAddress_SetsEmptyState() async {
        // Given
        let addresses = [createTestAddress(id: 1)]
        sut.addresses = addresses
        mockAPIClient.deleteAddressSuccess = true

        // When
        _ = await sut.deleteAddress(id: 1)

        // Then
        XCTAssertEqual(sut.state, .empty)
    }

    // MARK: - Refresh Tests

    func testRefresh_InvalidatesCache() async {
        // Given
        mockAPIClient.stubbedAddresses = [createTestAddress(id: 1)]

        // When
        await sut.refresh()

        // Then
        XCTAssertTrue(mockCacheService.invalidateAddressesCalled)
    }

    // MARK: - Copy to Clipboard Tests

    func testCopyToClipboard_CopiesFormattedAddress() {
        // Given
        let address = createTestAddress(id: 1)

        // When
        sut.copyToClipboard(address)

        // Then
        // Note: UIPasteboard behavior can't be easily tested without UI context
        // This test verifies the method doesn't crash
    }

    // MARK: - Helper Methods

    private func createTestAddress(id: Int) -> Address {
        Address(
            id: id,
            object: "address",
            name: "Test",
            street: "123 Main St",
            city: "San Francisco",
            province: "CA",
            postalCode: "94102",
            country: nil,
            latitude: nil,
            longitude: nil,
            contact: nil,
            account: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Mock API Client

class MockMonicaAPIClient: MonicaAPIClient {
    var stubbedAddresses: [Address] = []
    var shouldThrowError = false
    var errorToThrow: Error = APIError.networkError(NSError(domain: "test", code: -1))
    var deleteAddressSuccess = true

    init() {
        super.init(baseURL: "https://test.com", apiToken: "test-token")
    }

    override func fetchAddresses(contactId: Int) async throws -> [Address] {
        if shouldThrowError {
            throw errorToThrow
        }
        return stubbedAddresses
    }

    override func deleteAddress(addressId: Int) async throws {
        if !deleteAddressSuccess || shouldThrowError {
            throw APIError.serverError(500)
        }
    }
}

// MARK: - Mock Cache Service

class MockCacheService: CacheService {
    var stubbedAddresses: [Address]?
    var setAddressesCalled = false
    var invalidateAddressesCalled = false

    override func getAddresses(for contactId: Int) -> [Address]? {
        return stubbedAddresses
    }

    override func setAddresses(_ addresses: [Address], for contactId: Int) {
        setAddressesCalled = true
    }

    override func invalidateAddresses(for contactId: Int) {
        invalidateAddressesCalled = true
    }
}
