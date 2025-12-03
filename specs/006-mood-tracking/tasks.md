# Tasks: Day and Mood Tracking

**Input**: Design documents from `/specs/006-mood-tracking/`
**Prerequisites**: plan.md (✅), spec.md (✅), research.md (✅), data-model.md (✅)

**Tests**: Tests are deferred to post-MVP per constitution principle 7 (focus on business logic, 70% coverage target).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing Journal infrastructure and create feature directory structure

- [x] T001 Verify JournalView.swift is present and functional in MonicaClient/Views/JournalView.swift
- [x] T002 Create Features/MoodTracking directory structure (Views/, ViewModels/)
- [x] T003 [P] Verify MonicaAPIClient.swift has base request methods working

---

## Phase 2: Foundational (Model & API Layer)

**Purpose**: Core data model and API methods that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Add DayEntry struct model to MonicaClient/Models/Contact.swift
- [x] T005 Add MoodRating enum with emoji mapping to MonicaClient/Models/Contact.swift
- [x] T006 [P] Add DayEntry extensions (moodEmoji, moodDescription, hasComment, formattedDate) to MonicaClient/Models/Contact.swift
- [x] T007 [P] Add DayEntriesResponse typealias to MonicaClient/Models/Contact.swift
- [x] T008 Add fetchDayEntries method to MonicaClient/Services/MonicaAPIClient.swift
- [x] T009 Add createDayEntry method to MonicaClient/Services/MonicaAPIClient.swift
- [x] T010 [P] Add updateDayEntry method to MonicaClient/Services/MonicaAPIClient.swift
- [x] T011 [P] Add deleteDayEntry method to MonicaClient/Services/MonicaAPIClient.swift
- [x] T012 Test API endpoint discovery - verify /api/days or fallback to /api/journal parsing

**Checkpoint**: DayEntry model and all API methods ready - user story implementation can begin

---

## Phase 3: User Story 1 - Rate Your Day (Priority: P1) 🎯 MVP

**Goal**: Users can quickly capture how their day went by selecting a mood rating and optionally adding a comment

**Independent Test**: Add a new day rating, verify it appears in the journal feed

### Implementation for User Story 1

- [x] T013 [US1] Create MoodPickerView component in MonicaClient/Features/MoodTracking/Views/MoodPickerView.swift
- [x] T014 [US1] Add emoji buttons for bad/okay/great selection in MoodPickerView.swift
- [x] T015 [US1] Create DayRatingFormView in MonicaClient/Features/MoodTracking/Views/DayRatingFormView.swift
- [x] T016 [US1] Add date picker (default today) to DayRatingFormView.swift
- [x] T017 [US1] Add optional comment TextEditor to DayRatingFormView.swift
- [x] T018 [US1] Create DayEntryViewModel in MonicaClient/Features/MoodTracking/ViewModels/DayEntryViewModel.swift
- [x] T019 [US1] Implement createDayEntry() in DayEntryViewModel.swift
- [x] T020 [US1] Add form validation (no future dates, rate required) in DayEntryViewModel.swift
- [x] T021 [US1] Connect DayRatingFormView to DayEntryViewModel with save action
- [x] T022 [US1] Add "Rate Your Day" button to JournalView toolbar in MonicaClient/Views/JournalView.swift
- [x] T023 [US1] Present DayRatingFormView as sheet from JournalView.swift
- [x] T024 [US1] Add loading and error states to DayRatingFormView.swift

**Checkpoint**: Users can create day ratings - verify by tapping "Rate Your Day" and saving

---

## Phase 4: User Story 2 - View Day Ratings in Journal (Priority: P1)

**Goal**: Day ratings appear in the unified journal feed alongside other entries

**Independent Test**: View journal feed and see day entries displayed chronologically with emoji indicators

### Implementation for User Story 2

- [x] T025 [US2] Update JournalItem enum to include dayEntry case in MonicaClient/Views/JournalView.swift
- [x] T026 [US2] Add isDayEntry computed property to JournalItem enum
- [x] T027 [US2] Update JournalItem.date to handle dayEntry case
- [x] T028 [US2] Update JournalItem.id to handle dayEntry case
- [x] T029 [US2] Create DayEntryRowView in MonicaClient/Features/MoodTracking/Views/DayEntryRowView.swift
- [x] T030 [US2] Display mood emoji prominently in DayEntryRowView.swift
- [x] T031 [US2] Display date in DayEntryRowView.swift
- [x] T032 [US2] Display optional comment preview (first 100 chars) in DayEntryRowView.swift
- [x] T033 [US2] Add "Day Rating" type label to distinguish from journal entries in DayEntryRowView.swift
- [x] T034 [US2] Update loadJournalItems() in JournalView.swift to fetch day entries
- [x] T035 [US2] Parse day entries from API response and append to journal items
- [x] T036 [US2] Ensure unified sort by date (most recent first) includes day entries
- [x] T037 [US2] Update ForEach in JournalView.swift to render DayEntryRowView for dayEntry case
- [x] T038 [US2] Add DayEntryRowView to Xcode project file

**Checkpoint**: Day entries appear in journal feed with emoji indicators - verify by viewing journal

---

## Phase 5: User Story 3 - Edit and Delete Day Ratings (Priority: P2)

**Goal**: Users can modify or remove day ratings they've created

**Independent Test**: Edit a day entry's mood/comment, delete a day entry, verify changes persist

### Implementation for User Story 3

- [x] T039 [US3] Add editingEntry state to DayEntryViewModel.swift
- [x] T040 [US3] Implement loadEntry() to populate form from existing DayEntry in DayEntryViewModel.swift
- [x] T041 [US3] Implement updateDayEntry() in DayEntryViewModel.swift
- [x] T042 [US3] Add edit mode to DayRatingFormView.swift (pre-populate fields)
- [x] T043 [US3] Update save button to call update vs create based on mode
- [x] T044 [US3] Add NavigationLink from DayEntryRowView to edit form
- [x] T045 [US3] Implement deleteDayEntry() in DayEntryViewModel.swift
- [x] T046 [US3] Add swipe-to-delete gesture on DayEntryRowView in JournalView.swift
- [x] T047 [US3] Add delete confirmation alert
- [x] T048 [US3] Show "Edited" indicator when createdAt != updatedAt in DayEntryRowView.swift
- [x] T049 [US3] Refresh journal list after edit/delete operations

**Checkpoint**: Can edit and delete day entries - verify by modifying and removing entries

---

## Phase 6: User Story 4 - Visual Mood Indicators (Priority: P2)

**Goal**: Mood ratings display with clear visual indicators for quick scanning

**Independent Test**: View multiple day entries and confirm different moods are visually distinguishable

### Implementation for User Story 4

- [x] T050 [US4] Add moodColor computed property to DayEntry extension in Contact.swift
- [x] T051 [US4] Apply mood color as background tint in DayEntryRowView.swift
- [x] T052 [US4] Increase emoji font size for visibility in DayEntryRowView.swift
- [x] T053 [US4] Add mood description text below emoji in DayEntryRowView.swift
- [x] T054 [US4] Style DayEntryRowView to visually distinguish from JournalEntryRow
- [x] T055 [US4] Add visual feedback on mood selection in MoodPickerView.swift
- [x] T056 [US4] Animate mood selection with scale effect in MoodPickerView.swift

**Checkpoint**: Day entries are visually distinct with colored indicators - verify by scrolling journal

---

## Phase 7: User Story 5 - Review Mood Trends (Priority: P3) 🔮 Future

**Goal**: Users can view mood history and identify patterns (deferred for post-MVP)

**Independent Test**: Filter journal to show only day entries, browse patterns over time

**Note**: This story is deferred to post-MVP. Tasks documented for future reference.

### Implementation for User Story 5 (FUTURE)

- [ ] T057 [US5] Add filter toggle to show only day entries in JournalView.swift
- [ ] T058 [US5] Implement mood-only filter in loadJournalItems()
- [ ] T059 [US5] Add date range picker for historical review
- [ ] T060 [US5] Calculate mood statistics (average, most common) for visible range
- [ ] T061 [US5] Display simple mood summary at top of filtered view

**Checkpoint**: Can filter and review mood trends - DEFERRED TO POST-MVP

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and overall feature quality

- [x] T062 [P] Add accessibility labels to mood picker buttons in MoodPickerView.swift
- [x] T063 [P] Add accessibility labels to day entry rows in DayEntryRowView.swift
- [ ] T064 Add duplicate date prevention (check if today already rated) in DayEntryViewModel.swift
- [x] T065 Add error message display with retry button in DayRatingFormView.swift
- [x] T066 Add keyboard dismissal on form save/cancel
- [ ] T067 Update docs/monica-api-openapi.yaml with Day Entry endpoints (Constitution Principle 11)
- [x] T068 Add logging for all day entry API operations (debug mode)
- [x] T069 Code review and refactoring for consistency with JournalView patterns
- [ ] T070 Manual testing on physical device per constitution principle 7
- [x] T071 Add all new Swift files to Xcode project (pbxproj updates)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - Can start after Phase 2
- **User Story 2 (Phase 4)**: Depends on User Story 1 (needs create to test view)
- **User Story 3 (Phase 5)**: Depends on User Story 2 (needs view to test edit/delete)
- **User Story 4 (Phase 6)**: Depends on User Story 2 (needs view to enhance visuals)
- **User Story 5 (Phase 7)**: DEFERRED - post-MVP
- **Polish (Phase 8)**: Depends on all implemented stories

### User Story Dependencies

```
Phase 2 (Foundation)
    ↓
Phase 3 (US1: Create) ← MVP checkpoint
    ↓
Phase 4 (US2: View) ← Core feature complete
    ↓
    ├── Phase 5 (US3: Edit/Delete)
    └── Phase 6 (US4: Visual Polish)
            ↓
        Phase 8 (Polish)
```

### Parallel Opportunities

**Within Phase 2 (Foundational)**:
- T006, T007 can run in parallel (different extension methods)
- T010, T011 can run in parallel (different API methods)

**Within Phase 3 (US1)**:
- T013, T015, T018 can start in parallel (different files)

**Within Phase 4 (US2)**:
- T029-T033 (DayEntryRowView) can be built while T025-T028 (JournalItem) is being updated

**Across Stories (with multiple developers)**:
- After Phase 4 complete: US3 and US4 can proceed in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch API methods in parallel:
Task: "Add updateDayEntry method to MonicaClient/Services/MonicaAPIClient.swift"
Task: "Add deleteDayEntry method to MonicaClient/Services/MonicaAPIClient.swift"

# Launch model extensions in parallel:
Task: "Add DayEntry extensions to MonicaClient/Models/Contact.swift"
Task: "Add DayEntriesResponse typealias to MonicaClient/Models/Contact.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (verify existing infrastructure)
2. Complete Phase 2: Foundational (model + API)
3. Complete Phase 3: User Story 1 (create day rating)
4. **STOP and VALIDATE**: Can create day ratings?
5. Complete Phase 4: User Story 2 (view in journal)
6. **STOP and VALIDATE**: Day entries appear in journal feed?
7. Deploy/demo MVP

### Incremental Delivery

1. Setup + Foundational → API layer ready
2. Add US1 (Create) → Test create flow → **MVP Checkpoint**
3. Add US2 (View) → Test journal display → **Core Feature Complete**
4. Add US3 (Edit/Delete) → Test modifications → Full CRUD
5. Add US4 (Visual Polish) → Enhanced UX
6. Each story adds value without breaking previous stories

---

## Summary

| Phase | Tasks | Parallel Tasks | Description |
|-------|-------|----------------|-------------|
| 1 - Setup | 3 | 1 | Verify infrastructure |
| 2 - Foundation | 9 | 4 | Model + API layer |
| 3 - US1 Create | 12 | 3 | Rate your day (P1) |
| 4 - US2 View | 14 | 4 | Display in journal (P1) |
| 5 - US3 Edit/Delete | 11 | 0 | Modify entries (P2) |
| 6 - US4 Visuals | 7 | 2 | Enhanced indicators (P2) |
| 7 - US5 Trends | 5 | 0 | DEFERRED (P3) |
| 8 - Polish | 10 | 3 | Cross-cutting concerns |

**Total**: 71 tasks (66 active + 5 deferred)
- MVP Scope (US1+US2): 38 tasks
- Full Feature (US1-US4): 56 tasks
- Future (US5): 5 tasks 🔮

**Parallel Opportunities**: 17+ tasks can be parallelized

**MVP Scope**: User Stories 1 + 2 → Create and view day ratings

**Independent Test Criteria**: Defined for each user story

**Format Validation**: ✅ All tasks follow checkbox + ID + [P?] + [Story?] + Description + File Path format

---

## Notes

- [P] tasks = different files/components, no dependencies
- [Story] label maps task to specific user story for traceability
- Tests deferred to post-MVP per constitution (Testing Standards principle 7)
- Backend-only architecture: no Core Data, no offline support
- All API operations are async/await with error handling
- Follow JournalView patterns for consistency
- Update OpenAPI spec per Constitution Principle 11
- Each checkpoint = independently testable increment
- Commit after each task or logical group
- Stop at User Story 2 for MVP validation
