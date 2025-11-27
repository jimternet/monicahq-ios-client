# Feature Specification: Life Events Timeline

**Feature Branch**: `001-010-life-events`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Track major life events - marriages, new jobs, graduations, moving, having children. Show life milestones in a timeline"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record Life Events (Priority: P1)

Users can log significant life events for contacts (marriages, births, new jobs, graduations, moving, etc.), capturing the event type, date, and optional notes, creating a historical record of important milestones in each person's life.

**Why this priority**: This is the core value proposition - capturing life milestone information. Without this, users cannot track important events in contacts' lives. It's the foundation that enables comprehensive relationship management and remembering important dates.

**Independent Test**: Can be fully tested by creating a life event for a contact and verifying it appears in their timeline. Delivers immediate value by documenting significant life moments.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact's details, **When** they tap "Add Life Event", **Then** they can select an event type, date, and optional description
2. **Given** user selects "New Job" event type, **When** they save with a date, **Then** the event appears in the contact's timeline marked as a Work event
3. **Given** user records multiple events, **When** viewing the timeline, **Then** events are ordered chronologically with most recent first
4. **Given** user creates an event with notes, **When** viewing it later, **Then** the notes are displayed along with event type and date

---

### User Story 2 - View Life Events Timeline (Priority: P1)

Users can see all life events for a contact displayed in a chronological timeline, showing event types with appropriate icons and dates, helping them understand that person's life journey at a glance.

**Why this priority**: Viewing recorded events is essential to get value from logging them. Users need to see the life history to understand important milestones and remember significant moments.

**Independent Test**: Can be tested by viewing a contact's detail page and seeing their life events displayed in timeline format. Delivers value through comprehensive life history visibility.

**Acceptance Scenarios**:

1. **Given** a contact has life events, **When** user views contact details, **Then** a timeline section shows all events with dates and icons
2. **Given** events span multiple years, **When** user views the timeline, **Then** events are grouped by year for easier navigation
3. **Given** a contact has no life events, **When** user views their details, **Then** an empty state shows with option to add first event
4. **Given** user views an event in the timeline, **When** they tap it, **Then** they can see full event details including any notes

---

### User Story 3 - Categorize Life Events (Priority: P2)

Users can organize life events into categories (Work & Education, Family & Relationships, Home & Living, Health & Wellness, Travel & Experiences), with each category having distinctive visual indicators for quick recognition.

**Why this priority**: Categorization adds organizational value but isn't essential for basic event tracking. Helps users quickly identify types of events and filter by life area.

**Independent Test**: Can be tested by creating events of different types and verifying they display with appropriate category indicators. Delivers value through organized life history.

**Acceptance Scenarios**:

1. **Given** user is adding a life event, **When** they browse event types, **Then** types are grouped by category (Work, Family, Home, Health, Travel)
2. **Given** user creates a "New Job" event, **When** viewing the timeline, **Then** it displays with a Work & Education icon and color
3. **Given** user creates a "Marriage" event, **When** viewing it, **Then** it displays with a Family & Relationships icon
4. **Given** multiple event categories exist, **When** viewing the timeline, **Then** different categories are visually distinguishable by icon and color

---

### User Story 4 - Track Event Milestones (Priority: P2)

Users can see how long ago events occurred and be reminded of upcoming anniversaries, helping them maintain awareness of important dates and celebrate milestones with contacts.

**Why this priority**: Adds contextual value to events but requires time-based calculations. Useful for maintaining relationships but not essential for basic tracking.

**Independent Test**: Can be tested by viewing events and seeing relative time displays (e.g., "3 years ago"). Delivers value through temporal awareness.

**Acceptance Scenarios**:

1. **Given** a life event has a date, **When** user views it, **Then** it shows how long ago the event occurred (e.g., "2 years ago")
2. **Given** an event anniversary is approaching, **When** user views the contact, **Then** they see a reminder indicator
3. **Given** user views an old event, **When** checking the timeline, **Then** they can see exact date along with relative time
4. **Given** multiple events exist from the same year, **When** viewing the timeline, **Then** they're ordered within that year chronologically

---

### User Story 5 - Edit and Delete Life Events (Priority: P3)

Users can modify or remove life events to correct mistakes or update information as circumstances change, maintaining accurate historical records.

**Why this priority**: Useful for data management but not part of the core event tracking workflow. Users occasionally need this for corrections.

**Independent Test**: Can be tested by editing an event's date or type and verifying the changes persist. Delivers value through data accuracy.

**Acceptance Scenarios**:

1. **Given** a life event exists, **When** user edits the date, **Then** the updated date is saved and the timeline reorders appropriately
2. **Given** user modifies an event's type, **When** they save, **Then** the new type appears with appropriate category icon
3. **Given** an event was created by mistake, **When** user deletes it, **Then** it's removed from the contact's timeline
4. **Given** user edits an event's notes, **When** viewing it later, **Then** the updated notes are displayed

---

### Edge Cases

- What happens when user creates multiple events with the same type and date?
- How does system handle future-dated life events (planned events)?
- What occurs when a life event date is before the contact's birthdate?
- How are life events handled when a contact is deleted?
- What happens when user creates events spanning several decades for elderly contacts?
- How does system behave when event type categories change on the backend?
- What occurs when user tries to create an event without a date?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create life event records for specific contacts
- **FR-002**: System MUST support categorized event types (Work & Education, Family & Relationships, Home & Living, Health & Wellness, Travel & Experiences)
- **FR-003**: System MUST capture event date and optional description/notes
- **FR-004**: System MUST display life events in chronological timeline format
- **FR-005**: System MUST show relative time for events (e.g., "2 years ago")
- **FR-006**: System MUST group timeline events by year when spanning multiple years
- **FR-007**: System MUST persist life event data to the Monica backend
- **FR-008**: System MUST provide distinctive icons for each event category
- **FR-009**: System MUST support standard life event types (marriage, birth of child, new job, graduation, moving, etc.)
- **FR-010**: System MUST allow users to delete life events
- **FR-011**: System MUST allow users to edit life event details
- **FR-012**: System MUST validate that event dates are reasonable
- **FR-013**: System MUST handle contacts with no life events gracefully via empty states
- **FR-014**: System MUST remove associated life events when contacts are deleted
- **FR-015**: System MUST load event types from the backend
- **FR-016**: System MUST cache event types locally for performance
- **FR-017**: System MUST display full event details including notes when expanded
- **FR-018**: System MUST sort events by date with most recent first

### Key Entities

- **Life Event**: Significant milestone in a contact's life. Contains event type, date, optional notes, category reference, and timestamps. Multiple events can exist per contact. Examples: marriage, new job, graduation, birth of child, moving to new home.

- **Life Event Type**: Categorized descriptor of the kind of life event (e.g., Marriage, New Job, Graduation, New Home). Contains name, category group, and display icon reference. Provided by backend and cached locally.

- **Life Event Category**: High-level grouping for event types (Work & Education, Family & Relationships, Home & Living, Health & Wellness, Travel & Experiences). Determines visual styling and organizational structure in timeline display.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new life event in under 20 seconds
- **SC-002**: Life event records persist correctly and sync with backend without data loss
- **SC-003**: Timeline displays correctly for contacts with 50+ life events spanning decades
- **SC-004**: Users can identify event categories at a glance through distinctive icons and colors
- **SC-005**: The system displays life event timelines within 2 seconds for contacts with 20+ events
- **SC-006**: 90% of users successfully create their first life event without training
- **SC-007**: Relative time displays are accurate and update appropriately as time passes
- **SC-008**: Events are correctly ordered chronologically 100% of the time
- **SC-009**: Users can find and view specific life events in under 15 seconds
- **SC-010**: The feature helps users remember and celebrate important milestones (measured by usage patterns and timeline engagement)

## Assumptions

- Monica backend provides life event API endpoints at `/api/lifeevents` and `/api/contacts/{contact}/lifeevents`
- Backend provides life event type metadata at `/api/lifeeventtypes` and `/api/lifeeventcategories`
- Life event data from backend includes all necessary fields (id, contact_id, type_id, date, notes, timestamps)
- Event types are categorized into standard groups (Work, Family, Home, Health, Travel)
- Event dates are stored as full dates (YYYY-MM-DD), not just year or month
- Users can create past events retroactively to document historical milestones
- Standard mobile data connectivity is available but offline event creation should queue for sync
- Life events are chronologically ordered without complex filtering by default
- Life event records are private to the user and not shared with other Monica users
- Event types rarely change, making local caching effective
