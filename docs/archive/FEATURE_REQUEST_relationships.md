# Feature Request: Relationships Management

## Overview
Define and track relationships between contacts - family members, friends, coworkers, etc. with bidirectional relationship support.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/relationships/{id}` - Get single relationship
- `POST /api/relationships` - Create relationship
- `PUT /api/relationships/{id}` - Update relationship
- `DELETE /api/relationships/{id}` - Delete relationship
- `GET /api/contacts/{contact}/relationships` - Get all relationships for a contact
- `GET /api/relationshiptypegroups` - List relationship type groups (e.g., Family, Love)
- `GET /api/relationshiptypes` - List relationship types (e.g., Father, Mother, Partner)

## Proposed Models

```swift
struct Relationship: Codable, Identifiable {
    let id: Int
    let contactIs: Contact
    let ofContact: Contact
    let relationshipType: RelationshipType
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactIs = "contact_is"
        case ofContact = "of_contact"
        case relationshipType = "relationship_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RelationshipType: Codable, Identifiable {
    let id: Int
    let name: String
    let nameReverseRelationship: String?
    let relationshipTypeGroupId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameReverseRelationship = "name_reverse_relationship"
        case relationshipTypeGroupId = "relationship_type_group_id"
    }
}

struct RelationshipTypeGroup: Codable, Identifiable {
    let id: Int
    let name: String // e.g., "Family", "Love", "Friend", "Work"
    let delible: Bool
}

struct RelationshipCreatePayload: Codable {
    let contactId: Int // ID of the "other" contact
    let relationshipTypeId: Int

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_is"
        case relationshipTypeId = "relationship_type_id"
    }
}
```

## UI Components Needed

### 1. ContactRelationshipsSection
- Show on contact detail page as expandable section
- Group relationships by type (Family, Love, Friends, Work)
- Visual tree/graph of relationships
- Tap to navigate to related contact
- Add relationship button

### 2. AddRelationshipView
- Search/select existing contact
- OR create new contact inline
- Select relationship type from grouped picker
- Preview reverse relationship ("John is father of" → "Contact is child of John")

### 3. RelationshipTypesPicker
- Grouped list: Family → (Father, Mother, Son, Daughter, etc.)
- Show both directions of relationship
- Common types at top

### 4. FamilyTreeView (Optional Advanced)
- Visual family tree representation
- Interactive nodes for each family member
- Multiple generations support
- Zoom and pan gestures

## Implementation Priority
**MEDIUM-HIGH** - Important for understanding contact networks but complex to implement well

## Key Features
1. Bidirectional relationships (Parent ↔ Child)
2. Grouped relationship types (Family, Love, Friends, Work)
3. Navigate between related contacts
4. Family tree visualization
5. Quick navigation: "View John's wife" → navigates to wife's contact

## Relationship Type Groups (from Monica)
- **Family**: Father, Mother, Son, Daughter, Sibling, etc.
- **Love**: Partner, Spouse, Ex, Date, etc.
- **Friend**: Best friend, Friend, etc.
- **Work**: Boss, Subordinate, Colleague, Mentor, etc.

## Visual Design
- Use icons for relationship types
- Color coding by group (Family=blue, Love=red, etc.)
- Compact list view for contact detail page
- Expandable tree view for visualization

## Integration Points
- Contact search when adding relationship
- Quick contact creation flow
- Deep linking between related contacts
- Display relationship info in contact list (e.g., "John (Sarah's husband)")

## Related Files
- Contact.swift - Add `relationships: [Relationship]?` field
- MonicaAPIClient.swift - Add relationship CRUD + type fetching
- ContactDetailView.swift - Add relationships section

## Notes
- Cache relationship types locally (they rarely change)
- Handle orphaned relationships gracefully
- Consider importing from iOS Contacts relationships
- Respect privacy - don't auto-share relationship data
