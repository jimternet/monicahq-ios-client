# Feature Specification: Contact Reminders and Notifications

**Feature Branch**: `001-014-reminders`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Add support for managing reminders for contacts - birthdays, anniversaries, custom date-based reminders with notifications."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Contact Reminders (Priority: P1)

Users can create reminders for important dates related to contacts (birthdays, anniversaries, follow-ups, etc.) with customizable titles and optional descriptions, ensuring they never forget important relationship moments.

**Why this priority**: This is the core value proposition - setting reminders for contact-related dates. Without this, users cannot proactively maintain relationships through timely follow-ups and remembrance.

**Independent Test**: Can be fully tested by creating a reminder for a contact and verifying it appears in their reminder list. Delivers immediate value by enabling proactive relationship management.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact's details, **When** they tap "Add Reminder", **Then** they can set a date, title, and optional description
2. **Given** user creates a birthday reminder, **When** they save it, **Then** it appears in the contact's reminders list with the date
3. **Given** user sets a reminder date, **When** they configure frequency, **Then** they can choose one-time, weekly, monthly, or yearly recurrence
4. **Given** user creates a reminder, **When** viewing the contact later, **Then** the reminder persists and displays correctly

---

### User Story 2 - View Upcoming Reminders (Priority: P1)

Users can see all upcoming reminders across all contacts in a chronological list, helping them prepare for important dates and maintain relationship obligations proactively.

**Why this priority**: Viewing reminders is essential to get value from creating them. Users need a central place to see what's coming up to take appropriate action.

**Independent Test**: Can be tested by viewing the reminders list and seeing all upcoming reminders sorted by date. Delivers value through actionable reminder visibility.

**Acceptance Scenarios**:

1. **Given** user has upcoming reminders, **When** they open the reminders view, **Then** reminders are listed chronologically with contact names and dates
2. **Given** multiple reminders exist, **When** viewing the list, **Then** reminders are grouped by time period (today, this week, this month, later)
3. **Given** a reminder date has passed, **When** viewing the list, **Then** overdue reminders are visually distinguished
4. **Given** user taps a reminder, **When** the detail view opens, **Then** they can see full reminder information and navigate to the contact

---

### User Story 3 - Configure Reminder Recurrence (Priority: P2)

Users can set reminders to repeat at regular intervals (weekly, monthly, yearly), automatically creating recurring notifications for ongoing relationship maintenance needs like regular check-ins or annual celebrations.

**Why this priority**: Recurrence is valuable for ongoing obligations but secondary to basic one-time reminders. Essential for birthdays and regular follow-ups.

**Independent Test**: Can be tested by creating a recurring reminder and verifying it shows future occurrences. Delivers value through automated reminder renewal.

**Acceptance Scenarios**:

1. **Given** user creates a birthday reminder, **When** they set frequency to "yearly", **Then** the reminder will recur every year on that date
2. **Given** user sets a "call every month" reminder, **When** configured as monthly, **Then** it recurs on the same day each month
3. **Given** user sets weekly recurrence, **When** viewing upcoming reminders, **Then** multiple future instances appear in the timeline
4. **Given** a recurring reminder occurs, **When** the date passes, **Then** the next occurrence automatically appears in upcoming reminders

---

### User Story 4 - Receive Reminder Notifications (Priority: P2)

Users receive timely notifications for upcoming and due reminders, ensuring they're alerted to important dates even when not actively using the app.

**Why this priority**: Notifications add significant value by proactively alerting users, but basic reminder viewing can function without them. Critical for real-world effectiveness.

**Independent Test**: Can be tested by setting a near-future reminder and verifying notification delivery. Delivers value through proactive alerts.

**Acceptance Scenarios**:

1. **Given** a reminder is due today, **When** the notification time arrives, **Then** user receives a notification with contact name and reminder title
2. **Given** user taps a notification, **When** the app opens, **Then** they navigate directly to the relevant contact or reminder details
3. **Given** user has notification permissions, **When** reminders are created, **Then** notifications are automatically scheduled
4. **Given** multiple reminders are due soon, **When** notifications fire, **Then** each reminder sends a separate, clear notification

---

### User Story 5 - Manage and Edit Reminders (Priority: P3)

Users can modify reminder details, change dates or frequencies, and delete reminders that are no longer needed, maintaining control over their reminder collection.

**Why this priority**: Management capabilities are useful for updates but not part of the core reminder workflow. Users occasionally need this for life changes or corrections.

**Independent Test**: Can be tested by editing a reminder's date and verifying the change persists. Delivers value through reminder maintenance flexibility.

**Acceptance Scenarios**:

1. **Given** a reminder exists, **When** user edits the date, **Then** the updated date is saved and future occurrences adjust accordingly
2. **Given** user changes a reminder from one-time to recurring, **When** they save, **Then** future instances appear in the timeline
3. **Given** a reminder is no longer needed, **When** user deletes it, **Then** it's removed from all reminder lists
4. **Given** user edits a reminder's title, **When** viewing it later, **Then** the updated title is displayed everywhere

---

### Edge Cases

- What happens when user creates reminders for dates in the past?
- How does system handle very long reminder titles or descriptions?
- What occurs when a contact is deleted who has associated reminders?
- How are notifications managed when user denies notification permissions?
- What happens when many reminders (50+) are due on the same day?
- How does system behave when changing device timezone with scheduled reminders?
- What occurs when user creates overlapping recurring reminders?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create reminders associated with specific contacts
- **FR-002**: System MUST support reminder dates with day/month/year precision
- **FR-003**: System MUST allow reminder titles and optional descriptions
- **FR-004**: System MUST support recurrence patterns (one-time, weekly, monthly, yearly)
- **FR-005**: System MUST display all reminders for a given contact
- **FR-006**: System MUST show upcoming reminders across all contacts in chronological order
- **FR-007**: System MUST distinguish between upcoming, today, and overdue reminders
- **FR-008**: System MUST persist reminder data to Monica backend
- **FR-009**: System MUST support local notifications for reminder alerts
- **FR-010**: System MUST allow users to edit existing reminders
- **FR-011**: System MUST allow users to delete reminders
- **FR-012**: System MUST handle notification permissions gracefully
- **FR-013**: System MUST group reminders by time period (today, this week, this month)
- **FR-014**: System MUST remove associated reminders when contacts are deleted
- **FR-015**: System MUST calculate next occurrence for recurring reminders
- **FR-016**: System MUST display empty states when no reminders exist
- **FR-017**: System MUST support navigating from reminder to associated contact
- **FR-018**: System MUST handle timezone changes without losing reminder accuracy

### Key Entities

- **Reminder**: Time-based alert associated with a contact. Contains initial date, title, optional description, recurrence pattern (one-time/weekly/monthly/yearly), and timestamps. Multiple reminders can exist per contact. Used for maintaining relationship obligations and celebrating important dates.

- **Recurrence Pattern**: Configuration for reminder repetition. Includes frequency type (one-time, weekly, monthly, yearly) and optional frequency number for intervals. Determines when reminder repeats and calculates next occurrence.

- **Reminder Timeline**: Chronological view of upcoming reminders across all contacts. Groups reminders by time period (today, this week, this month, later). Highlights overdue items and provides quick access to contact details.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new reminder in under 20 seconds
- **SC-002**: Reminder data persists correctly and syncs with backend without loss
- **SC-003**: Upcoming reminders display clearly for users with 100+ reminders
- **SC-004**: Notifications are delivered reliably for 95% of due reminders (with permissions granted)
- **SC-005**: Users can identify today's reminders at a glance
- **SC-006**: 90% of users successfully create their first reminder without training
- **SC-007**: Recurring reminders calculate next occurrence correctly 100% of the time
- **SC-008**: Reminder notifications help users maintain relationships effectively (measured by feature usage and relationship engagement)
- **SC-009**: Users can find and act on specific reminders in under 15 seconds
- **SC-010**: The feature reduces forgotten birthdays and important dates (measured by reminder creation patterns and user feedback)

## Assumptions

- Monica backend provides reminder API endpoints at `/api/reminders` and `/api/contacts/{contact}/reminders`
- Backend supports upcoming reminders endpoint at `/api/reminders/upcoming/{month}`
- Reminder data from backend includes all necessary fields (id, contact_id, initial_date, frequency_type, frequency_number, title, description, timestamps)
- Device notification permissions can be requested and managed
- Standard mobile data connectivity is available but offline reminder creation should queue for sync
- Notification scheduling works with system notification frameworks
- Users primarily set reminders for dates within the next year, not decades in advance
- Reminder dates are stored with day precision (not hour/minute timing)
- Birthday reminders are automatically created from contact birthday fields or manually added
- Reminder recurrence follows calendar patterns (same date each year/month/week)
