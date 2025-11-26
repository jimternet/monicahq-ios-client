# Data Model: Contact Addresses Management

**Feature**: 002-contact-addresses
**Date**: 2025-11-22

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│     Contact     │       │     Country     │
├─────────────────┤       ├─────────────────┤
│ id: Int         │       │ id: Int         │
│ first_name      │       │ name: String    │
│ last_name       │       │ iso: String     │
│ ...             │       └────────┬────────┘
└────────┬────────┘                │
         │                         │
         │ 1:N                     │ 1:N
         │                         │
         ▼                         │
┌─────────────────┐                │
│     Address     │◄───────────────┘
├─────────────────┤
│ id: Int         │
│ name: String?   │ (label: Home, Work, etc.)
│ street: String? │
│ city: String?   │
│ province: String?│
│ postal_code: String? │
│ country_id: Int │
│ latitude: Double? │
│ longitude: Double? │
│ contact_id: Int │
│ created_at: Date│
│ updated_at: Date│
└─────────────────┘
```

---

## Entity Definitions

### Address

Represents a physical location associated with a contact.

```swift
struct Address: Codable, Identifiable, Hashable {
    let id: Int
    let object: String  // "address"
    let name: String?   // Label (Home, Work, Custom)
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
```

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | Int | Yes | Unique identifier |
| object | String | Yes | Always "address" |
| name | String? | No | Label (Home, Work, Other, or custom) |
| street | String? | No | Street address including number |
| city | String? | No | City or town name |
| province | String? | No | State, province, region, or county |
| postalCode | String? | No | ZIP code, postal code, postcode |
| country | Country? | No | Associated country object |
| latitude | Double? | No | Geographic latitude (-90 to 90) |
| longitude | Double? | No | Geographic longitude (-180 to 180) |
| contact | ContactRef | No | Parent contact reference |
| account | AccountRef | No | Parent account reference |
| createdAt | Date? | No | Creation timestamp |
| updatedAt | Date? | No | Last update timestamp |

**Validation Rules**:
- At least one field (street, city, or country) must be provided
- latitude must be between -90 and 90
- longitude must be between -180 and 180
- country_id must reference a valid country

---

### Country

Represents a nation from a standardized list.

```swift
struct Country: Codable, Identifiable, Hashable {
    let id: Int
    let object: String  // "country"
    let name: String
    let iso: String     // ISO 3166-1 alpha-2 code

    enum CodingKeys: String, CodingKey {
        case id, object, name, iso
    }
}
```

**Field Descriptions**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | Int | Yes | Unique identifier |
| object | String | Yes | Always "country" |
| name | String | Yes | Country name in English |
| iso | String | Yes | ISO 3166-1 alpha-2 code (e.g., "US", "GB") |

---

### Supporting Types

#### AddressCreateRequest

Request body for creating a new address.

```swift
struct AddressCreateRequest: Codable {
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let countryId: Int?

    enum CodingKeys: String, CodingKey {
        case name, street, city, province
        case postalCode = "postal_code"
        case countryId = "country_id"
    }
}
```

#### AddressUpdateRequest

Request body for updating an existing address.

```swift
struct AddressUpdateRequest: Codable {
    let name: String?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let countryId: Int?

    enum CodingKeys: String, CodingKey {
        case name, street, city, province
        case postalCode = "postal_code"
        case countryId = "country_id"
    }
}
```

#### ContactReference

Lightweight reference to parent contact.

```swift
struct ContactReference: Codable, Hashable {
    let id: Int
}
```

#### AccountReference

Lightweight reference to parent account.

```swift
struct AccountReference: Codable, Hashable {
    let id: Int
}
```

---

## Computed Properties

### Address Extensions

```swift
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
```

---

## State Transitions

### Address Lifecycle

```
┌─────────┐    Create    ┌─────────┐
│  None   │─────────────▶│  Saved  │
└─────────┘              └────┬────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
              ┌─────────┐         ┌─────────┐
              │  Edit   │         │ Delete  │
              └────┬────┘         └────┬────┘
                   │                   │
                   │ Save              │ Confirm
                   ▼                   ▼
              ┌─────────┐         ┌─────────┐
              │  Saved  │         │ Deleted │
              └─────────┘         └─────────┘
```

### ViewModel States

```swift
enum AddressViewState {
    case loading
    case loaded([Address])
    case empty
    case error(String)
}

enum AddressFormState {
    case idle
    case saving
    case success
    case error(String)
}
```

---

## Caching Strategy

### In-Memory Cache

```swift
// Address cache keyed by contact ID
private var addressCache: [Int: CacheEntry<[Address]>] = [:]

struct CacheEntry<T> {
    let data: T
    let timestamp: Date
    let ttl: TimeInterval = 300 // 5 minutes

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}
```

### UserDefaults Cache (Countries)

```swift
// Countries cached in UserDefaults
private let countriesCacheKey = "cached_countries"
private let countriesCacheDateKey = "cached_countries_date"
private let countriesTTL: TimeInterval = 86400 // 24 hours
```

---

## API Response Wrappers

### Single Address Response

```swift
struct AddressResponse: Codable {
    let data: Address
}
```

### Address List Response

```swift
struct AddressListResponse: Codable {
    let data: [Address]
    let links: PaginationLinks?
    let meta: PaginationMeta?
}
```

### Country List Response

```swift
struct CountryListResponse: Codable {
    let data: [Country]
}
```
