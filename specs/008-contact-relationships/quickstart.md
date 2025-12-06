# Quickstart: Contact Relationships Management

## Overview

This feature enables users to create, view, edit, and delete relationships between contacts with bidirectional support. It builds on existing read-only relationship display to add full CRUD capabilities.

## Prerequisites

- Xcode 15+
- iOS 16+ Simulator or device
- Monica API access with valid credentials
- Familiarity with existing codebase patterns (DebtTracking, ConversationTracking)

## Key Files

### Existing (No Changes Required)
- `MonicaClient/Models/Contact.swift` - Relationship, RelationshipType, RelationshipTypeGroup models
- `MonicaClient/Services/MonicaAPIClient.swift` - All relationship API methods
- `MonicaClient/Features/ContactDetail/Views/RelationshipsSection.swift` - Read-only display

### New Files to Create
```
MonicaClient/Features/ContactRelationships/
├── Models/
│   └── RelationshipEnums.swift        # Category enum, gender mapping
├── Services/
│   └── RelationshipAPIService.swift   # Wrapper for MonicaAPIClient
├── ViewModels/
│   └── RelationshipViewModel.swift    # State management, validation
└── Views/
    ├── RelationshipFormView.swift     # Create/edit form
    ├── RelationshipListView.swift     # Full relationship list
    ├── RelationshipTypePicker.swift   # Grouped type selector
    └── ContactSearchView.swift        # Contact picker for relationships
```

### Files to Modify
- `ContactDetailView.swift` - Add relationship management integration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ContactDetailView                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              RelationshipsSection                       │ │
│  │  ┌──────────────────┐  ┌─────────────────────────────┐ │ │
│  │  │ + Add Button     │  │ RelationshipRowView (x N)   │ │ │
│  │  └────────┬─────────┘  │  - Swipe to delete          │ │ │
│  │           │            │  - Tap to navigate           │ │ │
│  └───────────┼────────────┴─────────────────────────────┘ │
└──────────────┼──────────────────────────────────────────────┘
               │
               ▼ Sheet
┌─────────────────────────────────────────────────────────────┐
│                   RelationshipFormView                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ContactSearchView        │ RelationshipTypePicker      │ │
│  │  - Search contacts       │  - Grouped by category      │ │
│  │  - Exclude self          │  - Show reverse preview     │ │
│  └──────────────────────────┴─────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                RelationshipViewModel                    │ │
│  │  - Cached relationship types                           │ │
│  │  - Gender-aware display names                          │ │
│  │  - Validation (duplicates, self-reference)             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Steps

### Phase 1: Setup & Models
1. Create directory structure under `Features/ContactRelationships/`
2. Create `RelationshipEnums.swift` with category enum and gender mapping

### Phase 2: Service & ViewModel
3. Create `RelationshipAPIService.swift` wrapping MonicaAPIClient
4. Create `RelationshipViewModel.swift` with:
   - Relationship type caching
   - Gender-aware display name resolution
   - Duplicate/self-relationship validation
   - CRUD operations

### Phase 3: Views
5. Create `ContactSearchView.swift` for selecting target contact
6. Create `RelationshipTypePicker.swift` with grouped categories
7. Create `RelationshipFormView.swift` combining picker and validation

### Phase 4: Integration
8. Update `RelationshipsSection.swift` to add "+" button
9. Add swipe-to-delete on relationship rows
10. Connect sheet presentation for form

## API Endpoints Used

| Operation | Endpoint | Method |
|-----------|----------|--------|
| List relationships | `/contacts/{id}/relationships` | GET |
| Create relationship | `/relationships` | POST |
| Update relationship | `/relationships/{id}` | PUT |
| Delete relationship | `/relationships/{id}` | DELETE |
| Get types | `/relationshiptypes` | GET |
| Get type groups | `/relationshiptypegroups` | GET |

## Validation Rules

1. **Self-relationship**: Block if `contactIs == ofContact`
2. **Duplicate**: Block if relationship with same type already exists between contacts
3. **Type selection**: Must select valid relationship type before save

## Gender Display Logic

```swift
func displayName(for gender: String?) -> String {
    switch (self.name, gender?.lowercased()) {
    case ("child", "male"): return "son"
    case ("child", "female"): return "daughter"
    case ("parent", "male"): return "father"
    case ("parent", "female"): return "mother"
    // ... etc
    default: return self.name
    }
}
```

## Testing Checklist

- [X] Create relationship from contact detail
- [X] Verify reverse relationship appears on target contact
- [X] Test duplicate prevention
- [X] Test self-relationship prevention
- [X] Verify gender-specific display names
- [X] Test delete removes both directions (verify API behavior)
- [X] Test navigation to related contact
- [X] Test type picker grouping by category
- [X] Test contact search excludes current contact

## Common Issues

### Reverse Relationship Not Showing
- Monica API should auto-create reverse; if not, check API version
- May need to refresh target contact's relationships

### Gender Display Incorrect
- Check contact's gender field is populated
- Verify gender mapping in RelationshipEnums

### Duplicate Error
- API may return 422; show user-friendly message
- Check both directions (A→B and B→A) for duplicates
