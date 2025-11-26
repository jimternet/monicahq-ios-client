# Quickstart: Contact Addresses Management

**Feature**: 002-contact-addresses
**Date**: 2025-11-22

## Overview

This guide provides integration scenarios and test patterns for the Contact Addresses Management feature.

---

## Prerequisites

- Monica iOS Client MVP running
- Valid Monica API token
- Monica instance with existing contacts
- iOS 15+ simulator or device

---

## Integration Scenarios

### Scenario 1: View Contact Addresses

**Given**: A contact exists with addresses in Monica
**When**: User navigates to contact detail view
**Then**: Addresses section displays with all addresses

```swift
// Test: ContactDetailView loads addresses
func testContactAddressesDisplay() async throws {
    // Arrange
    let contact = Contact(id: 123, firstName: "John", lastName: "Doe")
    let addresses = [
        Address(id: 1, name: "Home", city: "San Francisco"),
        Address(id: 2, name: "Work", city: "New York")
    ]
    mockAPI.setAddresses(for: contact.id, addresses)

    // Act
    let viewModel = ContactDetailViewModel(contact: contact, api: mockAPI)
    await viewModel.loadAddresses()

    // Assert
    XCTAssertEqual(viewModel.addresses.count, 2)
    XCTAssertEqual(viewModel.addresses[0].displayLabel, "Home")
}
```

### Scenario 2: Add New Address

**Given**: User is viewing a contact
**When**: User taps "Add Address" and fills form
**Then**: New address is created and appears in list

```swift
// Test: AddressFormView creates new address
func testCreateAddress() async throws {
    // Arrange
    let contactId = 123
    let newAddress = AddressCreateRequest(
        name: "Home",
        street: "123 Main St",
        city: "San Francisco",
        province: "CA",
        postalCode: "94102",
        countryId: 1
    )

    // Act
    let viewModel = AddressFormViewModel(contactId: contactId, api: mockAPI)
    viewModel.name = "Home"
    viewModel.street = "123 Main St"
    viewModel.city = "San Francisco"
    viewModel.province = "CA"
    viewModel.postalCode = "94102"
    viewModel.selectedCountry = Country(id: 1, name: "United States", iso: "US")

    await viewModel.save()

    // Assert
    XCTAssertTrue(viewModel.saveSuccessful)
    XCTAssertNil(viewModel.errorMessage)
}
```

### Scenario 3: Edit Existing Address

**Given**: A contact has an existing address
**When**: User taps edit and modifies fields
**Then**: Changes are saved and displayed

```swift
// Test: AddressFormView updates existing address
func testUpdateAddress() async throws {
    // Arrange
    let existingAddress = Address(
        id: 1,
        name: "Home",
        city: "San Francisco"
    )

    // Act
    let viewModel = AddressFormViewModel(
        contactId: 123,
        existingAddress: existingAddress,
        api: mockAPI
    )
    viewModel.city = "Los Angeles"
    await viewModel.save()

    // Assert
    XCTAssertTrue(viewModel.saveSuccessful)
    XCTAssertEqual(mockAPI.lastUpdatedAddress?.city, "Los Angeles")
}
```

### Scenario 4: Delete Address

**Given**: A contact has an address
**When**: User swipes to delete and confirms
**Then**: Address is removed from list

```swift
// Test: Address deletion
func testDeleteAddress() async throws {
    // Arrange
    let contactId = 123
    let addressId = 1
    mockAPI.setAddresses(for: contactId, [
        Address(id: addressId, name: "Home", city: "SF")
    ])

    // Act
    let viewModel = ContactDetailViewModel(contact: Contact(id: contactId), api: mockAPI)
    await viewModel.loadAddresses()
    await viewModel.deleteAddress(id: addressId)

    // Assert
    XCTAssertTrue(viewModel.addresses.isEmpty)
}
```

### Scenario 5: Get Directions

**Given**: An address has valid coordinates
**When**: User taps "Get Directions"
**Then**: Apple Maps opens with destination

```swift
// Test: Directions launches maps
func testGetDirections() {
    // Arrange
    let address = Address(
        id: 1,
        name: "Office",
        street: "1 Infinite Loop",
        city: "Cupertino",
        latitude: 37.3318,
        longitude: -122.0312,
        country: Country(id: 1, name: "United States", iso: "US")
    )

    // Act
    let canOpenMaps = address.hasCoordinates

    // Assert
    XCTAssertTrue(canOpenMaps)
    XCTAssertNotNil(address.coordinate)
}
```

### Scenario 6: Copy Address

**Given**: An address is displayed
**When**: User taps "Copy"
**Then**: Formatted address is copied to clipboard

```swift
// Test: Address copy to clipboard
func testCopyAddress() {
    // Arrange
    let address = Address(
        id: 1,
        street: "123 Main St",
        city: "San Francisco",
        province: "CA",
        postalCode: "94102",
        country: Country(id: 1, name: "United States", iso: "US")
    )

    // Act
    let formattedAddress = address.formattedAddress

    // Assert
    XCTAssertTrue(formattedAddress.contains("123 Main St"))
    XCTAssertTrue(formattedAddress.contains("San Francisco"))
    XCTAssertTrue(formattedAddress.contains("United States"))
}
```

---

## Mock API Setup

```swift
class MockMonicaAPIClient: MonicaAPIClientProtocol {
    private var addresses: [Int: [Address]] = [:]
    private var countries: [Country] = []
    var lastCreatedAddress: AddressCreateRequest?
    var lastUpdatedAddress: AddressUpdateRequest?

    func setAddresses(for contactId: Int, _ addresses: [Address]) {
        self.addresses[contactId] = addresses
    }

    func setCountries(_ countries: [Country]) {
        self.countries = countries
    }

    func fetchAddresses(contactId: Int) async throws -> [Address] {
        return addresses[contactId] ?? []
    }

    func createAddress(contactId: Int, _ request: AddressCreateRequest) async throws -> Address {
        lastCreatedAddress = request
        return Address(
            id: Int.random(in: 1000...9999),
            name: request.name,
            street: request.street,
            city: request.city,
            province: request.province,
            postalCode: request.postalCode
        )
    }

    func updateAddress(id: Int, _ request: AddressUpdateRequest) async throws -> Address {
        lastUpdatedAddress = request
        return Address(id: id, name: request.name, city: request.city)
    }

    func deleteAddress(id: Int) async throws {
        // Remove from all contacts
        for (contactId, addrs) in addresses {
            addresses[contactId] = addrs.filter { $0.id != id }
        }
    }

    func fetchCountries() async throws -> [Country] {
        if countries.isEmpty {
            return [
                Country(id: 1, object: "country", name: "United States", iso: "US"),
                Country(id: 2, object: "country", name: "Canada", iso: "CA"),
                Country(id: 3, object: "country", name: "United Kingdom", iso: "GB")
            ]
        }
        return countries
    }
}
```

---

## UI Integration Points

### ContactDetailView Extension

```swift
// In ContactDetailView.swift
struct ContactDetailView: View {
    @StateObject var viewModel: ContactDetailViewModel

    var body: some View {
        List {
            // ... existing sections ...

            // NEW: Addresses Section
            Section("Addresses") {
                if viewModel.addresses.isEmpty {
                    AddressEmptyStateView(onAdd: viewModel.showAddAddress)
                } else {
                    ForEach(viewModel.addresses) { address in
                        AddressRowView(
                            address: address,
                            onTap: { viewModel.showAddressDetail(address) },
                            onDirections: { viewModel.openDirections(to: address) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddressForm) {
            AddressFormView(viewModel: AddressFormViewModel(
                contactId: viewModel.contact.id,
                api: viewModel.api
            ))
        }
    }
}
```

### Navigation Flow

```
ContactListView
    └── ContactDetailView
            ├── AddressRowView (tap) → AddressFormView (edit mode)
            ├── AddressRowView (swipe) → Delete confirmation
            ├── AddressRowView (directions) → Apple Maps
            ├── AddressRowView (map preview) → AddressMapView
            └── "Add Address" → AddressFormView (create mode)
```

---

## Error Handling Patterns

```swift
// ViewModel error handling
@MainActor
class AddressFormViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    func save() async {
        isLoading = true
        errorMessage = nil

        do {
            if let existing = existingAddress {
                try await api.updateAddress(id: existing.id, buildRequest())
            } else {
                try await api.createAddress(contactId: contactId, buildRequest())
            }
            saveSuccessful = true
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Session expired. Please log in again."
            case .validationFailed(let message):
                errorMessage = message
            case .networkError:
                errorMessage = "No internet connection. Please try again."
            default:
                errorMessage = "Unable to save address. Please try again."
            }
        } catch {
            errorMessage = "An unexpected error occurred."
        }

        isLoading = false
    }
}
```

---

## Performance Considerations

1. **Lazy loading**: Only fetch addresses when section is visible
2. **Caching**: Cache addresses with 5-minute TTL
3. **Countries cache**: Store in UserDefaults with 24-hour TTL
4. **Map previews**: Load only for visible cells
5. **Geocoding**: Batch geocode requests, cache results
