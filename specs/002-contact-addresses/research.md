# Research: Contact Addresses Management

**Feature**: 002-contact-addresses
**Date**: 2025-11-22

## Research Summary

This document captures technical research and decisions for implementing address management in the Monica iOS Client.

---

## 1. Monica API Address Endpoints

### Decision
Use Monica's RESTful address endpoints with standard CRUD operations.

### Findings

**Endpoint Structure** (based on Monica API v4.x patterns):

```
GET    /api/contacts/{contact_id}/addresses    # List addresses for contact
POST   /api/contacts/{contact_id}/addresses    # Create new address
GET    /api/addresses/{id}                     # Get single address
PUT    /api/addresses/{id}                     # Update address
DELETE /api/addresses/{id}                     # Delete address
```

**Address Response Structure** (inferred from Contact model):
```json
{
  "id": 123,
  "object": "address",
  "name": "Home",
  "street": "123 Main Street",
  "city": "San Francisco",
  "province": "California",
  "postal_code": "94102",
  "country": {
    "id": 1,
    "object": "country",
    "name": "United States",
    "iso": "US"
  },
  "latitude": 37.7749,
  "longitude": -122.4194,
  "contact": {
    "id": 456
  },
  "account": {
    "id": 1
  },
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Create/Update Request Body**:
```json
{
  "name": "Home",
  "street": "123 Main Street",
  "city": "San Francisco",
  "province": "California",
  "postal_code": "94102",
  "country_id": 1
}
```

### Rationale
Monica follows consistent REST patterns across all endpoints. Address structure mirrors other entities like contacts and notes.

### Alternatives Considered
- GraphQL: Not supported by Monica
- Batch operations: Not needed for MVP address management

---

## 2. Monica API Countries Endpoint

### Decision
Fetch countries from `/api/countries` and cache locally for form dropdowns.

### Findings

**Endpoint**:
```
GET /api/countries    # List all countries
```

**Country Response Structure**:
```json
{
  "data": [
    {
      "id": 1,
      "object": "country",
      "name": "United States",
      "iso": "US"
    },
    {
      "id": 2,
      "object": "country",
      "name": "Canada",
      "iso": "CA"
    }
  ]
}
```

### Rationale
Countries list is static and rarely changes. Cache with long TTL (24 hours) to minimize API calls.

### Caching Strategy
- Fetch on first address form open
- Store in UserDefaults as JSON
- Refresh every 24 hours or on pull-to-refresh
- Fallback to cached data if offline

---

## 3. MapKit Integration

### Decision
Use SwiftUI `Map` view for inline previews and `MKMapView` wrapped for full-screen interaction.

### Findings

**SwiftUI Map Component** (iOS 14+):
```swift
Map(coordinateRegion: $region, annotationItems: annotations) { item in
    MapMarker(coordinate: item.coordinate, tint: .red)
}
```

**Geocoding with CLGeocoder**:
```swift
let geocoder = CLGeocoder()
let placemarks = try await geocoder.geocodeAddressString(addressString)
if let location = placemarks.first?.location {
    // Use location.coordinate
}
```

**Opening Apple Maps for Directions**:
```swift
let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
mapItem.name = contactName
mapItem.openInMaps(launchOptions: [
    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
])
```

### Rationale
- SwiftUI `Map` is simpler for small previews
- MKMapView provides more control for full-screen interactions
- CLGeocoder handles addresses without coordinates
- MKMapItem provides native directions experience

### Alternatives Considered
- Google Maps SDK: Violates zero-dependency principle
- Web-based maps: Poor native experience
- MapBox: External dependency

---

## 4. Address Formatting

### Decision
Implement country-aware address formatting with localized field labels.

### Findings

**US Format**:
```
123 Main Street
San Francisco, CA 94102
United States
```

**UK Format**:
```
123 High Street
London SW1A 1AA
United Kingdom
```

**Japan Format**:
```
Japan
〒100-0001
Tokyo
Chiyoda-ku
1-1-1 Marunouchi
```

### Implementation Approach
```swift
struct AddressFormatter {
    static func format(_ address: Address) -> String {
        // Standard Western format as default
        var lines: [String] = []

        if let street = address.street, !street.isEmpty {
            lines.append(street)
        }

        var cityLine = ""
        if let city = address.city { cityLine += city }
        if let province = address.province { cityLine += ", \(province)" }
        if let postal = address.postalCode { cityLine += " \(postal)" }
        if !cityLine.isEmpty { lines.append(cityLine) }

        if let country = address.country?.name {
            lines.append(country)
        }

        return lines.joined(separator: "\n")
    }
}
```

### Field Label Localization
| Country | Postal Code Label | Province Label |
|---------|------------------|----------------|
| US | ZIP Code | State |
| UK | Postcode | County |
| CA | Postal Code | Province |
| AU | Postcode | State/Territory |
| Default | Postal Code | Province/State |

### Rationale
Start with Western format (covers most use cases). Full i18n address formatting is complex; defer to v3+ if needed.

---

## 5. Offline Support

### Decision
Cache addresses for offline viewing; queue write operations for sync when online.

### Findings

**Caching Strategy**:
- Store fetched addresses in memory cache (same as contacts)
- 5-minute TTL for fresh data
- Serve stale data immediately, refresh in background
- Country list cached in UserDefaults (24h TTL)

**Offline Writes** (Deferred):
- For MVP: Show error if offline during save
- Future: Queue operations in local store, sync when online

### Rationale
Read-heavy use case; most users will view addresses more than edit them. Complex offline sync deferred to avoid scope creep.

---

## 6. Error Handling

### Decision
Follow existing error handling patterns from MVP.

### Findings

**Error Cases**:
| Status | Meaning | User Message |
|--------|---------|--------------|
| 400 | Validation error | "Please check your address details" |
| 401 | Unauthorized | Auto-logout, prompt re-authentication |
| 404 | Not found | "This address no longer exists" |
| 429 | Rate limited | "Please wait a moment and try again" |
| 500 | Server error | "Unable to save. Please try again later" |

### Rationale
Consistent with existing MVP error handling. User-friendly messages without technical jargon.

---

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Map Framework | MapKit (SwiftUI Map + MKMapView) | Zero dependencies, native iOS |
| Geocoding | CLGeocoder | Built-in, no API key required |
| Address Format | Western default | Covers majority use cases |
| Offline | Cache reads, error on writes | MVP simplicity |
| Country Cache | UserDefaults, 24h TTL | Static data, minimize API calls |
