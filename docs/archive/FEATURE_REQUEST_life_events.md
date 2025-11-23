# Feature Request: Life Events Timeline

## Overview
Track major life events for contacts - marriage, new job, graduation, moving, having children, etc. Build a timeline of significant moments.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/lifeevents` - List all life events
- `GET /api/lifeevents/{id}` - Get single life event
- `POST /api/lifeevents` - Create life event
- `PUT /api/lifeevents/{id}` - Update life event
- `DELETE /api/lifeevents/{id}` - Delete life event

## Proposed Models

```swift
struct LifeEvent: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let lifeEventTypeId: Int
    let lifeEventType: LifeEventType?
    let happenedAt: Date
    let name: String?
    let note: String?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case lifeEventTypeId = "life_event_type_id"
        case lifeEventType = "life_event_type"
        case happenedAt = "happened_at"
        case name
        case note
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LifeEventType: Codable, Identifiable {
    let id: Int
    let name: String
    let coreMonicaData: Bool
    let lifeEventCategoryId: Int
    let lifeEventCategory: LifeEventCategory?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coreMonicaData = "core_monica_data"
        case lifeEventCategoryId = "life_event_category_id"
        case lifeEventCategory = "life_event_category"
    }
}

struct LifeEventCategory: Codable, Identifiable {
    let id: Int
    let name: String // "Work & Education", "Family & Relationships", etc.
    let coreMonicaData: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coreMonicaData = "core_monica_data"
    }
}

struct LifeEventCreatePayload: Codable {
    let contactId: Int
    let lifeEventTypeId: Int
    let happenedAt: String
    let name: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case lifeEventTypeId = "life_event_type_id"
        case happenedAt = "happened_at"
        case name
        case note
    }
}
```

## UI Components Needed

### 1. ContactTimelineView
- Visual timeline of life events
- Chronological order (newest first or oldest first toggle)
- Event type icons
- Date markers
- Notes preview

### 2. LifeEventsSection
- On contact detail page
- Recent/major life events summary
- "Add life event" button
- Quick view of timeline

### 3. AddLifeEventView
- Date picker
- Category selector (Work, Family, Health, etc.)
- Event type picker within category
- Custom name (optional)
- Notes field

### 4. LifeEventDetailView
- Full event information
- Edit capability
- Delete option
- Related notes
- Navigate to contact

### 5. GlobalTimelineView (Optional)
- Life events across all contacts
- "What happened in 2023" view
- Filter by event type/category
- Celebration reminders

## Life Event Categories (from Monica)
- **Work & Education**: New job, Promotion, Retirement, Graduation, Published work
- **Family & Relationships**: Marriage, Divorce, New child, Engaged, New relationship
- **Home & Living**: Moved, Bought house, New roommate
- **Health & Wellness**: Hospitalization, Surgery, Started therapy
- **Travel & Experiences**: Traveled, Started hobby, Achieved goal

## Implementation Priority
**MEDIUM** - Nice for comprehensive contact history but not essential for daily use

## Key Features
1. Categorized life event types
2. Visual timeline presentation
3. Custom event naming
4. Notes for context
5. Anniversary tracking (auto-remind on event anniversaries)
6. Historical view of contact's life journey

## Visual Design
- Vertical timeline with markers
- Category-specific icons
- Color coding by category
- Date grouping (by year)
- Expandable event cards
- Milestone celebrations

## Advanced Features
- Auto-suggest from journal entries
- Create reminders from life events
- Share congratulations for events
- Export timeline as PDF
- Photo attachment to events
- Multiple contacts per event (wedding with spouse)

## Related Files
- MonicaAPIClient.swift - Add life event CRUD methods
- ContactDetailView.swift - Add timeline section
- New models for LifeEvent, LifeEventType, LifeEventCategory

## Notes
- Cache event types locally (core data, rarely changes)
- Differentiate between positive/neutral/negative events
- Consider sentiment in timeline visualization
- Privacy: major life events are personal
- Auto-create reminders for recurring celebrations
