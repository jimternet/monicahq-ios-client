# Feature Specification: Day and Mood Tracking

**Feature Branch**: `006-mood-tracking`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Day/Mood entries missing from journal view - users can rate their day with emoji mood indicators and text descriptions in the web app, but these don't appear in mobile app"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rate Your Day (Priority: P1)

Users can quickly capture how their day went by selecting a mood rating and optionally adding a brief comment, helping them track emotional patterns and reflect on their overall wellbeing over time.

**Why this priority**: This is the core value proposition - capturing daily emotional state. Without this, users cannot record mood data or track how they're feeling day-to-day. It's the foundation that enables self-awareness and emotional pattern recognition.

**Independent Test**: Can be fully tested by adding a new day rating, then verifying it appears in the journal feed. Delivers immediate value by creating a record of emotional wellbeing.

**Acceptance Scenarios**:

1. **Given** user opens the journal view, **When** they tap "Rate Your Day", **Then** a mood selection interface appears with rating options
2. **Given** user selects a mood rating, **When** they save without adding a comment, **Then** the day entry is created with just the rating
3. **Given** user selects a mood rating, **When** they add an optional comment and save, **Then** the day entry is created with both rating and comment
4. **Given** user has created a day rating, **When** viewing the journal feed, **Then** the day entry appears with the mood indicator and any associated comment

---

### User Story 2 - View Day Ratings in Journal (Priority: P1)

Users see their day ratings integrated into the unified journal feed alongside other entries and activities, providing a complete picture of their daily life and interactions.

**Why this priority**: Viewing recorded ratings is essential to get value from logging them. The unified journal view must show all entry types together to provide context and completeness.

**Independent Test**: Can be tested by viewing the journal feed and seeing day entries displayed chronologically with other journal items. Delivers value through comprehensive life tracking.

**Acceptance Scenarios**:

1. **Given** user has created day ratings, **When** viewing the journal feed, **Then** day entries appear in chronological order with other journal items
2. **Given** a day entry has a mood rating, **When** user views it in the feed, **Then** the mood is displayed with an appropriate visual indicator
3. **Given** a day entry has a comment, **When** user views it, **Then** the comment text is displayed along with the mood indicator
4. **Given** user has multiple day ratings over time, **When** viewing the journal, **Then** each day's rating appears on the correct date

---

### User Story 3 - Edit and Delete Day Ratings (Priority: P2)

Users can modify or remove day ratings they've previously created, allowing them to correct mistakes or update their mood assessment as the day progresses.

**Why this priority**: Users need control over their data and the ability to correct entries, but this is secondary to creating and viewing ratings.

**Independent Test**: Can be tested by editing or deleting a day entry and verifying the changes persist. Delivers value through data management flexibility.

**Acceptance Scenarios**:

1. **Given** a day entry exists, **When** user taps to edit it, **Then** they can change the mood rating and comment
2. **Given** user modifies a day entry, **When** they save changes, **Then** the updated rating and comment appear in the journal
3. **Given** a day entry exists, **When** user deletes it, **Then** the entry is removed from the journal feed
4. **Given** user has edited a day rating, **When** viewing the entry, **Then** it shows when it was last updated

---

### User Story 4 - Visual Mood Indicators (Priority: P2)

Mood ratings are displayed with clear, intuitive visual indicators that make it easy to quickly scan the journal and identify emotional patterns at a glance.

**Why this priority**: Visual representation enhances usability and makes mood tracking more engaging, but the functionality works without it.

**Independent Test**: Can be tested by viewing day entries and confirming that each mood rating has an appropriate visual representation. Delivers value through improved UX.

**Acceptance Scenarios**:

1. **Given** a day entry has a specific mood rating, **When** user views it, **Then** an appropriate visual indicator (color, emoji, or icon) represents that mood
2. **Given** multiple day entries with different moods, **When** user scans the journal, **Then** different moods are visually distinguishable
3. **Given** day entries appear alongside other journal items, **When** user views the feed, **Then** day entries are clearly identified as mood ratings
4. **Given** user views a day entry, **When** they see the visual indicator, **Then** it accurately reflects the numerical or categorical mood rating

---

### User Story 5 - Review Mood Trends (Priority: P3)

Users can look back at their mood history over weeks or months to identify patterns in their emotional wellbeing and understand what factors affect their mood.

**Why this priority**: Trend analysis adds deeper insights but requires accumulated data over time. Useful for power users but not essential for basic mood tracking.

**Independent Test**: Can be tested by viewing a series of day ratings over time and observing patterns. Delivers value through self-awareness and reflection.

**Acceptance Scenarios**:

1. **Given** user has multiple day ratings over several weeks, **When** they browse the journal, **Then** they can see mood patterns emerge over time
2. **Given** user filters the journal to show only day ratings, **When** viewing this filtered view, **Then** only mood entries appear
3. **Given** user has consistent mood data, **When** viewing day entries, **Then** they can identify trends in their emotional wellbeing
4. **Given** user reviews their mood history, **When** they see correlations with activities or events, **Then** they gain insights into what affects their mood

---

### Edge Cases

- What happens when user tries to rate the same day multiple times?
- How does system handle day ratings with dates in the future?
- What occurs when a day entry has no mood rating selected?
- How are day ratings displayed when the comment text is very long?
- What happens when user creates a day rating while offline?
- How does system behave when backend returns an unexpected mood rating value?
- What occurs when user tries to delete a day rating that has already been synced?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create day rating entries with a mood indicator
- **FR-002**: System MUST support adding optional text comments to day ratings
- **FR-003**: System MUST display day entries in the unified journal feed
- **FR-004**: System MUST show day entries in chronological order with other journal items
- **FR-005**: System MUST allow users to edit existing day ratings
- **FR-006**: System MUST allow users to delete day ratings
- **FR-007**: System MUST persist day ratings to the Monica backend
- **FR-008**: System MUST display visual indicators for different mood ratings
- **FR-009**: System MUST prevent creation of multiple day ratings for the same date
- **FR-010**: System MUST associate day ratings with specific dates
- **FR-011**: System MUST sync day ratings from backend when loading the journal
- **FR-012**: System MUST handle missing or incomplete day rating data gracefully
- **FR-013**: System MUST show when a day entry was created and last modified
- **FR-014**: System MUST validate that day ratings are not created for future dates
- **FR-015**: System MUST support quick mood selection without requiring a comment
- **FR-016**: System MUST distinguish day entries visually from other journal item types
- **FR-017**: System MUST handle offline creation of day ratings with later synchronization

### Key Entities

- **Day Entry**: Represents a mood rating for a specific date. Contains the date, mood rating value, optional comment text, and timestamps for creation/modification. One day entry can exist per date for each user.

- **Mood Rating**: A categorical or numerical value representing emotional state. Can be mapped to visual indicators (emojis, colors, icons) for display purposes. Part of each day entry.

- **Journal Item**: Unified feed item that can be either a manual journal entry, an activity, or a day entry. All types appear together chronologically in the journal view.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new day rating in under 10 seconds using quick mood selection
- **SC-002**: Day entries appear correctly in the unified journal feed 100% of the time
- **SC-003**: Day ratings persist across app restarts and sync correctly with the backend
- **SC-004**: Users can distinguish between day entries and other journal items at a glance
- **SC-005**: The journal loads and displays day entries within 2 seconds for users with 100+ entries
- **SC-006**: 90% of users successfully create their first day rating without training or help
- **SC-007**: Visual mood indicators accurately represent the underlying rating values 100% of the time
- **SC-008**: Users can edit or delete day ratings without data loss or sync issues
- **SC-009**: The system prevents duplicate day ratings for the same date 100% of the time
- **SC-010**: Mood tracking enhances user's self-awareness as measured by usage patterns (users who start tracking continue doing so)

## Assumptions

- Monica v4.x API does NOT have a separate `/api/days` endpoint - day ratings are fetched via `/api/journal` alongside journal entries
- Day entries are returned as part of the journal feed with a different structure than manual journal entries
- Mood ratings use a standardized scale (e.g., 1-5, or predefined mood categories)
- The web app's day entry functionality serves as the reference implementation for behavior
- Journal feed combines day entries with manual entries and activities chronologically
- Users track one mood rating per day (not multiple ratings throughout the day)
- Date/time values are exchanged with backend in ISO 8601 format
- Day ratings are personal to the user and not shared with others
- Standard mobile data connectivity is available but offline entry creation should queue for sync
- Visual indicators for moods can be implemented without requiring new backend data

## API Implementation Notes (Added during implementation)

**Discovery**: The Monica v4.x `/api/journal` endpoint returns ALL journal items including:
1. Manual journal entries (`object: "journalentry"`)
2. Day/mood rating entries (structure TBD - needs API testing)

The current implementation only parses `JournalEntry` objects. Day entries need to be identified and parsed from the same API response.
