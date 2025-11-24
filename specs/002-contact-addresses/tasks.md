# Implementation Tasks: Contact Addresses Management

**Feature**: 002-contact-addresses
**Generated**: 2025-11-22
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 55 |
| User Stories | 6 |
| Parallel Tasks | 21 |
| Test Tasks | 3 |
| Estimated Complexity | Medium |

## User Story Mapping

| Story | Priority | Tasks | Description |
|-------|----------|-------|-------------|
| US1 | P1 | T010-T020 | View Contact Addresses |
| US2 | P2 | T021-T029 | Add New Address |
| US3 | P2 | T030-T036 | Edit and Delete Addresses |
| US4 | P3 | T037-T041 | Get Directions to Address |
| US5 | P3 | T042-T045 | Copy and Share Addresses |
| US6 | P3 | T046-T049 | View Address on Map |

---

## Phase 1: Setup & Foundation

**Purpose**: Project setup and shared models that all user stories depend on

- [X] T001 Create feature branch `002-contact-addresses` from main
- [X] T002 [P] Create Address model in MonicaClient/Models/Address.swift
- [X] T003 [P] Create Country model in MonicaClient/Models/Country.swift
- [X] T004 [P] Create AddressCreateRequest and AddressUpdateRequest in MonicaClient/Models/Address.swift
- [X] T005 [P] Create AddressResponse and AddressListResponse in MonicaClient/Models/Address.swift
- [X] T006 [P] Create CountryListResponse in MonicaClient/Models/Country.swift
- [X] T007 Add address CRUD methods to MonicaClient/Services/MonicaAPIClient.swift (fetchAddresses, createAddress, updateAddress, deleteAddress)
- [X] T008 Add fetchCountries method to MonicaClient/Services/MonicaAPIClient.swift
- [X] T009 Add address and country caching to MonicaClient/Services/Storage/CacheService.swift

---

## Phase 2: Foundational Infrastructure

**Purpose**: Shared utilities and view components needed by multiple user stories

- [X] T010 Create AddressFormatter utility in MonicaClient/Utilities/AddressFormatter.swift with format() method
- [X] T011 [P] Add Address computed properties (hasCoordinates, coordinate, formattedAddress, displayLabel, geocodableString) in MonicaClient/Models/Address.swift
- [X] T012 [P] Create AddressManagement feature directory structure: MonicaClient/Features/AddressManagement/ViewModels/ and MonicaClient/Features/AddressManagement/Views/

---

## Phase 3: User Story 1 - View Contact Addresses (P1)

**Goal**: Users can see all physical addresses associated with a contact in their contact detail view

**Independent Test**: Add address data through Monica backend and verify it displays correctly in iOS app's contact detail view

**Acceptance Criteria**:
1. Single home address displays with label and formatted text
2. Multiple addresses display in a list with distinct labels
3. Empty state shows with option to add first address
4. Map preview displays for addresses with coordinates

### Tasks

- [X] T013 [US1] Create AddressViewModel in MonicaClient/Features/AddressManagement/ViewModels/AddressViewModel.swift with loadAddresses(contactId:) method
- [X] T014 [US1] Add AddressViewState enum (loading, loaded, empty, error) to AddressViewModel
- [X] T015 [P] [US1] Create AddressRowView in MonicaClient/Features/AddressManagement/Views/AddressRowView.swift displaying label, formatted address, and map preview
- [X] T016 [P] [US1] Create AddressListView in MonicaClient/Features/AddressManagement/Views/AddressListView.swift with list of AddressRowView items
- [X] T017 [US1] Create AddressEmptyStateView in MonicaClient/Features/AddressManagement/Views/AddressEmptyStateView.swift with "Add Address" button
- [X] T018 [US1] Add small map preview to AddressRowView using SwiftUI Map component (only if hasCoordinates)
- [X] T019 [US1] Integrate AddressListView as section in MonicaClient/Views/ContactDetailView.swift
- [X] T020 [US1] Add address loading to ContactDetailViewModel.loadContactDetails() method

---

## Phase 4: User Story 2 - Add New Address (P2)

**Goal**: Users can add new addresses to a contact's profile

**Independent Test**: Add address to contact that had none, verify it appears in list

**Acceptance Criteria**:
1. Address entry form appears with all fields (street, city, province, postal code, country, label)
2. New address appears in list after save
3. Country picker shows searchable list
4. Label displays prominently with address

### Tasks

- [X] T021 [US2] Create AddressFormViewModel in MonicaClient/Features/AddressManagement/ViewModels/AddressFormViewModel.swift with form fields and save() method
- [X] T022 [US2] Add AddressFormState enum (idle, saving, success, error) to AddressFormViewModel
- [X] T023 [US2] Add loadCountries() method to AddressFormViewModel using cached country list
- [X] T024 [P] [US2] Create AddressFormView in MonicaClient/Features/AddressManagement/Views/AddressFormView.swift with all address fields
- [X] T025 [US2] Create searchable CountryPickerView in MonicaClient/Features/AddressManagement/Views/CountryPickerView.swift
- [X] T026 [US2] Add country-specific field label hints to AddressFormView (ZIP Code for US, Postcode for UK)
- [X] T027 [US2] Add validation to AddressFormViewModel (at least one field required before save)
- [X] T028 [US2] Add "Add Address" navigation from AddressListView to AddressFormView
- [X] T029 [US2] Refresh address list after successful save in AddressListView

---

## Phase 5: User Story 3 - Edit and Delete Addresses (P2)

**Goal**: Users can update or remove existing addresses

**Independent Test**: Modify existing address and verify changes persist, delete address and confirm removal

**Acceptance Criteria**:
1. Edit form pre-fills with current address data
2. Updated address displays with new information
3. Delete shows confirmation dialog
4. Deleted address removed from list

### Tasks

- [X] T030 [US3] Extend AddressFormViewModel to accept existing Address for edit mode
- [X] T031 [US3] Pre-populate AddressFormView fields when editing existing address
- [X] T032 [US3] Add updateAddress() method to AddressFormViewModel
- [X] T033 [US3] Add swipe-to-delete gesture to AddressRowView in AddressListView
- [X] T034 [US3] Create delete confirmation alert in AddressListView
- [X] T035 [US3] Add deleteAddress(id:) method to AddressViewModel
- [X] T036 [US3] Add edit button/navigation from AddressRowView to AddressFormView in edit mode

---

## Phase 6: User Story 4 - Get Directions to Address (P3)

**Goal**: Users can launch device's maps application with directions to address

**Independent Test**: Tap "Get Directions" and verify Apple Maps opens with correct destination

**Acceptance Criteria**:
1. Maps app opens with destination pre-set
2. System attempts geocoding if coordinates missing
3. Contact's name appears as destination label

### Tasks

- [X] T037 [US4] Create GeocodingService in MonicaClient/Services/GeocodingService.swift using CLGeocoder
- [X] T038 [US4] Add openDirections(to:contactName:) method to AddressViewModel using MKMapItem
- [X] T039 [US4] Add geocodeAddress() method to GeocodingService for addresses without coordinates
- [X] T040 [US4] Add "Get Directions" button to AddressRowView
- [X] T041 [US4] Handle case where geocoding fails with user-friendly error message

---

## Phase 7: User Story 5 - Copy and Share Addresses (P3)

**Goal**: Users can copy address text to clipboard or share via system share sheet

**Independent Test**: Copy address and paste elsewhere, share via share sheet

**Acceptance Criteria**:
1. Copy copies formatted address to clipboard
2. Share sheet appears with address as content
3. Recipient receives properly formatted address

### Tasks

- [X] T042 [P] [US5] Add copyToClipboard() method to AddressViewModel using UIPasteboard
- [X] T043 [P] [US5] Add "Copy" context menu action to AddressRowView
- [X] T044 [US5] Add shareAddress() method to AddressViewModel using UIActivityViewController
- [X] T045 [US5] Add "Share" context menu action to AddressRowView using iOS share sheet

---

## Phase 8: User Story 6 - View Address on Map (P3)

**Goal**: Users can see address on interactive full-screen map

**Independent Test**: Tap map preview to expand full map view, verify correct location

**Acceptance Criteria**:
1. Full-screen map appears centered on location
2. Pin marks exact address location
3. Map closes on tap elsewhere

### Tasks

- [X] T046 [US6] Create AddressMapView in MonicaClient/Features/AddressManagement/Views/AddressMapView.swift as full-screen map
- [X] T047 [US6] Add map annotation with pin at address coordinate
- [X] T048 [US6] Add tap gesture to AddressRowView map preview to present AddressMapView
- [X] T049 [US6] Add dismiss gesture/button to AddressMapView to return to contact detail

---

## Phase 9: Testing (Constitution Principle 7)

**Purpose**: Unit tests for ViewModels to meet 70% coverage requirement

- [ ] T050 [P] Create AddressViewModelTests in MonicaClientTests/AddressViewModelTests.swift with tests for loadAddresses, deleteAddress, error states
- [ ] T051 [P] Create AddressFormViewModelTests in MonicaClientTests/AddressFormViewModelTests.swift with tests for save, validation, country loading
- [ ] T052 [P] Create GeocodingServiceTests in MonicaClientTests/GeocodingServiceTests.swift with tests for geocoding success/failure

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T053 [P] Add offline support to AddressViewModel - serve cached addresses when offline
- [ ] T054 [P] Add error handling for all API operations in AddressViewModel and AddressFormViewModel
- [ ] T055 Update OpenAPI spec at docs/monica-api-openapi.yaml with address endpoints if API behavior differs from documentation

---

## Dependencies & Execution Order

```
Phase 1 (Setup) ──────────────────────────────────────────────────────────────►
        │
        ▼
Phase 2 (Foundation) ─────────────────────────────────────────────────────────►
        │
        ▼
Phase 3 (US1: View) ──────────────────────────────────────────────────────────►
        │
        ├─────────────────────────────────────────────────────────────────────►
        │
        ▼
Phase 4 (US2: Add) ──────────► Phase 5 (US3: Edit/Delete) ────────────────────►
                                        │
                                        ├─────────────────────────────────────►
                                        │
                                        ▼
                               Phase 6 (US4: Directions) ─────────────────────►
                                        │
                                        ├─────────────────────────────────────►
                                        │
                                        ▼
                               Phase 7 (US5: Copy/Share) ─────────────────────►
                                        │
                                        ▼
                               Phase 8 (US6: Full Map) ───────────────────────►
                                        │
                                        ▼
                               Phase 9 (Polish) ──────────────────────────────►
```

### Story Dependencies

| Story | Depends On | Can Start After |
|-------|------------|-----------------|
| US1 (View) | Phase 2 | Foundation complete |
| US2 (Add) | US1 | View addresses working |
| US3 (Edit/Delete) | US2 | Add addresses working |
| US4 (Directions) | US1 | View addresses working |
| US5 (Copy/Share) | US1 | View addresses working |
| US6 (Full Map) | US1 | View addresses working |

---

## Parallel Execution Opportunities

### Within Phase 1 (Setup)
```
T002 ──┬── T003 ──┬── T004 ──┬── T005 ──┬── T006
       │         │          │          │
       └─────────┴──────────┴──────────┘
                      │
                      ▼
              T007 ─► T008 ─► T009
```

### Within Phase 3 (US1)
```
T013 ─► T014 ─┬─► T015 (AddressRowView)
              │
              └─► T016 (AddressListView)
                      │
                      ▼
              T017 ─► T018 ─► T019 ─► T020
```

### Within Phase 4 (US2)
```
T021 ─► T022 ─► T023 ─┬─► T024 (AddressFormView)
                      │
                      └─► T025 (CountryPickerView)
                              │
                              ▼
                      T026 ─► T027 ─► T028 ─► T029
```

### Within Phase 7 (US5)
```
T042 (Copy) ────┬────► T043 (Copy Menu)
                │
T044 (Share) ───┴────► T045 (Share Menu)
```

---

## Implementation Strategy

### MVP Scope (Recommended)

**Minimum Viable Product**: Complete US1 (View) + US2 (Add) only

This delivers:
- ✅ View all addresses for a contact
- ✅ Add new addresses with form
- ✅ Country picker with searchable list
- ✅ Basic map preview for addresses with coordinates

**MVP Task Range**: T001-T029 (29 tasks)

### Incremental Delivery

1. **Increment 1**: US1 (View) - 11 tasks - Basic address display
2. **Increment 2**: US2 (Add) - 9 tasks - Create new addresses
3. **Increment 3**: US3 (Edit/Delete) - 7 tasks - Full CRUD
4. **Increment 4**: US4-US6 - 13 tasks - Enhanced features
5. **Increment 5**: Testing + Polish - 6 tasks - Tests and cross-cutting

### File Creation Summary

| New Files | Path |
|-----------|------|
| Address.swift | MonicaClient/Models/Address.swift |
| Country.swift | MonicaClient/Models/Country.swift |
| AddressFormatter.swift | MonicaClient/Utilities/AddressFormatter.swift |
| AddressViewModel.swift | MonicaClient/Features/AddressManagement/ViewModels/AddressViewModel.swift |
| AddressFormViewModel.swift | MonicaClient/Features/AddressManagement/ViewModels/AddressFormViewModel.swift |
| AddressListView.swift | MonicaClient/Features/AddressManagement/Views/AddressListView.swift |
| AddressRowView.swift | MonicaClient/Features/AddressManagement/Views/AddressRowView.swift |
| AddressFormView.swift | MonicaClient/Features/AddressManagement/Views/AddressFormView.swift |
| AddressEmptyStateView.swift | MonicaClient/Features/AddressManagement/Views/AddressEmptyStateView.swift |
| AddressMapView.swift | MonicaClient/Features/AddressManagement/Views/AddressMapView.swift |
| CountryPickerView.swift | MonicaClient/Features/AddressManagement/Views/CountryPickerView.swift |
| GeocodingService.swift | MonicaClient/Services/GeocodingService.swift |
| AddressViewModelTests.swift | MonicaClientTests/AddressViewModelTests.swift |
| AddressFormViewModelTests.swift | MonicaClientTests/AddressFormViewModelTests.swift |
| GeocodingServiceTests.swift | MonicaClientTests/GeocodingServiceTests.swift |

| Modified Files | Path |
|----------------|------|
| MonicaAPIClient.swift | MonicaClient/Services/MonicaAPIClient.swift |
| CacheService.swift | MonicaClient/Services/Storage/CacheService.swift |
| ContactDetailView.swift | MonicaClient/Views/ContactDetailView.swift |
| monica-api-openapi.yaml | docs/monica-api-openapi.yaml |
