//
//  AddressFormViewModel.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation

// MARK: - Form State

/// State of the address form
enum AddressFormState: Equatable {
    case idle
    case saving
    case success
    case error(String)
}

// MARK: - Form Mode

/// Mode of the address form
enum AddressFormMode {
    case create
    case edit(Address)
}

// MARK: - AddressFormViewModel

/// ViewModel for creating and editing addresses
@MainActor
class AddressFormViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var state: AddressFormState = .idle

    // Form fields
    @Published var name: String = ""
    @Published var street: String = ""
    @Published var city: String = ""
    @Published var province: String = ""
    @Published var postalCode: String = ""
    @Published var selectedCountry: Country?

    // Countries list
    @Published var countries: [Country] = []
    @Published var isLoadingCountries: Bool = false

    // MARK: - Private Properties

    private let contactId: Int
    private let apiClient: MonicaAPIClient
    private let cacheService: CacheService
    private let mode: AddressFormMode
    private var existingAddressId: Int?

    // MARK: - Computed Properties

    /// Returns true if at least one address field has content
    var isValid: Bool {
        !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedCountry != nil
    }

    /// Returns the current country's postal code label
    var postalCodeLabel: String {
        selectedCountry?.postalCodeLabel ?? "Postal Code"
    }

    /// Returns the current country's province label
    var provinceLabel: String {
        selectedCountry?.provinceLabel ?? "Province/State"
    }

    /// Returns true if in edit mode
    var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: - Initialization

    init(contactId: Int, apiClient: MonicaAPIClient, cacheService: CacheService = .shared, mode: AddressFormMode = .create) {
        self.contactId = contactId
        self.apiClient = apiClient
        self.cacheService = cacheService
        self.mode = mode

        // Pre-populate fields if editing
        if case .edit(let address) = mode {
            self.existingAddressId = address.id
            self.name = address.name ?? ""
            self.street = address.street ?? ""
            self.city = address.city ?? ""
            self.province = address.province ?? ""
            self.postalCode = address.postalCode ?? ""
            self.selectedCountry = address.country
        }
    }

    // MARK: - Public Methods

    /// Load available countries
    func loadCountries() async {
        isLoadingCountries = true

        // Try cache first
        if let cached = cacheService.getCountries() {
            countries = cached
            isLoadingCountries = false
            return
        }

        // Fetch from API
        do {
            let fetchedCountries = try await apiClient.fetchCountries()
            countries = fetchedCountries
            cacheService.setCountries(fetchedCountries)
        } catch {
            print("❌ Failed to load countries: \(error)")
            // Continue with empty list - user can still save without country
        }

        isLoadingCountries = false
    }

    /// Save the address (create or update based on mode)
    func save() async -> Address? {
        guard isValid else {
            state = .error("Please fill in at least one address field")
            return nil
        }

        state = .saving

        do {
            let address: Address

            if let existingId = existingAddressId {
                // Update existing address
                let request = AddressUpdateRequest(
                    name: name.isEmpty ? nil : name,
                    street: street.isEmpty ? nil : street,
                    city: city.isEmpty ? nil : city,
                    province: province.isEmpty ? nil : province,
                    postalCode: postalCode.isEmpty ? nil : postalCode,
                    country: selectedCountry?.iso
                )
                address = try await apiClient.updateAddress(addressId: existingId, request: request)
            } else {
                // Create new address
                let request = AddressCreateRequest(
                    contactId: contactId,
                    name: name.isEmpty ? nil : name,
                    street: street.isEmpty ? nil : street,
                    city: city.isEmpty ? nil : city,
                    province: province.isEmpty ? nil : province,
                    postalCode: postalCode.isEmpty ? nil : postalCode,
                    country: selectedCountry?.iso
                )
                address = try await apiClient.createAddress(contactId: contactId, request: request)
            }

            // Invalidate cache for this contact
            cacheService.invalidateAddresses(for: contactId)

            state = .success
            return address
        } catch {
            state = .error(error.localizedDescription)
            return nil
        }
    }

    /// Reset the form to initial state
    func reset() {
        state = .idle
        name = ""
        street = ""
        city = ""
        province = ""
        postalCode = ""
        selectedCountry = nil
        existingAddressId = nil
    }
}
