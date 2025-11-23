# Feature Request: Conversations Tracking

## Overview
Log text conversations (SMS, WhatsApp, email) with contacts - track message exchanges with content and timestamps.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/conversations` - List all conversations
- `GET /api/conversations/{id}` - Get single conversation
- `POST /api/conversations` - Create conversation
- `PUT /api/conversations/{id}` - Update conversation
- `DELETE /api/conversations/{id}` - Delete conversation
- `GET /api/contacts/{contact}/conversations` - Get conversations for specific contact
- `POST /api/conversations/{conversation}/messages` - Add message to conversation
- `PUT /api/conversations/{conversation}/messages/{message}` - Update message
- `DELETE /api/conversations/{conversation}/messages/{message}` - Delete message

## Proposed Models

```swift
struct Conversation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let contactFieldTypeId: Int // Type of communication (email, SMS, etc.)
    let happenedAt: Date
    let messages: [Message]?
    let contactFieldType: ContactFieldType?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case contactFieldTypeId = "contact_field_type_id"
        case happenedAt = "happened_at"
        case messages
        case contactFieldType = "contact_field_type"
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let written: Bool // true = you wrote, false = they wrote
    let writtenAt: Date
    let content: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case written
        case writtenAt = "written_at"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ContactFieldType: Codable, Identifiable {
    let id: Int
    let name: String // "Email", "Phone", "WhatsApp", etc.
    let protocol: String?
    let type: String
}

struct ConversationCreatePayload: Codable {
    let contactId: Int
    let contactFieldTypeId: Int
    let happenedAt: String

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case contactFieldTypeId = "contact_field_type_id"
        case happenedAt = "happened_at"
    }
}

struct MessageCreatePayload: Codable {
    let written: Bool
    let writtenAt: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case written
        case writtenAt = "written_at"
        case content
    }
}
```

## UI Components Needed

### 1. ConversationsListView (Global)
- Recent conversations across all contacts
- Show contact name, platform (SMS/Email/WhatsApp), last message preview
- Sort by date
- Filter by platform type

### 2. ContactConversationsSection
- Show on contact detail page
- List of conversations grouped by platform
- Quick "Log conversation" button
- Last conversation indicator

### 3. ConversationDetailView
- Chat-bubble style message thread
- Your messages on right, theirs on left
- Timestamps for each message
- Add more messages to existing conversation
- Platform indicator (SMS, Email, etc.)

### 4. NewConversationView
- Contact selector
- Platform type picker
- Date/time of conversation
- Initial message entry

### 5. AddMessageView
- Who wrote it toggle (You/Them)
- Timestamp picker
- Message content
- Quick add button

## Implementation Priority
**LOW-MEDIUM** - Useful for archiving important conversations but manual entry is tedious

## Key Features
1. Track multi-message conversations
2. Distinguish who wrote each message
3. Multiple platform support (SMS, Email, WhatsApp, etc.)
4. Chat-bubble visualization
5. Search through message content
6. Archive important conversations for reference

## Visual Design
- Chat bubble layout (iMessage style)
- Platform icons (mail, message, WhatsApp)
- Color coding for sender (blue=you, gray=them)
- Timestamps between message groups
- Expandable message threads

## iOS Integration Opportunities
- Share extension for Messages app
- Import from iOS Messages (with permission)
- Quick log from notification
- Paste conversation from clipboard

## Use Cases
- Archive important email exchanges
- Save meaningful text conversations
- Document agreements in writing
- Track customer service conversations
- Remember what was discussed

## Related Files
- MonicaAPIClient.swift - Add conversation + message CRUD methods
- ContactDetailView.swift - Add conversations section
- New models for Conversation, Message, ContactFieldType

## Notes
- Manual entry can be tedious - consider bulk import
- Privacy: conversation content is sensitive
- Don't auto-sync without explicit permission
- Consider conversation summarization AI feature
- Message search across all conversations useful
