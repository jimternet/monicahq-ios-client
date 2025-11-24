//
//  AddressViewModel.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - View State

/// Represents the current state of address list view
enum AddressViewState: Equatable {
    case loading
    case loaded([Address])
    case empty
    case error(String)

    static func == (lhs: AddressViewState, rhs: AddressViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.empty, .empty):
            return true
        case let (.loaded(lAddresses), .loaded(rAddresses)):
            return lAddresses.map(\.id) == rAddresses.map(\.id)
        case let (.error(lMsg), .error(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Address ViewModel

/// ViewModel for managing address list and operations
@MainActor
class AddressViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var state: AddressViewState = .loading
    @Published var addresses: [Address] = []
    @Published var isRefreshing = false

    // MARK: - Dependencies

    let apiClient: MonicaAPIClient
    private let cacheService: CacheService
    private let contactId: Int

    // MARK: - Initialization

    init(contactId: Int, apiClient: MonicaAPIClient, cacheService: CacheService = .shared) {
        self.contactId = contactId
        self.apiClient = apiClient
        self.cacheService = cacheService
    }

    // MARK: - Public Methods

    /// Load addresses for the contact
    func loadAddresses() async {
        // Check cache first
        if let cached = cacheService.getAddresses(for: contactId) {
            addresses = cached
            state = cached.isEmpty ? .empty : .loaded(cached)
            // Still refresh in background
            await refreshInBackground()
            return
        }

        state = .loading
        await fetchAddresses()
    }

    /// Refresh addresses (for pull-to-refresh)
    func refresh() async {
        isRefreshing = true
        cacheService.invalidateAddresses(for: contactId)
        await fetchAddresses()
        isRefreshing = false
    }

    /// Delete an address
    func deleteAddress(id: Int) async -> Bool {
        do {
            try await apiClient.deleteAddress(addressId: id)
            // Update local state
            addresses.removeAll { $0.id == id }
            cacheService.setAddresses(addresses, for: contactId)
            state = addresses.isEmpty ? .empty : .loaded(addresses)
            return true
        } catch {
            print("❌ Failed to delete address: \(error)")
            return false
        }
    }

    /// Copy address to clipboard
    func copyToClipboard(_ address: Address) {
        UIPasteboard.general.string = address.formattedAddress
    }

    /// Get directions to address
    func openDirections(to address: Address, contactName: String?) async throws {
        try await GeocodingService.shared.openDirections(to: address, contactName: contactName)
    }

    /// Open map for address
    func openMap(for address: Address, contactName: String?) async throws {
        try await GeocodingService.shared.openMap(for: address, contactName: contactName)
    }

    // MARK: - Private Methods

    private func fetchAddresses() async {
        do {
            let fetchedAddresses = try await apiClient.fetchAddresses(contactId: contactId)
            addresses = fetchedAddresses
            cacheService.setAddresses(fetchedAddresses, for: contactId)
            state = fetchedAddresses.isEmpty ? .empty : .loaded(fetchedAddresses)
        } catch let error as APIError {
            handleError(error)
        } catch {
            state = .error("An unexpected error occurred")
        }
    }

    private func refreshInBackground() async {
        do {
            let fetchedAddresses = try await apiClient.fetchAddresses(contactId: contactId)
            if fetchedAddresses != addresses {
                addresses = fetchedAddresses
                cacheService.setAddresses(fetchedAddresses, for: contactId)
                state = fetchedAddresses.isEmpty ? .empty : .loaded(fetchedAddresses)
            }
        } catch {
            // Silently fail background refresh - we have cached data
            print("⚠️ Background refresh failed: \(error)")
        }
    }

    private func handleError(_ error: APIError) {
        switch error {
        case .unauthorized:
            state = .error("Session expired. Please log in again.")
        case .networkError:
            // Try to use cached data if available
            if let cached = cacheService.getAddresses(for: contactId) {
                addresses = cached
                state = cached.isEmpty ? .empty : .loaded(cached)
            } else {
                state = .error("No internet connection. Please try again.")
            }
        case .serverError(let code):
            if code == 404 {
                state = .empty
            } else {
                state = .error("Server error. Please try again later.")
            }
        default:
            state = .error("Unable to load addresses. Please try again.")
        }
    }
}

// MARK: - Array Extension for Address Comparison

extension Array where Element == Address {
    static func != (lhs: [Address], rhs: [Address]) -> Bool {
        guard lhs.count == rhs.count else { return true }
        return zip(lhs, rhs).contains { $0.id != $1.id }
    }
}
