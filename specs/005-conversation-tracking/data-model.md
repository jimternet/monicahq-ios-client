# Data Model: Conversation Tracking

**Feature**: 005-conversation-tracking
**Architecture**: Backend-only (no local persistence)
**Date**: 2025-01-26

## Overview

The conversation tracking feature uses a backend-only architecture where all data operations communicate directly with the Monica Conversations API. No local persistence layer (Core Data, SQLite, etc.) is used - all conversation data lives on the user's Monica instance.

## API Models

### Conversation

**Purpose**: Represents a conversation event with a contact

**Swift Definition**:
```swift
struct Conversation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Field Details**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | Int | Yes | Server-assigned unique identifier |
| contactId | Int | Yes | Foreign key to Contact (who conversation was with) |
| happenedAt | Date | Yes | Timestamp when conversation occurred |
| contactFieldTypeId | Int? | No | Optional category for conversation type (in-person, email, text, etc.) |
| notes | String? | No | Free-form text describing conversation content (max 10,000 characters) |
| createdAt | Date | Yes | Server timestamp when record was created |
| updatedAt | Date | Yes | Server timestamp when record was last modified |

**Validation Rules**:
- `happenedAt` MUST NOT be in the future (enforced by API)
- `notes` MUST NOT exceed 10,000 characters (enforced by API)
- `contactId` MUST reference a valid Contact (enforced by API)

**Extensions**:
```swift
extension Conversation {
    var hasNotes: Bool {
        notes != nil && !(notes?.isEmpty ?? true)
    }

    var isQuickLog: Bool {
        !hasNotes
    }

    var formattedDate: String {
        // Format happenedAt for display (e.g., "Jan 26, 2025 at 2:30 PM")
    }
}
```

---

### ConversationCreateRequest

**Purpose**: Request payload for creating new conversations

**Swift Definition**:
```swift
struct ConversationCreateRequest: Encodable {
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}
```

**Usage**:
- Created from ConversationViewModel form state
- Sent to `POST /api/conversations`
- All fields validated client-side before sending

---

### ConversationUpdateRequest

**Purpose**: Request payload for updating existing conversations

**Swift Definition**:
```swift
struct ConversationUpdateRequest: Encodable {
    let happenedAt: Date?
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}
```

**Usage**:
- Created from ConversationViewModel when editing
- Sent to `PUT /api/conversations/{id}`
- Only modified fields included in payload

---

## ViewModel State

### ConversationViewModel

**Purpose**: Manages conversation list, form state, and API operations

**State Properties**:
```swift
@Published var conversations: [Conversation] = []
@Published var isLoading: Bool = false
@Published var errorMessage: String?

// Form state
@Published var happenedAt: Date = Date()
@Published var selectedConversationType: Int?
@Published var notes: String = ""
@Published var isShowingForm: Bool = false
@Published var editingConversation: Conversation?
```

**Computed Properties**:
```swift
var sortedConversations: [Conversation] {
    // Sort by happenedAt descending (most recent first)
}

var isFormValid: Bool {
    // Validate form state before saving
    // - happenedAt not in future
    // - notes within character limit
}

var characterCount: Int {
    notes.count
}

var characterCountColor: Color {
    // Green: < 9000
    // Yellow: 9000-9999
    // Red: >= 10000
}
```

---

## API Service Interface

### ConversationAPIService

**Purpose**: Handles all HTTP communication with Monica Conversations API

**Methods**:
```swift
protocol ConversationAPIService {
    func fetchConversations(contactId: Int) async throws -> [Conversation]
    func createConversation(_ request: ConversationCreateRequest) async throws -> Conversation
    func updateConversation(id: Int, _ request: ConversationUpdateRequest) async throws -> Conversation
    func deleteConversation(id: Int) async throws
}
```

**Error Handling**:
- Network errors → user-friendly message
- 401 Unauthorized → prompt re-authentication
- 404 Not Found → "Conversation not found"
- 422 Validation → display specific validation errors

---

## Data Flow

### Create Conversation

1. User fills form in ConversationFormView
2. User taps "Save"
3. ConversationViewModel validates form state
4. ViewModel creates ConversationCreateRequest
5. ViewModel calls ConversationAPIService.createConversation()
6. API returns new Conversation
7. ViewModel adds to conversations array
8. View updates automatically via @Published

### Update Conversation

1. User taps edit on ConversationRowView
2. ConversationViewModel populates form state
3. User modifies fields
4. User taps "Save"
5. ViewModel creates ConversationUpdateRequest (only changed fields)
6. ViewModel calls ConversationAPIService.updateConversation()
7. API returns updated Conversation
8. ViewModel replaces in conversations array
9. View updates automatically

### Delete Conversation

1. User swipes to delete on ConversationRowView
2. ViewModel calls ConversationAPIService.deleteConversation()
3. API confirms deletion
4. ViewModel removes from conversations array
5. View updates automatically

### Load Conversations

1. ConversationListView appears
2. ViewModel calls ConversationAPIService.fetchConversations()
3. API returns array of Conversations
4. ViewModel updates conversations property
5. View displays list

---

## UI State Management

### Loading States

- `isLoading = true`: Show ProgressView overlay
- `isLoading = false, conversations.isEmpty`: Show empty state
- `isLoading = false, !conversations.isEmpty`: Show list

### Error States

- Network error: Show inline error with retry button
- Validation error: Show field-specific error message
- 401 error: Show "Please log in again" alert

### Form States

- Create mode: `editingConversation = nil`, form cleared
- Edit mode: `editingConversation != nil`, form populated
- Quick log: `notes = ""`, save immediately after selecting date

---

## Relationships to Other Models

### Contact

**Relationship**: One Contact has Many Conversations

**Usage**:
- Conversations always created for a specific Contact
- Contact detail view displays conversation history
- ContactId required for all conversation operations

**Navigation**:
```
ContactDetailView
  → ConversationListView (shows conversations for this contact)
    → ConversationFormView (create/edit)
```

---

## Performance Considerations

### API Caching

- No local cache - always fetch fresh data
- Consider implementing simple memory cache for 5-minute TTL in future

### Pagination

- If contact has > 100 conversations, implement pagination
- Monica API supports `page` parameter
- Load more on scroll to bottom

### Optimistic UI Updates

- Add conversation to list immediately on create (before API confirms)
- Remove from list immediately on delete (before API confirms)
- Show loading indicator on row during operation
- Rollback if API call fails

---

## Migration Notes

This feature follows the backend-only architecture established by call logging (001-004-call-logging). Key differences from call logging:

1. **No Core Data**: Call logging uses Core Data for offline storage; conversations do not
2. **Simpler sync**: No sync status tracking needed - all operations are synchronous API calls
3. **Different API endpoint**: Uses `/api/conversations` instead of `/api/activities`

This architecture aligns with spec dependency: "Follows the same architecture as call logging feature (001-004-call-logging)" but adapts to backend-only pattern as specified in spec assumptions.

---

## Future Enhancements (Out of Scope for MVP)

- Rich text formatting in notes
- Attachments (photos, documents)
- Conversation templates
- Analytics and insights
- Offline support with sync queue
- Search and filtering
