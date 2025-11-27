# Feature Specification: Work and Career History

**Feature Branch**: `001-013-work-occupation`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Track employment and career information for contacts - company, job title, salary range, work history."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record Current Employment (Priority: P1)

Users can capture a contact's current job title and company, providing essential professional context for conversations, networking, and relationship management.

**Why this priority**: This is the core value proposition - knowing what someone does for work. Without this, users cannot track professional context. It's the foundation that enables career-aware relationship management.

**Independent Test**: Can be fully tested by adding a current job and company to a contact and verifying it displays prominently. Delivers immediate value by documenting professional status.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact's details, **When** they tap "Add Job", **Then** they can enter job title and company name
2. **Given** user enters "Software Engineer" at "Tech Corp", **When** they mark as current position and save, **Then** it appears as the contact's current job
3. **Given** a contact has a current job, **When** viewing their profile, **Then** the job title and company display prominently in the work section
4. **Given** user updates a current job, **When** they save changes, **Then** the updated information appears immediately

---

### User Story 2 - Track Full Career History (Priority: P1)

Users can record multiple positions across a contact's career, including previous employers and roles, creating a timeline of professional progression that helps understand the contact's career journey.

**Why this priority**: Career history provides valuable context beyond current position. Understanding someone's background helps with networking, referrals, and meaningful professional conversations.

**Independent Test**: Can be tested by adding 3+ positions spanning several years and verifying they display chronologically. Delivers value through comprehensive professional understanding.

**Acceptance Scenarios**:

1. **Given** user adds multiple positions for a contact, **When** viewing work history, **Then** positions are displayed in chronological order (most recent first)
2. **Given** user adds a past position, **When** they specify start and end dates, **Then** the duration is calculated and displayed
3. **Given** a contact has current and past positions, **When** viewing work history, **Then** the current position is visually distinguished from past roles
4. **Given** user records a position, **When** they add job responsibilities, **Then** the description is stored and viewable

---

### User Story 3 - Manage Company Information (Priority: P2)

Users can select from existing companies when adding positions or create new company records, enabling reuse across contacts and maintaining consistent company information for networking context.

**Why this priority**: Company reuse is important for seeing connections but secondary to basic job tracking. Helps identify who works at the same companies.

**Independent Test**: Can be tested by creating a company, then using it for multiple contacts' positions. Delivers value through network visibility.

**Acceptance Scenarios**:

1. **Given** user is adding a position, **When** they search for a company, **Then** previously used companies appear in suggestions
2. **Given** a company doesn't exist, **When** user creates it, **Then** they can optionally add website and company size information
3. **Given** user selects an existing company, **When** saving the position, **Then** the company information is associated with the role
4. **Given** multiple contacts work at the same company, **When** viewing company details, **Then** users can see all contacts at that company

---

### User Story 4 - Track Employment Dates and Tenure (Priority: P2)

Users can record start and end dates for positions, automatically calculating tenure duration and helping understand timing of career moves and current position length.

**Why this priority**: Date tracking adds valuable temporal context but isn't essential for basic job information. Useful for understanding career progression timing.

**Independent Test**: Can be tested by adding positions with dates and verifying duration calculations appear correctly. Delivers value through career timeline clarity.

**Acceptance Scenarios**:

1. **Given** user enters a start date for a position, **When** marking it as current, **Then** system shows "Jan 2020 - Present" with calculated years/months
2. **Given** user enters start and end dates, **When** saving a past position, **Then** system shows "Jan 2018 - Dec 2019 (2 years)" with calculated duration
3. **Given** a contact has a long-tenured current position, **When** viewing their profile, **Then** the duration prominently shows career stability
4. **Given** user reviews work history, **When** looking at dates, **Then** career gaps and rapid changes are visible

---

### User Story 5 - Manage Sensitive Career Information (Priority: P3)

Users can optionally record salary information for their own reference while managing and updating career records as contacts' circumstances change.

**Why this priority**: Salary tracking is useful for some users but not essential. Edit/delete functionality is needed for maintenance but occasional.

**Independent Test**: Can be tested by adding optional salary, then editing/deleting positions. Delivers value through complete record management.

**Acceptance Scenarios**:

1. **Given** user wants to track compensation, **When** adding a position, **Then** they can optionally enter salary amount and currency
2. **Given** salary is recorded, **When** viewing the position, **Then** salary information is displayed in an appropriate, discreet manner
3. **Given** a contact changes jobs, **When** user marks old position as ended and adds new one, **Then** work history accurately reflects the change
4. **Given** user needs to update a position, **When** they edit and save changes, **Then** the updated information replaces previous data

---

### Edge Cases

- What happens when user enters overlapping employment dates (two current positions)?
- How does system handle positions without end dates that aren't marked as current?
- What occurs when a contact is deleted who has associated work history?
- How are companies handled when they're referenced by multiple contacts' positions?
- What happens when user enters future start dates?
- How does system behave when very long job titles or company names are entered?
- What occurs when user deletes a company that's used in multiple positions?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to record job title and company for contacts
- **FR-002**: System MUST distinguish between current and past positions
- **FR-003**: System MUST support multiple positions per contact (work history)
- **FR-004**: System MUST display work history in chronological order (most recent first)
- **FR-005**: System MUST allow users to specify start and end dates for positions
- **FR-006**: System MUST calculate and display position duration based on dates
- **FR-007**: System MUST support company entities that can be reused across contacts
- **FR-008**: System MUST allow users to search and select from existing companies
- **FR-009**: System MUST allow creation of new company records
- **FR-010**: System MUST store optional job description/responsibilities
- **FR-011**: System MUST support optional salary information with currency
- **FR-012**: System MUST display current position prominently in contact profile
- **FR-013**: System MUST persist work and company data to Monica backend
- **FR-014**: System MUST allow users to edit existing positions
- **FR-015**: System MUST allow users to delete positions
- **FR-016**: System MUST remove associated positions when contacts are deleted
- **FR-017**: System MUST handle contacts with no work history via empty states
- **FR-018**: System MUST display formatted date ranges (e.g., "Jan 2020 - Present")

### Key Entities

- **Occupation/Position**: Employment record for a contact. Contains job title, company reference, optional description, optional salary with currency, start/end dates, current position flag, and timestamps. Multiple positions can exist per contact. Used for professional context and networking.

- **Company**: Organization entity that can be associated with multiple contacts' positions. Contains company name, optional website, optional employee count, and timestamps. Reusable across contacts to show professional connections and networks.

- **Work History**: Chronological collection of positions for a contact, ordered by start date (most recent first). Current position is visually distinguished. Shows career progression, tenure patterns, and professional background.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a current job to a contact in under 20 seconds
- **SC-002**: Work history data persists correctly and syncs with backend without loss
- **SC-003**: Career timeline displays clearly for contacts with 10+ positions
- **SC-004**: Position duration calculations are accurate 100% of the time
- **SC-005**: Users can identify a contact's current employer at a glance
- **SC-006**: 90% of users successfully add their first work entry without training
- **SC-007**: Company reuse works correctly across multiple contacts
- **SC-008**: Work history helps users understand professional context (measured by usage patterns)
- **SC-009**: Users can find and update career information in under 15 seconds
- **SC-010**: The feature supports professional networking and career-aware conversations (measured by feature adoption and feedback)

## Assumptions

- Monica backend provides occupation API endpoints at `/api/occupations` and `/api/contacts/{contact}/work`
- Backend provides company API endpoints at `/api/companies` for company management
- Work data from backend includes all necessary fields (id, contact_id, company_id, title, description, salary, dates, current flag, timestamps)
- Company data includes id, name, website, employee count, and timestamps
- Salary tracking is optional and treated as private/sensitive information
- Standard mobile data connectivity is available but offline work entry should queue for sync
- Users primarily track current and recent positions, not complete 30-year career histories
- Employment dates are stored as full dates (YYYY-MM-DD format) or at least month/year
- Duration calculations handle ongoing positions (current jobs with no end date)
- Work records are private to the user and not shared with other Monica users
