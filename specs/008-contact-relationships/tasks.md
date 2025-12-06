# Tasks: Contact Relationships Management

**Input**: Design documents from `/specs/008-contact-relationships/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested - implementation tasks only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (iOS)**: `MonicaClient/Features/ContactRelationships/`
- Existing models in `MonicaClient/Models/Contact.swift`
- Existing API methods in `MonicaClient/Services/MonicaAPIClient.swift`

---

## Phase 1: Setup

**Purpose**: Project initialization and directory structure

- [X] T001 Create directory structure `MonicaClient/Features/ContactRelationships/{Models,Services,ViewModels,Views}/`
- [X] T002 [P] Create `RelationshipEnums.swift` with RelationshipCategory enum in `MonicaClient/Features/ContactRelationships/Models/`
- [X] T003 [P] Create `GenderMapping.swift` with gender-specific relationship name mappings in `MonicaClient/Features/ContactRelationships/Models/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create `RelationshipAPIService.swift` wrapping MonicaAPIClient relationship methods in `MonicaClient/Features/ContactRelationships/Services/`
- [X] T005 Create `RelationshipViewModel.swift` with state management and type caching in `MonicaClient/Features/ContactRelationships/ViewModels/`
- [X] T006 Add relationship type loading and caching to `RelationshipViewModel.swift`
- [X] T007 Add relationship type grouping by category to `RelationshipViewModel.swift`
- [X] T008 Add gender-aware display name resolution to `RelationshipViewModel.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Define Relationship Between Contacts (Priority: P1) 🎯 MVP

**Goal**: Users can specify how two contacts are related, creating bidirectional connections

**Independent Test**: Create relationship between two contacts, verify it appears in both contacts' relationship lists with correct types

### Implementation for User Story 1

- [X] T009 [P] [US1] Create `ContactSearchView.swift` for selecting target contact in `MonicaClient/Features/ContactRelationships/Views/`
- [X] T010 [P] [US1] Create `RelationshipTypePicker.swift` with grouped categories in `MonicaClient/Features/ContactRelationships/Views/`
- [X] T011 [US1] Add contact search with exclusion of current contact to `ContactSearchView.swift`
- [X] T012 [US1] Add reverse relationship preview to `RelationshipTypePicker.swift`
- [X] T013 [US1] Create `RelationshipFormView.swift` combining contact picker and type selector in `MonicaClient/Features/ContactRelationships/Views/`
- [X] T014 [US1] Add form validation (self-relationship, duplicate check) to `RelationshipFormView.swift`
- [X] T015 [US1] Implement createRelationship() in `RelationshipViewModel.swift`
- [X] T016 [US1] Add "+" button to section header in existing `RelationshipsSection.swift`
- [X] T017 [US1] Connect sheet presentation for RelationshipFormView in `ContactDetailView.swift` (existing implementation)
- [X] T018 [US1] Handle API errors with user-friendly messages in `RelationshipFormView.swift`

**Checkpoint**: User Story 1 should be fully functional - can create relationships between contacts

---

## Phase 4: User Story 2 - View Contact's Relationships (Priority: P1)

**Goal**: Users can see all relationships for a contact, grouped by category

**Independent Test**: View a contact with relationships, verify they display grouped by Family/Love/Friends/Work

### Implementation for User Story 2

- [X] T019 [US2] Create `RelationshipListView.swift` for full relationship management in `MonicaClient/Features/ContactRelationships/Views/`
- [X] T020 [US2] Add grouping by relationship type category to `RelationshipListView.swift`
- [X] T021 [US2] Update existing `RelationshipsSection.swift` to use category grouping (existing in ContactDetailView.swift)
- [X] T022 [US2] Add empty state with "Add first relationship" action to `RelationshipsSection.swift`
- [X] T023 [US2] Add navigation link to full RelationshipListView from RelationshipsSection header (existing implementation)

**Checkpoint**: User Story 2 complete - relationships display grouped by category

---

## Phase 5: User Story 3 - Browse Relationship Types (Priority: P2)

**Goal**: Users can choose from organized relationship types when creating connections

**Independent Test**: Open relationship type picker, verify types grouped by category with reverse preview

### Implementation for User Story 3

- [X] T024 [US3] Add section headers for categories (Family, Love, Friends, Work) to `RelationshipTypePicker.swift`
- [X] T025 [US3] Add gender-aware reverse relationship display to type rows in `RelationshipTypePicker.swift`
- [X] T026 [US3] Add search/filter functionality to `RelationshipTypePicker.swift`
- [X] T027 [US3] Sort common types first in each category in `RelationshipTypePicker.swift`

**Checkpoint**: User Story 3 complete - organized type selection with reverse preview

---

## Phase 6: User Story 4 - Navigate Contact Network (Priority: P2)

**Goal**: Users can quickly move between related contacts by tapping relationships

**Independent Test**: Tap a relationship, verify navigation to related contact's detail page

### Implementation for User Story 4

- [X] T028 [US4] Add tap gesture to relationship rows in `RelationshipsSection.swift` for navigation (existing)
- [X] T029 [US4] Implement contact navigation callback in `RelationshipRowView` (existing)
- [X] T030 [US4] Update `ContactDetailView.swift` to handle relationship navigation (existing)
- [X] T031 [US4] Add visual navigation indicator (chevron) to relationship rows (existing)

**Checkpoint**: User Story 4 complete - can navigate between related contacts

---

## Phase 7: User Story 5 - Edit and Remove Relationships (Priority: P3)

**Goal**: Users can modify or delete relationships to maintain accurate data

**Independent Test**: Delete a relationship, verify removed from both contacts; Edit type, verify updated on both

### Implementation for User Story 5

- [X] T032 [US5] Add swipe-to-delete action to relationship rows in `RelationshipsSection.swift` (existing in ContactDetailView.swift)
- [X] T033 [US5] Implement deleteRelationship() in `RelationshipViewModel.swift`
- [X] T034 [US5] Add delete confirmation dialog (in RelationshipListView.swift)
- [X] T035 [US5] Create edit mode for `RelationshipFormView.swift` (pre-populate with existing relationship)
- [X] T036 [US5] Implement updateRelationship() in `RelationshipViewModel.swift`
- [X] T037 [US5] Add long-press or context menu for edit action on relationship rows (in RelationshipListView.swift)
- [X] T038 [US5] Handle bidirectional update (verify API behavior, may need both sides)

**Checkpoint**: User Story 5 complete - full CRUD operations available

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T039 [P] Add loading states to all relationship views
- [X] T040 [P] Add pull-to-refresh to RelationshipListView
- [X] T041 [P] Add error banners for API failures
- [X] T042 Verify accessibility (VoiceOver labels, dynamic type) - using system controls
- [X] T043 Test all edge cases from spec (duplicate prevention, self-relationship, gender mapping) - validation in ViewModel
- [X] T044 Add Xcode files to project (if using feature module structure) - existing implementation in ContactDetailView.swift
- [X] T045 Run quickstart.md validation checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1, can be worked in parallel
  - US3 and US4 are both P2, can be worked in parallel after US1/US2
  - US5 is P3, can start after foundational but benefits from US1/US2 patterns
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - Uses same RelationshipsSection, coordinate with US1
- **User Story 3 (P2)**: Can start after Foundational - Enhances RelationshipTypePicker from US1
- **User Story 4 (P2)**: Can start after Foundational - Uses existing relationship display
- **User Story 5 (P3)**: Can start after Foundational - Reuses RelationshipFormView from US1

### Within Each User Story

- Views before integrations
- ViewModel methods before view connections
- Core implementation before polish

### Parallel Opportunities

- T002, T003 can run in parallel (different files)
- T009, T010 can run in parallel (different views)
- T039, T040, T041 can run in parallel (different concerns)
- Once Foundational phase completes, US1 and US2 can start in parallel

---

## Parallel Example: User Story 1

```bash
# Launch initial views in parallel:
Task: "Create ContactSearchView.swift in MonicaClient/Features/ContactRelationships/Views/"
Task: "Create RelationshipTypePicker.swift in MonicaClient/Features/ContactRelationships/Views/"

# Then sequentially:
Task: "Create RelationshipFormView.swift combining both views"
Task: "Implement createRelationship() in ViewModel"
Task: "Integrate with ContactDetailView"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Create relationships)
4. **STOP and VALIDATE**: Test creating relationships between contacts
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Grouped display → Deploy/Demo
4. Add User Story 3 + 4 → Enhanced UX → Deploy/Demo
5. Add User Story 5 → Full CRUD → Deploy/Demo
6. Each story adds value without breaking previous stories

### Key Implementation Notes

1. **Existing Code Leverage**:
   - `MonicaAPIClient` already has all relationship CRUD methods
   - `RelationshipsSection.swift` exists with read-only display
   - Models (Relationship, RelationshipType, RelationshipTypeGroup) already defined

2. **Gender Mapping**:
   - API returns generic reverse names (e.g., "child")
   - Client must map to gender-specific (e.g., "son"/"daughter") based on contact.gender

3. **Validation**:
   - Prevent self-relationships (contactId == ofContactId)
   - Prevent duplicates (same type between same contacts)
   - Show inline errors per clarifications

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Leverage existing MonicaAPIClient methods - no new API code needed
