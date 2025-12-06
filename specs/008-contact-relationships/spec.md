# Feature Specification: Contact Relationships Management

**Feature Branch**: `001-008-contact-relationships`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Define and track relationships between contacts - family members, friends, coworkers, etc. with bidirectional relationship support"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Define Relationship Between Contacts (Priority: P1)

Users can specify how two contacts are related (parent, sibling, spouse, friend, coworker, etc.), creating a connection that helps them understand their social network and navigate between related people.

**Why this priority**: This is the core value proposition - defining connections between contacts. Without this, users cannot map their social and family networks. It's the foundation that enables relationship tracking and network visualization.

**Independent Test**: Can be fully tested by creating a relationship between two contacts and verifying it appears in both contacts' relationship lists. Delivers immediate value by documenting social connections.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact's details, **When** they tap "Add Relationship", **Then** they can select another contact and specify the relationship type
2. **Given** user specifies "John is Father of Sarah", **When** they save, **Then** John's contact shows "Father of Sarah" and Sarah's contact shows "Daughter of John"
3. **Given** user selects a relationship type, **When** creating the relationship, **Then** the system automatically creates the reverse relationship
4. **Given** user creates a relationship, **When** viewing either contact, **Then** they can tap the relationship to navigate to the related contact

---

### User Story 2 - View Contact's Relationships (Priority: P1)

Users can see all relationships for a given contact, grouped by category (Family, Love, Friends, Work), helping them understand that person's social connections at a glance.

**Why this priority**: Viewing relationships is essential to get value from defining them. Users need to see the network map to understand connections and navigate between contacts.

**Independent Test**: Can be tested by viewing a contact's detail page and seeing their relationships displayed by category. Delivers value through social network visibility.

**Acceptance Scenarios**:

1. **Given** a contact has relationships, **When** user views contact details, **Then** relationships are displayed grouped by category (Family, Love, Friends, Work)
2. **Given** a contact has multiple family relationships, **When** viewing the Family section, **Then** all family members are listed with their specific relationship types
3. **Given** a contact has no relationships, **When** viewing their details, **Then** an empty state shows with option to add first relationship
4. **Given** user views a relationship, **When** they tap it, **Then** they navigate to the related contact's detail page

---

### User Story 3 - Browse Relationship Types (Priority: P2)

Users can choose from organized relationship types when defining connections, with categories like Family (father, mother, sibling), Love (spouse, partner), Friends, and Work (boss, colleague), making it easy to accurately describe connections.

**Why this priority**: Structured relationship types ensure consistency and enable better organization, but users can still create relationships with a simplified type system if needed.

**Independent Test**: Can be tested by opening the relationship type picker and seeing organized categories with specific types. Delivers value through guided selection.

**Acceptance Scenarios**:

1. **Given** user is adding a relationship, **When** they open the relationship type picker, **Then** types are grouped by category (Family, Love, Friends, Work)
2. **Given** user browses relationship types, **When** they select "Father", **Then** they see the reverse relationship will be "Son" or "Daughter"
3. **Given** user selects a relationship type, **When** creating the relationship, **Then** both forward and reverse types are set correctly
4. **Given** relationship types are available, **When** user searches or scrolls, **Then** common types appear first for quick access

---

### User Story 4 - Navigate Contact Network (Priority: P2)

Users can quickly move between related contacts by tapping on relationships, enabling them to explore their social network and understand how people are connected.

**Why this priority**: Navigation adds significant value for understanding networks but isn't essential for basic relationship tracking. Becomes more valuable as more relationships are defined.

**Independent Test**: Can be tested by tapping a relationship link and verifying it navigates to the related contact. Delivers value through efficient network exploration.

**Acceptance Scenarios**:

1. **Given** a contact has a spouse, **When** user taps "Spouse: Jane Smith", **Then** they navigate to Jane Smith's contact details
2. **Given** user is viewing Jane Smith's details, **When** they see "Spouse: John Doe", **Then** they can tap to return to John's details
3. **Given** a contact has multiple family members, **When** user taps any family relationship, **Then** they navigate to that family member's contact
4. **Given** user navigates through relationships, **When** they use back navigation, **Then** they return to the previous contact in their browsing history

---

### User Story 5 - Edit and Remove Relationships (Priority: P3)

Users can modify or delete relationships to correct mistakes or update connections as circumstances change, maintaining accurate social network data.

**Why this priority**: Useful for data management but not part of the core relationship tracking workflow. Users occasionally need this for corrections or life changes (divorce, friend breakups, job changes).

**Independent Test**: Can be tested by editing or deleting a relationship and verifying the change appears for both contacts. Delivers value through data accuracy.

**Acceptance Scenarios**:

1. **Given** a relationship exists, **When** user deletes it, **Then** it's removed from both contacts' relationship lists
2. **Given** a relationship exists, **When** user changes the type (e.g., from Friend to Best Friend), **Then** the updated type appears for both contacts
3. **Given** user deletes a relationship, **When** viewing either contact, **Then** the relationship no longer appears
4. **Given** a bidirectional relationship exists, **When** user edits one side, **Then** the reverse side updates automatically to maintain consistency

---

### Edge Cases

- What happens when user tries to create duplicate relationships (John is father of Sarah twice)?
- How does system handle orphaned relationships when a contact is deleted?
- What occurs when relationship types have no defined reverse (e.g., custom types)?
- How are circular relationships handled (John is father of Sarah, Sarah is mother of John)?
- What happens when user creates a relationship with themselves?
- How does system behave when relationship type groups or types change on the backend?
- What occurs when user creates many relationships with one contact (polyamorous, large families)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create relationships between two contacts
- **FR-002**: System MUST support categorized relationship types (Family, Love, Friends, Work)
- **FR-003**: System MUST automatically create bidirectional relationships (forward and reverse)
- **FR-004**: System MUST display all relationships for a given contact
- **FR-005**: System MUST group relationships by category when displaying
- **FR-006**: System MUST allow navigation between related contacts
- **FR-007**: System MUST persist relationship data to the Monica backend
- **FR-008**: System MUST support standard relationship types (father, mother, spouse, partner, friend, boss, colleague, etc.)
- **FR-009**: System MUST show appropriate reverse relationships (father ↔ son/daughter, spouse ↔ spouse), inferring gendered reverse types from the related contact's gender field; when gender is unknown, use gender-neutral fallback if available
- **FR-010**: System MUST allow users to delete relationships
- **FR-011**: System MUST allow users to edit relationship types
- **FR-012**: System MUST prevent duplicate relationships between same two contacts with same type, showing inline error with link to existing relationship
- **FR-013**: System MUST handle contact deletion by removing associated relationships
- **FR-014**: System MUST load relationship types from the backend
- **FR-015**: System MUST cache relationship types locally for performance
- **FR-016**: System MUST display empty states when contacts have no relationships
- **FR-017**: System MUST maintain relationship consistency when editing or deleting
- **FR-018**: System MUST support searching for contacts when adding relationships
- **FR-019**: System MUST prevent creating relationships with self, showing clear error message

### Key Entities

- **Relationship**: Connection between two contacts with a specific type. Contains references to both contacts, relationship type, and timestamps. Bidirectional - changes to one side affect the other.

- **Relationship Type**: Categorized descriptor of how contacts are related (e.g., Father, Spouse, Friend, Boss). Contains name, reverse name, and category group. Provided by backend and cached locally.

- **Relationship Type Group**: Category for organizing relationship types (Family, Love, Friends, Work). Groups similar relationship types together for better organization and navigation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new relationship in under 15 seconds
- **SC-002**: Bidirectional relationships display correctly 100% of the time (both sides show appropriate type)
- **SC-003**: Relationship data persists correctly and syncs with backend without data loss
- **SC-004**: Users can navigate between related contacts in under 3 seconds
- **SC-005**: The system displays relationships within 2 seconds for contacts with 20+ relationships
- **SC-006**: 90% of users successfully create their first relationship without training
- **SC-007**: Relationship types load and display in organized categories for easy selection
- **SC-008**: Deleting or editing relationships updates both contacts immediately
- **SC-009**: Users can find and select the correct relationship type in under 10 seconds
- **SC-010**: The feature helps users understand their social network structure (measured by usage patterns and network navigation)

## Clarifications

### Session 2025-12-05

- Q: When creating a gendered reverse relationship (e.g., Father → Son/Daughter), how should the system determine which reverse type to use? → A: Infer from related contact's gender field in Monica
- Q: When a user attempts to create a duplicate relationship (same two contacts, same type), what should happen? → A: Block with inline error message showing existing relationship
- Q: When a user tries to create a relationship with themselves, what should happen? → A: Prevent with clear error message ("Cannot create relationship with self")
- Q: When a contact's gender is unknown and gendered reverse type is needed, what should happen? → A: Use gender-neutral fallback (e.g., "Child" instead of Son/Daughter) if available
- Q: Where should the "Add Relationship" action be accessible from? → A: Relationships section in ContactDetailView with button in the section header

## Assumptions

- Monica backend provides relationship API endpoints at `/api/relationships` and `/api/contacts/{contact}/relationships`
- Backend provides relationship type metadata at `/api/relationshiptypes` and `/api/relationshiptypegroups`
- Relationship types include reverse relationship names (e.g., Father → Son/Daughter)
- Backend handles bidirectional relationship creation when one side is created
- Relationship type groups follow standard categories (Family, Love, Friends, Work)
- Users can only create relationships between existing contacts (not with non-contact entities)
- Relationship data is private to the user and not shared with other Monica users
- Standard mobile data connectivity is available but offline relationship creation should queue for sync
- Relationship types rarely change, making local caching effective
- Users typically have dozens of relationships per person, not hundreds
