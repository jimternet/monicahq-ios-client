# Tasks: Contact Avatar Display with Authentication

**Input**: Design documents from `/specs/001-003-avatar-authentication/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md, contracts/avatar-api.md

**Tests**: Tests included per constitution requirement (70%+ coverage)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- File paths use iOS project structure: `MonicaClient/`, `MonicaClientTests/`

## Phase 1: Setup & Branch Creation

**Purpose**: Project initialization and feature branch setup

- [ ] T001 Create feature branch `001-003-avatar-authentication` from main
- [ ] T002 Create directory `MonicaClient/Views/Components/` if not exists
- [ ] T003 Create directory `MonicaClient/Utilities/` if not exists

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 [P] Create `AvatarInfo` struct in `MonicaClient/Models/Contact.swift`
- [ ] T005 [P] Create `AvatarSource` enum in `MonicaClient/Models/Contact.swift`
- [ ] T006 [P] Add `avatar: AvatarInfo?` field to `Contact.Information` struct in `MonicaClient/Models/Contact.swift`
- [ ] T007 [P] Create `Color(hex:)` extension in `MonicaClient/Utilities/Color+Extensions.swift` (new file)
- [ ] T008 Add `avatarURL` computed property to `Contact` in `MonicaClient/Models/Contact.swift`
- [ ] T009 Add `shouldLoadAvatar` computed property to `Contact` in `MonicaClient/Models/Contact.swift`
- [ ] T010 Add `initials` computed property to `Contact` in `MonicaClient/Models/Contact.swift`
- [ ] T011 Add `initialsColor` computed property to `Contact` in `MonicaClient/Models/Contact.swift`
- [ ] T012 Add `generateColorFromName()` private method to `Contact` in `MonicaClient/Models/Contact.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Contact Photos (Priority: P1) 🎯 MVP

**Goal**: Display custom uploaded photos and Gravatar images for contacts with authentication

**Independent Test**: Open app and view contacts with photos - photos should display correctly instead of showing fallback initials

### Core Infrastructure for User Story 1

- [ ] T013 [P] [US1] Create `AuthenticatedImageLoading` protocol in `MonicaClient/Services/AuthenticatedImageLoader.swift` (new file)
- [ ] T014 [P] [US1] Create `ImageLoadError` enum in `MonicaClient/Services/AuthenticatedImageLoader.swift`
- [ ] T015 [P] [US1] Create `ImageLoadState` enum in `MonicaClient/ViewModels/ImageLoader.swift` (new file)
- [ ] T016 [US1] Implement `AuthenticatedImageLoader` class in `MonicaClient/Services/AuthenticatedImageLoader.swift`
- [ ] T017 [US1] Add `shouldAuthenticate(url:)` private method to `AuthenticatedImageLoader`
- [ ] T018 [US1] Configure NSCache in `AuthenticatedImageLoader.init()` with 100 image limit and 50MB capacity
- [ ] T019 [US1] Implement `loadImage(from:)` async method in `AuthenticatedImageLoader` with Bearer token injection
- [ ] T020 [US1] Implement `clearCache()` method in `AuthenticatedImageLoader`
- [ ] T021 [US1] Create `ImageLoader` ObservableObject in `MonicaClient/ViewModels/ImageLoader.swift`
- [ ] T022 [US1] Implement `load()` async method in `ImageLoader` with state management
- [ ] T023 [US1] Implement `cancel()` method in `ImageLoader`

### UI Components for User Story 1

- [ ] T024 [P] [US1] Create `AvatarView` component in `MonicaClient/Views/Components/AvatarView.swift` (new file)
- [ ] T025 [US1] Implement photo loading state machine in `AvatarView` (idle/loading/loaded/failed)
- [ ] T026 [US1] Add circular clipping and sizing to `AvatarView`
- [ ] T027 [US1] Add accessibility labels to `AvatarView` for photo state

### Integration for User Story 1

- [ ] T028 [US1] Create `AuthenticatedImageLoader` instance in `ContactsListView` using `authManager.apiToken`
- [ ] T029 [US1] Replace existing Circle/Text avatar in `ContactsListView` with `AvatarView` component
- [ ] T030 [US1] Replace existing Circle/Text avatar in `ContactDetailView` with `AvatarView` component (size: 120)
- [ ] T031 [US1] Configure URLCache in `MonicaClient/MonicaApp.swift` init() - 50MB memory, 150MB disk

**Checkpoint**: User Story 1 complete - custom photos and Gravatar images should load with authentication

---

## Phase 4: User Story 2 - Graceful Fallback for Missing Photos (Priority: P1) 🎯 MVP

**Goal**: Display colored initial-based avatars when contacts don't have photos, ensuring consistent and professional appearance

**Independent Test**: View contacts without photos and confirm colored initial avatars display instead of errors or blank spaces

### Implementation for User Story 2

- [ ] T032 [P] [US2] Create `InitialsAvatarView` component in `MonicaClient/Views/Components/InitialsAvatarView.swift` (new file)
- [ ] T033 [US2] Implement colored circle background in `InitialsAvatarView` using `contact.initialsColor`
- [ ] T034 [US2] Implement initials text overlay in `InitialsAvatarView` using `contact.initials`
- [ ] T035 [US2] Add accessibility labels to `InitialsAvatarView`
- [ ] T036 [US2] Integrate `InitialsAvatarView` as fallback in `AvatarView` for failed state
- [ ] T037 [US2] Integrate `InitialsAvatarView` as placeholder in `AvatarView` for loading state
- [ ] T038 [US2] Add immediate initials display in `AvatarView` when `shouldLoadAvatar` is false

**Checkpoint**: User Stories 1 AND 2 complete - photos display when available, initials display otherwise

---

## Phase 5: User Story 3 - Fast Photo Loading (Priority: P2)

**Goal**: Photos load quickly and are cached locally for instant subsequent views

**Independent Test**: View contact photos, then view again - photos should appear instantly from cache

### Implementation for User Story 3

- [ ] T039 [US3] Verify NSCache implementation in `AuthenticatedImageLoader` caches decompressed images
- [ ] T040 [US3] Verify URLCache configuration in `MonicaApp.swift` enables disk persistence
- [ ] T041 [US3] Add cache cost assignment in `AuthenticatedImageLoader.loadImage()` based on image data size
- [ ] T042 [US3] Test cache hit path - verify cached images bypass network request
- [ ] T043 [US3] Add `.id(contact.id)` modifier to `AvatarView` to prevent unnecessary re-loads on list updates

**Checkpoint**: Photos load from cache instantly on subsequent views

---

## Phase 6: User Story 4 - Support for Both Photo Types (Priority: P2)

**Goal**: Support both custom uploaded photos and Gravatar photos, with custom photos taking priority

**Independent Test**: View contacts with custom photos and contacts with Gravatars - both types display correctly

### Implementation for User Story 4

- [ ] T044 [US4] Verify `shouldAuthenticate()` in `AuthenticatedImageLoader` correctly identifies Gravatar URLs (host contains "gravatar.com")
- [ ] T045 [US4] Verify Gravatar requests do NOT include Authorization header
- [ ] T046 [US4] Verify custom photo requests DO include Bearer token header
- [ ] T047 [US4] Add support for "adorable" source type in `shouldAuthenticate()` (no auth required)
- [ ] T048 [US4] Test priority: custom photo URL used when both custom and Gravatar available in API response

**Checkpoint**: Both custom photos and Gravatar photos display correctly with appropriate authentication

---

## Phase 7: Testing (70%+ Coverage)

**Purpose**: Unit tests, integration tests, and manual testing per constitution requirement

### Unit Tests

- [ ] T049 [P] Create `MonicaClientTests/UnitTests/Models/ContactExtensionsTests.swift` (new file)
- [ ] T050 [P] [US2] Test initials generation in `ContactExtensionsTests` - "John Doe" → "JD"
- [ ] T051 [P] [US2] Test initials with single name in `ContactExtensionsTests` - "Madonna" → "M"
- [ ] T052 [P] [US2] Test initials with empty names in `ContactExtensionsTests`
- [ ] T053 [P] [US1] Test `avatarURL` parsing in `ContactExtensionsTests` for valid URLs
- [ ] T054 [P] [US1] Test `avatarURL` parsing in `ContactExtensionsTests` for empty URLs
- [ ] T055 [P] [US1] Test `shouldLoadAvatar` returns false for "default" source
- [ ] T056 [P] [US1] Test `shouldLoadAvatar` returns true for "photo" source with URL
- [ ] T057 [P] [US2] Test color generation determinism in `ContactExtensionsTests` - same name = same color
- [ ] T058 [P] Create `MonicaClientTests/UnitTests/Utilities/ColorExtensionsTests.swift` (new file)
- [ ] T059 [P] [US2] Test hex color parsing in `ColorExtensionsTests` - "#b3d5fe" → correct Color
- [ ] T060 [P] [US2] Test hex color parsing for 8-digit ARGB in `ColorExtensionsTests`
- [ ] T061 [P] [US2] Test hex color parsing for invalid hex in `ColorExtensionsTests` - defaults to gray

### Integration Tests

- [ ] T062 [P] Create `MonicaClientTests/IntegrationTests/AvatarLoadingIntegrationTests.swift` (new file)
- [ ] T063 [P] [US1] Create mock `AuthenticatedImageLoading` implementation in `AvatarLoadingIntegrationTests`
- [ ] T064 [P] [US1] Test successful image load updates `ImageLoader.state` to `.loaded()`
- [ ] T065 [P] [US2] Test failed image load updates `ImageLoader.state` to `.failed()`
- [ ] T066 [P] [US1] Test unauthorized (401) error falls back to initials
- [ ] T067 [P] [US1] Test not found (404) error falls back to initials
- [ ] T068 [P] [US3] Test cache clearing on `AuthenticatedImageLoader.clearCache()`

### Manual Testing

- [ ] T069 [US1] Manual test: View contact with custom uploaded photo - verify photo displays
- [ ] T070 [US4] Manual test: View contact with Gravatar - verify Gravatar loads without auth header (use network inspector)
- [ ] T071 [US2] Manual test: View contact with no photo - verify colored initials display
- [ ] T072 [US2] Manual test: Simulate network error - verify graceful fallback to initials
- [ ] T073 [US3] Manual test: View photo, scroll away, scroll back - verify instant load from cache
- [ ] T074 [US3] Manual test: Close app, reopen - verify cached photos persist

**Checkpoint**: 70%+ test coverage achieved for Contact extensions, Color extensions, ImageLoader state management

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and cleanup

### Cache Management

- [ ] T075 Add cache clearing to `AuthenticationManager.logout()` in `MonicaClient/Services/AuthenticationManager.swift`
- [ ] T076 Call `URLCache.shared.removeAllCachedResponses()` on logout
- [ ] T077 Verify cache is cleared when user logs out and logs back in

### Performance & Accessibility

- [ ] T078 [P] Add SwiftUI preview for `AvatarView` in `AvatarView.swift` with sample contacts
- [ ] T079 [P] Add SwiftUI preview for `InitialsAvatarView` in `InitialsAvatarView.swift`
- [ ] T080 Verify accessibility labels work with VoiceOver
- [ ] T081 Test dark mode support for avatar colors
- [ ] T082 Profile memory usage with Instruments for 100+ contacts in list

### Documentation & Validation

- [ ] T083 [P] Verify actual Monica API avatar response format matches contracts/avatar-api.md
- [ ] T084 [P] Update `docs/monica-api-openapi.yaml` if API differs from documentation (constitution principle 11)
- [ ] T085 Run through quickstart.md validation steps
- [ ] T086 Update CLAUDE.md if needed with avatar implementation notes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 and US2 can proceed in parallel (different components)
  - US3 depends on US1 (adds caching to existing loader)
  - US4 depends on US1 (adds Gravatar support to existing loader)
- **Testing (Phase 7)**: Depends on corresponding user story implementation
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start IMMEDIATELY after Foundational (Phase 2) - Parallel with US1 (different files)
- **User Story 3 (P2)**: Depends on US1 complete (enhances existing image loader)
- **User Story 4 (P2)**: Depends on US1 complete (adds Gravatar detection to existing loader)

### Within Each User Story

- Protocol/enum definitions before implementations
- Service layer (AuthenticatedImageLoader) before ViewModel layer (ImageLoader)
- ViewModels before UI components
- Core components before integration into existing views
- Tests can run in parallel once implementation exists

### Parallel Opportunities

- T004-T007 (Foundation models and utilities) can all run in parallel
- T013-T015 (Protocol, Error, State enums) can run in parallel
- T024 (AvatarView) and T032 (InitialsAvatarView) can run in parallel
- T028-T031 (Integration) can run in parallel after T024 complete
- US1 and US2 can be worked on in parallel by different developers
- All unit tests (T049-T061) can run in parallel
- All integration tests (T062-T068) can run in parallel

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only - Both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (authenticated photo loading)
4. Complete Phase 4: User Story 2 (graceful fallbacks)
5. **STOP and VALIDATE**: Test US1 and US2 independently
6. Deploy/demo MVP

**MVP Delivers**:
- Custom uploaded photos display with authentication
- Gravatar photos display
- Colored initials fallback for missing photos
- No broken images or errors visible to users

### Full Feature (Add P2 Stories)

1. Complete MVP (Phases 1-4)
2. Complete Phase 5: User Story 3 (caching for performance)
3. Complete Phase 6: User Story 4 (explicit both photo types support)
4. Complete Phase 7: Testing (70%+ coverage)
5. Complete Phase 8: Polish

**Full Feature Delivers**:
- Everything in MVP
- Fast cached loading (< 200ms for cached images)
- Verified support for both custom and Gravatar photos
- 70%+ test coverage
- Performance validated with 100+ contacts

### Incremental Delivery Checkpoints

1. **Checkpoint 1** (After Phase 2): Foundation ready - can demonstrate Contact model with avatar fields
2. **Checkpoint 2** (After Phase 3): US1 complete - can demonstrate photo loading with auth
3. **Checkpoint 3** (After Phase 4): MVP complete - can demonstrate full graceful fallback experience
4. **Checkpoint 4** (After Phase 5): Performance ready - can demonstrate fast cached loading
5. **Checkpoint 5** (After Phase 6): Full feature - both photo types verified
6. **Checkpoint 6** (After Phase 7): Production ready - 70%+ test coverage achieved
7. **Checkpoint 7** (After Phase 8): Polished - ready for PR submission

---

## Estimated Timeline

| Phase | Duration | Total | Notes |
|-------|----------|-------|-------|
| Setup & Branch | 10 min | 0.17 hr | Create branch and directories |
| Foundational | 45 min | 1 hr | Contact model updates, Color helper |
| US1 - View Photos | 1.75 hr | 2.75 hr | AuthenticatedImageLoader, ImageLoader, AvatarView, integration |
| US2 - Graceful Fallback | 30 min | 3.25 hr | InitialsAvatarView, fallback integration |
| US3 - Fast Loading | 30 min | 3.75 hr | Cache verification and optimization |
| US4 - Both Types | 30 min | 4.25 hr | Gravatar handling verification |
| Testing | 1.5 hr | 5.75 hr | Unit tests (70%+ coverage), integration tests, manual testing |
| Polish | 30 min | 6.25 hr | Cache cleanup, accessibility, profiling, docs |

**Total: 4-6 hours** (6.25 hours with full testing and polish)

**MVP Only (US1 + US2)**: ~3.25 hours
**Full Feature**: ~6.25 hours

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label (US1, US2, US3, US4) maps task to specific user story for traceability
- MVP = US1 + US2 (both P1 priority)
- Full feature = MVP + US3 + US4 (P2 priority)
- Each user story should be independently testable
- Tests are MANDATORY per constitution (70%+ coverage)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Use exact file paths from plan.md structure
- Bearer token authentication assumed for photos - validate with real API (T083)
- Update OpenAPI spec if API differs (T084) per constitution principle 11
