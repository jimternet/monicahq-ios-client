# Implementation Plan: Contact Addresses Management

**Branch**: `002-contact-addresses` | **Date**: 2025-11-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-contact-addresses/spec.md`

## Summary

Implement full CRUD operations for contact addresses in the Monica iOS Client, extending the existing read-only MVP with write capabilities. This feature enables users to view, add, edit, and delete physical addresses for contacts, with map integration for visualization and navigation.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await support
**Primary Dependencies**: SwiftUI, URLSession, Foundation, Security (Keychain), MapKit
**Storage**: Keychain for API tokens, UserDefaults for non-sensitive settings, In-memory cache for address data
**Testing**: XCTest with minimum 70% coverage for ViewModels and API logic
**Target Platform**: iOS 15+ (iPhone 12 and newer as primary target)
**Project Type**: Mobile iOS application
**Performance Goals**: Address list loads <2 seconds, address save <3 seconds, 60fps scrolling
**Constraints**: Offline viewing of cached addresses, <500ms search response, graceful degradation without coordinates
**Scale/Scope**: Support 100+ countries, unlimited addresses per contact

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| 1. Privacy & Security First | ✅ PASS | All data via HTTPS to Monica API, no third-party sharing, minimal local storage |
| 2. Read-Only Simplicity (MVP Phase) | ✅ PASS | This is a v2.0 feature - write operations are explicitly planned for post-MVP |
| 3. Native iOS Experience | ✅ PASS | SwiftUI with MapKit, iOS share sheet for address sharing, follows HIG |
| 4. Clean Architecture | ✅ PASS | MVVM pattern, separate API/data/UI layers, protocol-based DI |
| 5. API-First Design | ✅ PASS | Uses Monica `/api/addresses` and `/api/countries` endpoints |
| 6. Performance & Responsiveness | ✅ PASS | Lazy loading, caching, async operations |
| 7. Testing Standards | ✅ PASS | XCTest for ViewModels and API layer, manual device testing |
| 8. Code Quality | ✅ PASS | Swift style guide, Result types, no force unwraps |
| 9. Documentation | ✅ PASS | This plan, data-model.md, API contracts |
| 10. Decision-Making | ✅ PASS | Simplicity prioritized, user experience first |
| 11. API Documentation Accuracy | ✅ PASS | Will update OpenAPI spec with address endpoint discoveries |

**Gate Status**: ✅ PASSED - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/002-contact-addresses/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── addresses-api.md # Address CRUD API contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
MonicaClient/
├── Models/
│   ├── Address.swift           # NEW: Address entity model
│   └── Country.swift           # NEW: Country entity model
├── Features/
│   └── AddressManagement/      # NEW: Address feature module
│       ├── ViewModels/
│       │   └── AddressViewModel.swift
│       └── Views/
│           ├── AddressListView.swift
│           ├── AddressFormView.swift
│           ├── AddressRowView.swift
│           └── AddressMapView.swift
├── Services/
│   ├── API/
│   │   └── MonicaAPIClient.swift  # EXTEND: Add address/country endpoints
│   └── Storage/
│       └── CacheService.swift     # EXTEND: Add address/country caching
├── Utilities/
│   └── AddressFormatter.swift  # NEW: Country-specific address formatting
└── Views/
    └── ContactDetailView.swift # EXTEND: Integrate address section

MonicaClientTests/
├── AddressViewModelTests.swift  # NEW: Unit tests for address logic
└── AddressAPITests.swift        # NEW: Integration tests for API
```

**Structure Decision**: Follows existing MVVM feature module pattern from MVP. Address management added as a new feature module under `Features/AddressManagement/` with corresponding models, services extensions, and tests.

## Complexity Tracking

No constitution violations to justify.

---

## Phase 0: Research

### Research Tasks

1. **Monica API Address Endpoints**
   - Investigate `/api/addresses` endpoint structure
   - Verify `/api/contacts/{id}/addresses` endpoint
   - Document CRUD operations (POST, PUT, DELETE)
   - Identify required vs optional fields

2. **Monica API Countries Endpoint**
   - Investigate `/api/countries` endpoint
   - Document country data structure (id, name, ISO code)
   - Verify caching requirements

3. **MapKit Integration**
   - Research MKMapView vs Map SwiftUI component
   - Geocoding with CLGeocoder
   - Opening Apple Maps for directions

4. **Address Formatting**
   - Research international address format variations
   - Country-specific field labels (ZIP vs Postal Code)

**Output**: See [research.md](./research.md)

---

## Phase 1: Design & Contracts

### Data Model Summary

See [data-model.md](./data-model.md) for complete entity definitions.

**Key Entities**:
- `Address`: id, street, city, province, postal_code, country, name (label), latitude, longitude, contact_id
- `Country`: id, name, iso_code
- `Place`: street, city, province, postal_code, latitude, longitude

### API Contracts

See [contracts/addresses-api.md](./contracts/addresses-api.md) for complete API specifications.

**Endpoints**:
- `GET /api/contacts/{contact_id}/addresses` - List contact addresses
- `POST /api/contacts/{contact_id}/addresses` - Create address
- `GET /api/addresses/{id}` - Get single address
- `PUT /api/addresses/{id}` - Update address
- `DELETE /api/addresses/{id}` - Delete address
- `GET /api/countries` - List all countries

### Integration Scenarios

See [quickstart.md](./quickstart.md) for integration test scenarios.

---

## Phase 2: Implementation

*Generated by `/speckit.tasks` command - see [tasks.md](./tasks.md)*

### Estimated Phases

1. **Setup & Foundation** - Models, API extensions
2. **Core Address Display** - List view, detail integration
3. **Address CRUD** - Add, edit, delete operations
4. **Map Integration** - MapKit views, geocoding, directions
5. **Polish** - Sharing, copying, offline support, tests
