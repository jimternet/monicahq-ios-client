# Tasks: Financial Debt Tracking

**Input**: Design documents from `/specs/007-debt-tracking/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: Not explicitly requested in spec - test tasks omitted.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (iOS)**: `MonicaClient/` for source, `MonicaClientTests/` for tests
- Feature modules under `MonicaClient/Features/DebtTracking/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create feature directory structure and shared models

- [x] T001 Create feature directory structure at MonicaClient/Features/DebtTracking/{Models,Services,ViewModels,Views}/
- [x] T002 [P] Create DebtDirection and DebtStatus enums in MonicaClient/Features/DebtTracking/Models/DebtEnums.swift
- [x] T003 [P] Create NetBalance model in MonicaClient/Features/DebtTracking/Models/NetBalance.swift
- [x] T004 Update Debt struct with new fields (uuid, value, amountWithCurrency, contact) in MonicaClient/Models/Contact.swift
- [x] T005 [P] Add DebtContact struct for nested contact info in MonicaClient/Models/Contact.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: API service and ViewModel that all user stories depend on

**⚠️ CRITICAL**: No user story UI work can begin until this phase is complete

- [x] T006 Create DebtAPIService wrapping MonicaAPIClient debt methods in MonicaClient/Features/DebtTracking/Services/DebtAPIService.swift
- [x] T007 Create DebtViewModel with state management and CRUD operations in MonicaClient/Features/DebtTracking/ViewModels/DebtViewModel.swift
- [x] T008 Implement net balance calculation logic in DebtViewModel.calculateNetBalances() method
- [x] T009 Add Debt extension with computed properties (direction, isOutstanding, contactName, formattedDate) in MonicaClient/Features/DebtTracking/Models/DebtExtensions.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Record a New Debt (Priority: P1) 🎯 MVP

**Goal**: Users can log debts with amount, direction, and reason from a contact's detail page

**Independent Test**: Create a debt for a contact → verify it appears in API response and refreshes in UI

### Implementation for User Story 1

- [ ] T010 [P] [US1] Create DebtFormView with amount, direction picker, and reason fields in MonicaClient/Features/DebtTracking/Views/DebtFormView.swift
- [ ] T011 [US1] Add form validation (amount > 0, direction required) to DebtFormView
- [ ] T012 [US1] Implement createDebt() in DebtViewModel with API call and state refresh
- [ ] T013 [US1] Add "Add Debt" button to ContactDetailView that presents DebtFormView sheet in MonicaClient/Views/ContactDetailView.swift
- [ ] T014 [US1] Handle API errors with user-friendly alerts in DebtFormView

**Checkpoint**: User Story 1 complete - users can create debt records

---

## Phase 4: User Story 2 - View Debt History Per Contact (Priority: P1)

**Goal**: Users can see all debts for a contact with net balance summary

**Independent Test**: View contact with multiple debts → verify list displays with correct net balance per currency

### Implementation for User Story 2

- [ ] T015 [P] [US2] Create DebtRowView displaying amount, direction indicator, reason, and status in MonicaClient/Features/DebtTracking/Views/DebtRowView.swift
- [ ] T016 [P] [US2] Create DebtSummaryView showing net balance per currency in MonicaClient/Features/DebtTracking/Views/DebtSummaryView.swift
- [ ] T017 [US2] Create DebtListView with List of DebtRowView and DebtSummaryView header in MonicaClient/Features/DebtTracking/Views/DebtListView.swift
- [ ] T018 [US2] Implement fetchDebts(contactId:) in DebtViewModel with loading/error states
- [ ] T019 [US2] Add Debts section to ContactDetailView showing DebtListView in MonicaClient/Views/ContactDetailView.swift
- [ ] T020 [US2] Add visual distinction for settled vs outstanding debts (opacity, strikethrough, badge)
- [ ] T021 [US2] Add pull-to-refresh to DebtListView

**Checkpoint**: User Stories 1 & 2 complete - users can create and view debt history

---

## Phase 5: User Story 3 - Mark Debts as Settled (Priority: P2)

**Goal**: Users can mark outstanding debts as complete with immediate balance update

**Independent Test**: Mark debt as settled → verify status changes, balance recalculates, UI updates

### Implementation for User Story 3

- [ ] T022 [US3] Add swipe action "Mark as Paid" to DebtRowView (only for outstanding debts)
- [ ] T023 [US3] Implement markAsSettled(debtId:) in DebtViewModel calling updateDebt API
- [ ] T024 [US3] Update net balance calculation to exclude settled debts
- [ ] T025 [US3] Add settled date display to DebtRowView for completed debts
- [ ] T026 [US3] Hide "Mark as Paid" action for already-settled debts per spec clarification

**Checkpoint**: User Stories 1-3 complete - full debt lifecycle (create, view, settle)

---

## Phase 6: User Story 4 - Global Debt Overview (Priority: P2)

**Goal**: Users can see all debts across all contacts with global totals

**Independent Test**: View global debts → verify totals per currency, filter by direction, navigate to contact

### Implementation for User Story 4

- [ ] T027 [P] [US4] Create GlobalDebtsView with all debts list in MonicaClient/Features/DebtTracking/Views/GlobalDebtsView.swift
- [ ] T028 [US4] Add global summary header showing total owed to user and total user owes per currency
- [ ] T029 [US4] Implement fetchAllDebts() in DebtViewModel using /api/debts endpoint
- [ ] T030 [US4] Add direction filter (All / They owe me / I owe them) to GlobalDebtsView
- [ ] T031 [US4] Enable navigation from debt row to contact detail page
- [ ] T032 [US4] Add GlobalDebtsView to app navigation (e.g., TabView or menu item)

**Checkpoint**: User Stories 1-4 complete - per-contact and global debt views

---

## Phase 7: User Story 5 - Edit and Delete Debt Records (Priority: P3)

**Goal**: Users can modify or remove debt entries with confirmation

**Independent Test**: Edit debt amount → verify change persists and balance recalculates; Delete debt → verify removal

### Implementation for User Story 5

- [ ] T033 [US5] Add edit mode to DebtFormView accepting optional existing Debt for pre-population
- [ ] T034 [US5] Implement updateDebt() in DebtViewModel with API call and state refresh
- [ ] T035 [US5] Add swipe action "Edit" to DebtRowView presenting DebtFormView in edit mode
- [ ] T036 [US5] Add direction change confirmation dialog per spec clarification when editing
- [ ] T037 [US5] Implement deleteDebt() in DebtViewModel with API call
- [ ] T038 [US5] Add swipe action "Delete" to DebtRowView with confirmation alert
- [ ] T039 [US5] Display "last modified" date on edited debts in DebtRowView

**Checkpoint**: All user stories complete - full CRUD functionality

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, performance, and integration improvements

- [ ] T040 Add loading states (ProgressView) during API calls in all views
- [ ] T041 Add empty state messaging when no debts exist in DebtListView and GlobalDebtsView
- [ ] T042 Handle large amounts formatting (millions) with proper number formatting
- [ ] T043 Add haptic feedback for debt creation, settlement, and deletion
- [ ] T044 Verify VoiceOver accessibility labels on DebtRowView and DebtSummaryView
- [ ] T045 Update docs/monica-api-openapi.yaml if any API discrepancies discovered (Constitution Principle 11)
- [ ] T046 Run quickstart.md validation scenarios manually

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 priority - complete in order or parallel if staffed
  - US3 and US4 are P2 - can proceed after US1/US2
  - US5 is P3 - lowest priority
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Creates debts
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Views debts (can parallel with US1)
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Settles debts (integrates with US2 UI)
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Global view (independent of US1-3)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Edit/delete (integrates with US1 form)

### Within Each User Story

- Models/enums before views
- ViewModel methods before views that call them
- Core UI before polish (swipe actions, haptics)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- T002, T003, T005 can all run in parallel (different files)
- T010, T015, T016 can run in parallel (different view files)
- T027 (GlobalDebtsView) can be built while US1-3 views are in progress

---

## Parallel Example: Setup Phase

```bash
# Launch all Setup model tasks together:
Task: "Create DebtDirection and DebtStatus enums in .../DebtEnums.swift"
Task: "Create NetBalance model in .../NetBalance.swift"
Task: "Add DebtContact struct in .../Contact.swift"
```

---

## Parallel Example: User Story 2 Views

```bash
# Launch view creation tasks together:
Task: "Create DebtRowView in .../DebtRowView.swift"
Task: "Create DebtSummaryView in .../DebtSummaryView.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Create debt)
4. Complete Phase 4: User Story 2 (View debts)
5. **STOP and VALIDATE**: Test creating and viewing debts
6. Deploy/demo if ready - users can track debts!

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test create flow → Deploy (can create)
3. Add User Story 2 → Test view flow → Deploy (MVP complete!)
4. Add User Story 3 → Test settle flow → Deploy (lifecycle complete)
5. Add User Story 4 → Test global view → Deploy (cross-contact visibility)
6. Add User Story 5 → Test edit/delete → Deploy (full CRUD)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Debt model already exists in Contact.swift - update rather than create new
- MonicaAPIClient already has debt CRUD methods - wrap in DebtAPIService
