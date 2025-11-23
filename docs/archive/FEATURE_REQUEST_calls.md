# Feature Request: Phone Call Logging

## Overview
Log phone calls with contacts - duration, notes about conversation, emotional state. Track call history to maintain better communication patterns.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/calls` - List all calls
- `GET /api/calls/{id}` - Get single call
- `POST /api/calls` - Create call log
- `PUT /api/calls/{id}` - Update call
- `DELETE /api/calls/{id}` - Delete call
- `GET /api/contacts/{contact}/calls` - Get calls for specific contact

## Proposed Models

```swift
struct Call: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let calledAt: Date
    let content: String?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: calledAt, relativeTo: Date())
    }
}

struct CallCreatePayload: Codable {
    let contactId: Int
    let calledAt: String // ISO 8601 date
    let content: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case calledAt = "called_at"
        case content
    }
}
```

## UI Components Needed

### 1. CallsListView (Global)
- Recent calls across all contacts
- Sorted by date (most recent first)
- Show contact name, date, preview of notes
- Filter by date range
- Search in call notes

### 2. ContactCallsSection
- Show on contact detail page
- Recent calls with this contact
- Quick "Log a call" button
- Call history with notes
- Last called indicator

### 3. LogCallView
- Date/time picker (defaults to now)
- Contact selector (if from global view)
- Text area for call notes
- Quick templates: "Quick check-in", "Birthday call", etc.
- Emotional tone selector (happy, neutral, concerned, etc.)

### 4. CallDetailView
- Full call notes
- Edit capability
- Delete option
- Navigate to contact

### 5. QuickLogCallWidget
- Floating action button on contact detail
- Quick "Just called" with minimal input
- Add notes later option

## Implementation Priority
**MEDIUM** - Useful for maintaining communication patterns but less critical than core features

## Key Features
1. Log calls with date/time and notes
2. Track communication frequency
3. Quick "just called" action
4. Call history per contact
5. Search through call notes
6. Communication pattern insights

## iOS Integration Opportunities
- CallKit integration to detect outgoing calls (with permission)
- Suggest logging after phone call detected
- Pull call duration from CallKit (if available)
- Quick action from iOS Phone app share sheet

## Visual Design
- Phone icon theming
- Timeline view of calls
- Color coding for call frequency (green=recent, red=overdue)
- Compact list items with expandable notes

## Advanced Features (Future)
- Call duration tracking
- Automatic call detection
- Voice memo attachment
- Transcription of call notes
- Communication frequency analytics
- "You haven't called X in Y days" reminders

## Related Files
- Contact.swift - Add `calls: [Call]?` field
- MonicaAPIClient.swift - Add call CRUD methods
- ContactDetailView.swift - Add calls section or quick log button

## Notes
- CallKit integration requires special permissions
- Voice recording laws vary by jurisdiction
- Consider privacy implications of call logging
- Auto-suggest logging when phone app closed
