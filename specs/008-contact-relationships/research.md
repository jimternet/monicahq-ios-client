# Research: Contact Relationships Management

## API Verification

### Existing Implementation Status

The Monica iOS client already has comprehensive relationship API support:

**Models (Contact.swift)**:
- `Relationship` struct with id, uuid, contactIs, relationshipType, ofContact, timestamps
- `RelationshipType` struct with id, name, nameReverseRelationship, relationshipTypeGroupId
- `RelationshipTypeGroup` struct with id, name, delible
- `RelatedContact` struct for contact references within relationships
- All payload/response types defined

**API Methods (MonicaAPIClient.swift)**:
- `fetchContactRelationships(contactId:)` - GET /contacts/{id}/relationships
- `fetchRelationshipTypes()` - GET /relationshiptypes (paginated)
- `fetchRelationshipTypeGroups()` - GET /relationshiptypegroups
- `createRelationship(contactIs:ofContact:relationshipTypeId:)` - POST /relationships
- `updateRelationship(relationshipId:relationshipTypeId:)` - PUT /relationships/{id}
- `deleteRelationship(relationshipId:)` - DELETE /relationships/{id}

**Existing UI (RelationshipsSection.swift)**:
- Read-only display of relationships grouped by type
- Navigation to related contacts
- Color-coded by relationship category
- Empty state handling

### API Endpoint Details

#### Create Relationship
```
POST /api/relationships
Body: {
  "contact_is": 123,        // Source contact ID
  "relationship_type_id": 1, // Type of relationship
  "of_contact": 456         // Target contact ID
}
Response: { "data": Relationship }
```

**Key Finding**: Monica API automatically creates the reverse relationship when creating one direction. No need for iOS app to create both sides.

#### Update Relationship
```
PUT /api/relationships/{id}
Body: {
  "relationship_type_id": 2  // New relationship type
}
Response: { "data": Relationship }
```

#### Delete Relationship
```
DELETE /api/relationships/{id}
Response: 204 No Content (or deleted confirmation)
```

**Key Finding**: Deleting one side of a bidirectional relationship may not automatically delete the reverse. Need to verify behavior and potentially delete both.

### Relationship Type Structure

From existing codebase analysis:
```swift
struct RelationshipType {
    let id: Int
    let name: String                    // e.g., "father"
    let nameReverseRelationship: String // e.g., "child"
    let relationshipTypeGroupId: Int    // Links to group (Family, Love, etc.)
}
```

**Key Finding**: The `nameReverseRelationship` is a generic reverse (e.g., "child"), not gender-specific (not "son" or "daughter"). Gender-specific display must be handled client-side based on contact's gender field.

### Gender-Based Reverse Relationship Mapping

Based on clarifications and API structure, the iOS app needs to:
1. Use contact's `gender` field to determine gendered display
2. Map generic reverse names to gendered variants:
   - "child" → "son" (male), "daughter" (female), "child" (unknown)
   - "parent" → "father" (male), "mother" (female), "parent" (unknown)
   - "sibling" → "brother" (male), "sister" (female), "sibling" (unknown)

### Contact Search for Relationship Creation

Existing contact search can be leveraged:
- `fetchContacts()` with search parameter already exists
- Need to exclude current contact from search results (self-relationship prevention)
- Need to check for existing relationships to prevent duplicates

## Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Use existing MonicaAPIClient methods | Already implemented and tested | Creating separate service (rejected: duplication) |
| Client-side gender mapping for display | API returns generic reverse names | Server-side change (rejected: not feasible) |
| Feature module under Features/ContactRelationships | Consistent with DebtTracking pattern | Inline in Views (rejected: poor organization) |
| Cache relationship types in ViewModel | Types rarely change, improves UX | Fetch every time (rejected: slow) |
| Integrate in existing RelationshipsSection | Add button in section header | Separate management screen (rejected: more navigation) |

## Open Questions Resolved

1. **Bidirectional creation**: API handles automatically ✅
2. **Gender-specific reverse names**: Client-side mapping needed ✅
3. **Duplicate prevention**: Client-side validation before API call ✅
4. **Self-relationship**: Client-side validation, API may also reject ✅

## Implementation Notes

1. **RelationshipViewModel** should:
   - Load and cache relationship types on init
   - Group types by relationshipTypeGroupId
   - Provide gender-aware display name resolution
   - Handle create/update/delete operations
   - Validate against duplicates and self-relationships

2. **RelationshipFormView** should:
   - Contact picker (search existing contacts)
   - Relationship type picker (grouped by category)
   - Show preview of reverse relationship
   - Validate before submission

3. **Integration Points**:
   - Add "+" button to existing RelationshipsSection header
   - Sheet presentation for form
   - Swipe-to-delete on existing RelationshipRowView
   - Edit via long-press or detail view
