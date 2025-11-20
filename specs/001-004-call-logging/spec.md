# Feature Specification: Phone Call Logging

**Feature Branch**: `001-004-call-logging`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Log phone calls with contacts - duration, notes about conversation, emotional state. Track call history to maintain better communication patterns."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log a Phone Call (Priority: P1)

Users can record that they had a phone call with a contact, including when it happened and what was discussed, so they can remember important conversations and track their communication patterns.

**Why this priority**: This is the core value proposition - capturing call history. Without this, no other features have value. Logging calls is the foundation that enables communication tracking and relationship maintenance.

**Independent Test**: Can be fully tested by logging a call for a contact, then verifying it appears in the contact's call history. Delivers immediate value by creating a record of communication.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact, **When** they tap "Log Call", **Then** a call logging form appears with date/time picker and notes field
2. **Given** user fills in call details, **When** they save the call log, **Then** the call appears in the contact's call history with the date and notes
3. **Given** user wants to log a call that just happened, **When** they open the log form, **Then** the date/time defaults to the current moment
4. **Given** user logs a call, **When** viewing the contact later, **Then** the call appears in chronological order with other interactions

---

### User Story 2 - View Call History (Priority: P1)

Users can see a chronological list of all phone calls with a contact, helping them remember when they last spoke and what was discussed.

**Why this priority**: Viewing recorded calls is essential to get value from logging them. This completes the basic logging cycle: record → view → recall.

**Independent Test**: Can be tested by viewing a contact's detail page and seeing their call history displayed in chronological order. Delivers value through easy access to communication records.

**Acceptance Scenarios**:

1. **Given** a contact has call history, **When** user views contact details, **Then** recent calls are displayed with dates and preview of notes
2. **Given** multiple calls exist, **When** user views call history, **Then** calls are sorted by date with most recent first
3. **Given** a call has detailed notes, **When** user views the call, **Then** they can expand to see full notes
4. **Given** a contact has no calls, **When** user views their call history section, **Then** an empty state shows with option to log first call

---

### User Story 3 - Quick Call Logging (Priority: P2)

Users can quickly log a call with minimal input (just marking that a call happened), with the option to add notes later, making it easy to capture calls without interrupting their workflow.

**Why this priority**: Reduces friction for busy users. Not everyone has time to write detailed notes immediately, but they still want to track that communication occurred.

**Independent Test**: Can be tested by using a "Quick Log" action that creates a call record with just a timestamp, then optionally adding notes later. Delivers value through reduced data entry burden.

**Acceptance Scenarios**:

1. **Given** user just finished a call, **When** they tap "Quick Log Call", **Then** a call is logged with current date/time and no notes
2. **Given** user used quick log, **When** they view the call later, **Then** they can edit it to add notes
3. **Given** user is viewing a contact, **When** they use quick log, **Then** the call appears immediately in the contact's history
4. **Given** user has multiple quick-logged calls, **When** viewing call history, **Then** quick-logged calls show a visual indicator that notes can be added

---

### User Story 4 - Search and Browse All Calls (Priority: P3)

Users can see a timeline of all calls across all contacts and search through call notes to find specific conversations or topics discussed.

**Why this priority**: Useful for power users who want to analyze communication patterns or find specific conversations, but not essential for basic call logging.

**Independent Test**: Can be tested by viewing a global calls list and using search to filter by keywords in call notes. Delivers value through cross-contact visibility.

**Acceptance Scenarios**:

1. **Given** user has logged calls with multiple contacts, **When** they view the calls timeline, **Then** all calls appear sorted by date across all contacts
2. **Given** user searches for a keyword, **When** the search executes, **Then** only calls with that keyword in notes are shown
3. **Given** user views a call in the timeline, **When** they tap it, **Then** they can navigate to the contact's detail page
4. **Given** user filters by date range, **When** viewing the timeline, **Then** only calls within that range appear

---

### User Story 5 - Track Communication Frequency (Priority: P3)

Users can see indicators of how recently they've communicated with contacts, helping them identify relationships that may need attention.

**Why this priority**: Adds relationship maintenance value but requires call history to already be built up. More valuable over time as data accumulates.

**Independent Test**: Can be tested by viewing visual indicators (e.g., "Last called 3 days ago") on contact cards. Delivers value through relationship awareness.

**Acceptance Scenarios**:

1. **Given** a contact has recent call history, **When** user views their contact card, **Then** the card shows "Last called X days ago"
2. **Given** a contact hasn't been called in a long time, **When** viewing contacts list, **Then** visual indicators (color coding) highlight infrequent communication
3. **Given** user has set communication preferences for a contact, **When** viewing that contact, **Then** system shows if they're overdue for contact
4. **Given** user reviews their contacts, **When** sorting by call frequency, **Then** contacts with fewer recent calls appear first

---

### Edge Cases

- What happens when user tries to log a call with a date in the future?
- How does system handle very long call notes (thousands of characters)?
- What occurs when user tries to save a call log with no date selected?
- How are calls handled when the contact is deleted?
- What happens if user logs multiple calls at the exact same date/time for a contact?
- How does system behave when device time zone changes between logging and viewing calls?
- What occurs when user attempts to edit or delete a call that was synced from another device?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to log phone calls with a specific contact
- **FR-002**: System MUST capture date and time when the call occurred
- **FR-003**: System MUST allow users to add notes about the call content
- **FR-004**: System MUST display call history for each contact in chronological order
- **FR-005**: System MUST show the most recent calls first in call history
- **FR-006**: System MUST allow users to edit call details after logging
- **FR-007**: System MUST allow users to delete call logs
- **FR-008**: System MUST persist call logs to the Monica backend
- **FR-009**: System MUST provide a quick logging option that captures just date/time with no notes
- **FR-010**: System MUST allow adding notes to quick-logged calls at a later time
- **FR-011**: System MUST show a global timeline of all calls across all contacts
- **FR-012**: System MUST support searching through call notes by keywords
- **FR-013**: System MUST display "last called" indicators on contact cards
- **FR-014**: System MUST handle date/time in user's local time zone
- **FR-015**: System MUST validate that call dates are not in the future
- **FR-016**: System MUST show empty states when contacts have no call history
- **FR-017**: System MUST default date/time to current moment when logging new calls

### Key Entities

- **Call Log**: Represents a record of a phone call with a contact. Contains the contact reference, date/time of call, optional notes about the conversation, and timestamps for when the log was created/updated. Multiple call logs can exist for each contact.

- **Contact-Call Relationship**: Links contacts to their call history. One contact can have many call logs, enabling tracking of communication patterns over time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can log a new call in under 15 seconds using the quick log feature
- **SC-002**: Users can log a detailed call with notes in under 60 seconds
- **SC-003**: Call logs persist correctly and remain accessible after app restart
- **SC-004**: Users can view complete call history for any contact in under 2 seconds
- **SC-005**: Search through call notes returns results in under 1 second for databases with 1000+ calls
- **SC-006**: 90% of users successfully log their first call without training or help documentation
- **SC-007**: Call history displays correctly in user's local time zone regardless of when/where calls were logged
- **SC-008**: Users can edit or delete call logs without data loss or synchronization issues
- **SC-009**: "Last called" indicators update correctly across all views when new calls are logged
- **SC-010**: System handles at least 5000 call logs per user without performance degradation

## Assumptions

- Monica backend provides call logging API endpoints at `/api/calls` and `/api/contacts/{contact}/calls`
- Call data returned from backend includes all necessary fields (id, contact_id, called_at, content, timestamps)
- Date/time values are exchanged with backend in ISO 8601 format
- Standard mobile data connectivity is generally available but offline logging should queue for later sync
- Call notes are free-form text with reasonable length limits (e.g., 10,000 characters)
- Users manually log calls - automatic call detection is not required for initial implementation
- Multiple calls can be logged for the same contact on the same day (e.g., multiple conversations)
- Call logs are personal to the user and not shared with other users of the Monica instance
