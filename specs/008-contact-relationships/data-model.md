# Data Model: Contact Relationships Management

## Entity Definitions

### Existing Entities (No Changes Required)

#### Relationship
```swift
struct Relationship: Codable, Identifiable {
    let id: Int
    let uuid: String
    let object: String
    let contactIs: RelatedContact      // Source contact
    let relationshipType: RelationshipType
    let ofContact: RelatedContact      // Target contact
    let url: String
    let account: Account
    let createdAt: Date
    let updatedAt: Date
}
```

#### RelationshipType
```swift
struct RelationshipType: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String                    // e.g., "father", "spouse", "friend"
    let nameReverseRelationship: String // e.g., "child", "spouse", "friend"
    let relationshipTypeGroupId: Int
    let delible: Bool
    let account: Account
    let createdAt: Date
    let updatedAt: Date
}
```

#### RelationshipTypeGroup
```swift
struct RelationshipTypeGroup: Codable, Identifiable, Hashable {
    let id: Int
    let object: String
    let name: String           // e.g., "Family", "Love", "Friends", "Work"
    let delible: Bool
    let account: Account
    let createdAt: Date?
    let updatedAt: Date?
}
```

#### RelatedContact
```swift
struct RelatedContact: Codable, Identifiable {
    let id: Int
    let uuid: String?
    let hashId: String?
    let firstName: String?
    let lastName: String?
    let completeName: String
    let initials: String?
    let gender: String?        // Used for gender-specific reverse name display
    let avatarURL: String?
    // ... additional fields
}
```

### New Entities

#### RelationshipCategory (enum for UI grouping)
```swift
enum RelationshipCategory: String, CaseIterable {
    case family = "family"
    case love = "love"
    case friends = "friends"
    case work = "work"
    case other = "other"

    var displayName: String { ... }
    var icon: String { ... }
    var color: Color { ... }
}
```

#### GenderedRelationshipName (helper for display)
```swift
struct GenderedRelationshipName {
    let generic: String        // "child"
    let male: String           // "son"
    let female: String         // "daughter"
    let neutral: String        // "child"

    func display(for gender: String?) -> String {
        switch gender?.lowercased() {
        case "male": return male
        case "female": return female
        default: return neutral
        }
    }
}
```

## Validation Rules

### Create Relationship
| Field | Rule | Error Message |
|-------|------|---------------|
| contactIs | Must not equal ofContact | "Cannot create relationship with self" |
| ofContact | Must exist in contacts | "Contact not found" |
| relationshipTypeId | Must be valid type ID | "Invalid relationship type" |
| Duplicate check | No existing relationship with same type between contacts | "Relationship already exists" |

### Update Relationship
| Field | Rule | Error Message |
|-------|------|---------------|
| relationshipTypeId | Must be valid type ID | "Invalid relationship type" |
| relationshipId | Must exist | "Relationship not found" |

### Delete Relationship
| Field | Rule | Error Message |
|-------|------|---------------|
| relationshipId | Must exist | "Relationship not found" |

## State Transitions

```
┌─────────────┐
│   (none)    │
└──────┬──────┘
       │ create
       ▼
┌─────────────┐
│   Active    │◄──────┐
└──────┬──────┘       │
       │ update       │ (type change)
       └──────────────┘
       │
       │ delete
       ▼
┌─────────────┐
│  Deleted    │
└─────────────┘
```

## Relationships Diagram

```
┌─────────────────┐         ┌─────────────────────┐
│     Contact     │         │  RelationshipType   │
├─────────────────┤         ├─────────────────────┤
│ id              │         │ id                  │
│ firstName       │         │ name                │
│ lastName        │         │ nameReverse         │
│ gender          │────┐    │ groupId ────────────┼───┐
└─────────────────┘    │    └─────────────────────┘   │
        │              │                              │
        │ 1:N          │                              │
        ▼              │                              │
┌─────────────────┐    │    ┌─────────────────────┐   │
│  Relationship   │    │    │ RelationshipTypeGroup│◄──┘
├─────────────────┤    │    ├─────────────────────┤
│ id              │    │    │ id                  │
│ contactIs ──────┼────┘    │ name (Family, etc.) │
│ ofContact ──────┼────┘    └─────────────────────┘
│ relationshipType│────┘
└─────────────────┘
```

## Gender Mapping Table

| Generic Type | Male Display | Female Display | Neutral Display |
|--------------|--------------|----------------|-----------------|
| child        | son          | daughter       | child           |
| parent       | father       | mother         | parent          |
| sibling      | brother      | sister         | sibling         |
| grandchild   | grandson     | granddaughter  | grandchild      |
| grandparent  | grandfather  | grandmother    | grandparent     |
| uncle/aunt   | uncle        | aunt           | uncle/aunt      |
| nephew/niece | nephew       | niece          | nephew/niece    |
| cousin       | cousin       | cousin         | cousin          |
| spouse       | husband      | wife           | spouse          |
| partner      | partner      | partner        | partner         |
| friend       | friend       | friend         | friend          |
| boss         | boss         | boss           | boss            |
| colleague    | colleague    | colleague      | colleague       |
