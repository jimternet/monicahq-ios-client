# Feature Request: Contact Addresses Management

## Overview
Store and manage multiple addresses for contacts - home, work, vacation home, etc. with map integration.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/addresses` - List all addresses
- `GET /api/addresses/{id}` - Get single address
- `POST /api/addresses` - Create address
- `PUT /api/addresses/{id}` - Update address
- `DELETE /api/addresses/{id}` - Delete address
- `GET /api/contacts/{contact}/addresses` - Get addresses for specific contact
- `GET /api/places` - List all places (locations)
- `GET /api/countries` - List all countries

## Proposed Models

```swift
struct Address: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let placeId: Int?
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let countryId: Int?
    let name: String? // "Home", "Work", etc.
    let place: Place?
    let country: Country?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case placeId = "place_id"
        case street
        case city
        case province
        case postalCode = "postal_code"
        case countryId = "country_id"
        case name
        case place
        case country
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var formattedAddress: String {
        var parts: [String] = []
        if let street = street, !street.isEmpty { parts.append(street) }
        if let city = city, !city.isEmpty { parts.append(city) }
        if let province = province, !province.isEmpty { parts.append(province) }
        if let postalCode = postalCode, !postalCode.isEmpty { parts.append(postalCode) }
        if let country = country { parts.append(country.name) }
        return parts.joined(separator: ", ")
    }

    var singleLineAddress: String {
        var parts: [String] = []
        if let street = street { parts.append(street) }
        if let city = city { parts.append(city) }
        return parts.joined(separator: ", ")
    }
}

struct Place: Codable, Identifiable {
    let id: Int
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let countryId: Int?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case street
        case city
        case province
        case postalCode = "postal_code"
        case countryId = "country_id"
        case latitude
        case longitude
    }
}

struct Country: Codable, Identifiable {
    let id: Int
    let iso: String
    let name: String
}

struct AddressCreatePayload: Codable {
    let contactId: Int
    let street: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let countryId: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case street
        case city
        case province
        case postalCode = "postal_code"
        case countryId = "country_id"
        case name
    }
}
```

## UI Components Needed

### 1. ContactAddressesSection
- Show on contact detail page
- List of addresses with labels
- Map preview for each (optional)
- Add address button
- Edit/delete actions

### 2. AddressListItem
- Address label (Home, Work, etc.)
- Formatted address display
- Tap to view on map
- Quick copy address
- Get directions button

### 3. AddEditAddressView
- Label selector/input (Home, Work, Custom)
- Street address field
- City field
- State/Province field
- Postal code field
- Country picker
- Map pin placement (optional)

### 4. AddressMapView
- Show address on map
- Get directions button
- Share location
- Copy to clipboard
- Open in Maps app

### 5. CountryPicker
- Searchable list of countries
- Grouped by continent or alphabetical
- Flags (optional)

## Implementation Priority
**MEDIUM** - Important for complete contact information but basic data already in notes

## Key Features
1. Multiple addresses per contact
2. Address labels (Home, Work, Other)
3. Full address components
4. Map integration
5. Get directions
6. Copy address to clipboard
7. Share address

## iOS Integration
- MapKit for map display
- Core Location for geocoding
- Apple Maps for directions
- Address autocomplete via MKLocalSearchCompleter
- Share sheet for address sharing

## Map Integration Code
```swift
import MapKit

struct AddressMapView: View {
    let address: Address

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [address]) { addr in
            MapMarker(coordinate: coordinate, tint: .red)
        }
        .frame(height: 200)
        .cornerRadius(12)
        .onTapGesture {
            openInMaps()
        }
    }

    var coordinate: CLLocationCoordinate2D {
        // Geocode address or use stored coordinates
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = address.name ?? "Contact Address"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}
```

## Visual Design
- Address cards with map previews
- Clear labels (Home icon, Work icon)
- Action buttons (Directions, Copy, Share)
- Inline map previews
- Expandable for full details

## Use Cases
- Navigate to contact's home
- Send physical mail
- Know where they work
- Multiple locations (vacation home)
- International contacts
- Plan visits

## Advanced Features (Future)
- Address autocomplete while typing
- Geocoding to get coordinates
- Distance calculation ("2.5 miles away")
- Travel time estimates
- Nearby contacts grouping
- Address history tracking

## Related Files
- Contact.swift - Add `addresses: [Address]?` field
- MonicaAPIClient.swift - Add address CRUD + countries fetch
- ContactDetailView.swift - Add addresses section
- New models for Address, Place, Country
- MapKit integration utilities

## Notes
- Cache countries list locally
- Consider address validation
- Handle international address formats
- Map requires internet connection
- Respect location privacy
- Consider offline address storage
