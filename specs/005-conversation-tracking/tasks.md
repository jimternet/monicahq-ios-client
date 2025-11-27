---
description: "Task list for conversation tracking feature implementation"
---

# Tasks: Conversation Tracking

**Input**: Design documents from `/specs/005-conversation-tracking/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/

**Tests**: Tests are deferred to post-MVP per constitution principle 7 (Testing Standards)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

This is an iOS mobile project with feature-based organization:
- **Models**: `MonicaClient/Models/`
- **Features**: `MonicaClient/Features/ConversationTracking/`
- **Services**: `MonicaClient/Features/ConversationTracking/Services/`
- **ViewModels**: `MonicaClient/Features/ConversationTracking/ViewModels/`
- **Views**: `MonicaClient/Features/ConversationTracking/Views/`

## Phase 1: Setup (Feature Infrastructure)

**Purpose**: Create directory structure and basic scaffolding for conversation tracking feature

- [X] T001 Create feature directory structure at MonicaClient/Features/ConversationTracking/
- [X] T002 Create Services subdirectory at MonicaClient/Features/ConversationTracking/Services/
- [X] T003 [P] Create ViewModels subdirectory at MonicaClient/Features/ConversationTracking/ViewModels/
- [X] T004 [P] Create Views subdirectory at MonicaClient/Features/ConversationTracking/Views/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core API model and service infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 [P] Create Conversation model in MonicaClient/Models/Conversation.swift
- [X] T006 [P] Create ConversationCreateRequest model in MonicaClient/Models/Conversation.swift
- [X] T007 [P] Create ConversationUpdateRequest model in MonicaClient/Models/Conversation.swift
- [X] T008 Implement ConversationAPIService protocol in MonicaClient/Features/ConversationTracking/Services/ConversationAPIService.swift
- [X] T009 Implement fetchConversations(contactId:) method in ConversationAPIService.swift
- [X] T010 Implement createConversation(_:) method in ConversationAPIService.swift
- [X] T011 Implement updateConversation(id:_:) method in ConversationAPIService.swift
- [X] T012 Implement deleteConversation(id:) method in ConversationAPIService.swift
- [X] T013 Add error handling and logging to ConversationAPIService.swift
- [X] T014 Create ConversationViewModel in MonicaClient/Features/ConversationTracking/ViewModels/ConversationViewModel.swift
- [X] T015 Add @Published properties for state management in ConversationViewModel.swift
- [X] T016 Implement loadConversations() async method in ConversationViewModel.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Log a Conversation (Priority: P1) 🎯 MVP

**Goal**: Users can record that they had a conversation with a contact, including when it happened and what was discussed

**Independent Test**: Log a conversation for a contact with date and notes, verify it appears in the contact's conversation history

### Implementation for User Story 1

- [X] T017 [US1] Implement saveConversation() async method in ConversationViewModel.swift
- [X] T018 [US1] Add form validation logic (validateForm()) in ConversationViewModel.swift
- [X] T019 [US1] Add form state properties (happenedAt, notes, selectedConversationType) in ConversationViewModel.swift
- [X] T020 [US1] Implement resetForm() method in ConversationViewModel.swift
- [X] T021 [US1] Create ConversationFormView in MonicaClient/Features/ConversationTracking/Views/ConversationFormView.swift
- [X] T022 [US1] Add date picker for happenedAt field in ConversationFormView.swift
- [X] T023 [US1] Add TextEditor for notes field with character counter in ConversationFormView.swift
- [X] T024 [US1] Add optional conversation type picker in ConversationFormView.swift
- [X] T025 [US1] Add save and cancel buttons with validation in ConversationFormView.swift
- [X] T026 [US1] Add loading and error states to ConversationFormView.swift
- [X] T027 [US1] Implement date validation (prevent future dates) in ConversationViewModel.swift
- [X] T028 [US1] Implement notes character limit validation (10,000 chars) in ConversationViewModel.swift
- [X] T029 [US1] Add default date to current moment when form opens in ConversationViewModel.swift

**Checkpoint**: At this point, User Story 1 should be fully functional - users can log conversations with date and notes

---

## Phase 4: User Story 2 - View Conversation History (Priority: P1)

**Goal**: Users can see a chronological list of all conversations with a contact

**Independent Test**: View a contact's detail page and see conversation history displayed in chronological order with most recent first

### Implementation for User Story 2

- [X] T030 [US2] Create ConversationListView in MonicaClient/Features/ConversationTracking/Views/ConversationListView.swift
- [X] T031 [US2] Add List with conversations data binding in ConversationListView.swift
- [X] T032 [US2] Implement sortedConversations computed property in ConversationViewModel.swift (most recent first)
- [X] T033 [US2] Create ConversationRowView in MonicaClient/Features/ConversationTracking/Views/ConversationRowView.swift
- [X] T034 [US2] Add conversation date display with formatting in ConversationRowView.swift
- [X] T035 [US2] Add notes preview (first 100 chars) in ConversationRowView.swift
- [X] T036 [US2] Add expand/collapse for full notes in ConversationRowView.swift
- [X] T037 [US2] Add empty state view for contacts with no conversations in ConversationListView.swift
- [X] T038 [US2] Add loading state (ProgressView) in ConversationListView.swift
- [X] T039 [US2] Add pull-to-refresh functionality in ConversationListView.swift
- [X] T040 [US2] Add navigation from ContactDetailView to ConversationListView
- [X] T041 [US2] Implement formattedDate helper in Conversation model extension
- [X] T042 [US2] Add visual indicator for conversations without notes in ConversationRowView.swift

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - users can log and view conversation history

---

## Phase 5: User Story 3 - Edit and Delete Conversations (Priority: P2)

**Goal**: Users can update conversation notes or remove conversation entries

**Independent Test**: Edit an existing conversation's notes and verify changes are saved, or delete a conversation and confirm removal from history

### Implementation for User Story 3

- [X] T043 [US3] Implement updateConversation() async method in ConversationViewModel.swift
- [X] T044 [US3] Implement deleteConversation(_:) async method in ConversationViewModel.swift
- [X] T045 [US3] Add editingConversation state property in ConversationViewModel.swift
- [X] T046 [US3] Add edit mode detection (isEditing computed property) in ConversationViewModel.swift
- [X] T047 [US3] Update ConversationFormView to support edit mode (populate from editingConversation)
- [X] T048 [US3] Add swipe-to-delete gesture in ConversationListView.swift
- [X] T049 [US3] Add confirmation dialog for delete action in ConversationListView.swift
- [X] T050 [US3] Add edit navigation from ConversationRowView tap or context menu
- [X] T051 [US3] Implement form population from editingConversation in ConversationViewModel.swift
- [X] T052 [US3] Update form title to show "Edit Conversation" vs "Log Conversation"
- [X] T053 [US3] Add undo capability after delete (optional Toast/Snackbar with undo)

**Checkpoint**: All core conversation management features complete - users can create, view, edit, and delete conversations

---

## Phase 6: User Story 4 - Quick Conversation Logging (Priority: P2)

**Goal**: Users can quickly log a conversation with minimal input (just marking that communication occurred)

**Independent Test**: Use "Quick Log" action to create a conversation with just timestamp, then optionally add notes later

### Implementation for User Story 4

- [X] T054 [US4] Implement quickLogConversation() async method in ConversationViewModel.swift
- [X] T055 [US4] Add quick log button/action in ConversationListView.swift or ContactDetailView
- [X] T056 [US4] Create quick log with current date and empty notes
- [X] T057 [US4] Add visual indicator for quick-logged conversations (no notes) in ConversationRowView.swift
- [X] T058 [US4] Add hasNotes computed property to Conversation model extension
- [X] T059 [US4] Add isQuickLog computed property to Conversation model extension
- [X] T060 [US4] Add "Add Notes" prompt/button for quick-logged conversations in ConversationRowView.swift
- [X] T061 [US4] Optimize quick log UI flow (single tap to log, optional sheet to add details)

**Checkpoint**: All user stories complete - users have full conversation tracking functionality with quick logging option

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and overall feature quality

- [X] T062 [P] Add accessibility labels to all interactive elements in ConversationFormView.swift
- [X] T063 [P] Add accessibility labels to all interactive elements in ConversationListView.swift
- [X] T064 [P] Add accessibility labels to ConversationRowView.swift
- [X] T065 Add error message display with retry button in ConversationListView.swift
- [X] T066 Add optimistic UI updates (show conversation immediately, rollback on error)
- [X] T067 Verify and update docs/monica-api-openapi.yaml with Conversations API endpoints (Constitution Principle 11)
- [X] T068 Add conversation type labels/icons if contactFieldTypeId is supported
- [X] T069 Implement character count color coding (green/yellow/red) for notes field in ConversationFormView.swift
- [X] T070 Add keyboard dismissal on form save/cancel
- [ ] T071 Test with contacts having 100+ conversations (performance validation)
- [X] T072 Add logging for all API operations (debug mode)
- [X] T073 Code review and refactoring for consistency with call logging patterns
- [X] T074 [P] Update CLAUDE.md with conversation tracking completion
- [ ] T075 Manual testing on physical device per constitution principle 7

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1): Independent, can start after Phase 2
  - User Story 2 (P1): Depends on User Story 1 (needs conversations to display)
  - User Story 3 (P2): Depends on User Story 1 & 2 (needs conversations to edit/delete)
  - User Story 4 (P2): Independent from US3, depends on US1 & US2 (quick log variant)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ MVP
- **User Story 2 (P1)**: Depends on User Story 1 - Needs conversations to display
- **User Story 3 (P2)**: Depends on User Story 1 & 2 - Needs conversations and list view to edit/delete
- **User Story 4 (P2)**: Depends on User Story 1 & 2 - Quick log is a variant of create + view

### Within Each User Story

- ViewModel methods before Views
- Form validation before form UI
- Core functionality before polish features
- Models and services from Phase 2 are prerequisites for all stories

### Parallel Opportunities

**Phase 1 (Setup)**:
- T002-T004 can run in parallel (different directories)

**Phase 2 (Foundational)**:
- T005-T007 can run in parallel (different model structs in same file)
- T009-T012 can run in parallel after T008 (different methods)

**Phase 3 (User Story 1)**:
- T022-T024 can run in parallel (different form UI components)

**Phase 4 (User Story 2)**:
- T034-T036 can run in parallel (different row UI components)
- T038-T039 can run in parallel (different list features)

**Phase 7 (Polish)**:
- T062-T064 can run in parallel (different files)
- T074 can run independently

---

## Parallel Example: User Story 1

```bash
# Launch all form UI components together:
Task: "Add date picker for happenedAt field in ConversationFormView.swift"
Task: "Add TextEditor for notes field with character counter in ConversationFormView.swift"
Task: "Add optional conversation type picker in ConversationFormView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 & 2 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T016) - CRITICAL foundation
3. Complete Phase 3: User Story 1 (T017-T029) - Log conversations
4. Complete Phase 4: User Story 2 (T030-T042) - View conversation history
5. **STOP and VALIDATE**: Test logging and viewing independently
6. Deploy/demo conversation tracking MVP

**MVP delivers**: Users can log conversations with notes and view chronological history - core value proposition achieved

### Incremental Delivery

1. **Foundation** (Phase 1-2): API models and service ready
2. **MVP** (Phase 3-4): Log + View → Test independently → Deploy (User Stories 1 & 2)
3. **Edit/Delete** (Phase 5): Add management → Test independently → Deploy (User Story 3)
4. **Quick Log** (Phase 6): Add convenience → Test independently → Deploy (User Story 4)
5. **Polish** (Phase 7): Refinements across all stories

Each phase adds value without breaking previous functionality.

### Parallel Team Strategy

With multiple developers:

1. **Together**: Complete Phase 1 (Setup) and Phase 2 (Foundational)
2. **After Phase 2 completes**:
   - Developer A: User Story 1 (T017-T029)
   - Developer B: User Story 2 (T030-T042) - waits for US1
   - Developer C: Can work on Phase 7 polish tasks that don't require UI
3. **Sequential for US3 & US4**: These depend on US1 & US2 being complete

Due to dependencies between stories (US2 needs US1, US3 needs US1&2), sequential delivery in priority order is recommended for this feature.

---

## Notes

- [P] tasks = different files/components, no dependencies
- [Story] label maps task to specific user story for traceability
- Tests deferred to post-MVP per constitution (Testing Standards principle 7)
- Backend-only architecture: no Core Data, no offline support
- All API operations are async/await with error handling
- Follow call logging patterns for consistency (004-call-logging)
- Verify OpenAPI spec updates per Constitution Principle 11
- Each checkpoint = independently testable increment
- Commit after each task or logical group
- Stop at User Story 1+2 for MVP validation
