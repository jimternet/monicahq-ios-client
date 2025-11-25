# Implementation Plan: Contact Avatar Display with Authentication

**Branch**: `001-003-avatar-authentication` | **Date**: 2025-01-19 | **Spec**: [spec.md](./spec.md)

## Summary

Implement authenticated contact avatar loading in the Monica iOS client to display custom uploaded photos, Gravatar images, and colored initial fallbacks. The feature addresses authentication issues preventing photo URLs from loading, implements two-tier caching for performance, and provides graceful fallback to colored initials when images are unavailable.

**Primary Requirement**: Display contact photos in lists and detail views with Bearer token authentication for custom uploads and graceful fallback to initials.

**Technical Approach**: Custom URLSession-based image loader with protocol abstraction, NSCache (memory) + URLCache (disk) caching, hash-based deterministic initial avatars using Monica's provided colors.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, Foundation (URLSession, NSCache), UIKit (UIImage)
**Storage**: Two-tier caching (NSCache for memory, URLCache for disk), no CoreData
**Testing**: XCTest with 70%+ coverage for ViewModels and service logic
**Target Platform**: iOS 15+
**Project Type**: Mobile (iOS native SwiftUI application)
**Performance Goals**:
- First load: < 2 seconds per image on normal connection
- Cached load: < 200ms from memory/disk
- List scrolling: 60fps with progressive loading
- Memory: < 50MB for 100 cached avatars

**Constraints**:
- Zero external dependencies (no Kingfisher, Nuke, SDWebImage)
- Bearer token authentication required for Monica photo URLs
- Gravatar URLs must work without authentication
- Must handle offline scenarios gracefully
- Follow existing MonicaAPIClient authentication patterns

**Scale/Scope**:
- Support 100+ contacts with avatars
- Handle 4 avatar sources (default initials, photo, gravatar, adorable)
- Cache up to 100 avatars in memory, unlimited on disk (URLCache managed)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Check (Phase 0)

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Privacy & Security First | ✅ PASS | Bearer token auth, secure Keychain storage, no third-party tracking |
| 2. Read-Only Simplicity | ✅ PASS | Photo display only; upload deferred to v2+ |
| 3. Native iOS Experience | ✅ PASS | SwiftUI AsyncImage patterns, respects dark mode |
| 4. Clean Architecture | ✅ PASS | Protocol-based ImageLoader, MVVM separation |
| 5. API-First Design | ✅ PASS | Uses Monica API avatar data from contact.information.avatar |
| 6. Performance & Responsiveness | ✅ PASS | Two-tier caching, progressive loading, 60fps scrolling |
| 7. Testing Standards | ✅ PASS | 70%+ coverage target for ImageLoader and ViewModels |
| 8. Code Quality | ✅ PASS | No force unwraps, Result types, protocol abstractions |
| 9. Documentation | ✅ PASS | Inline docs for cache logic, quickstart.md for integration |
| 10. Decision-Making | ✅ PASS | User value prioritized (visual recognition over text-only) |
| 11. API Documentation Accuracy | ✅ PASS | Will update OpenAPI spec if avatar API differs from docs |

**Result**: ✅ All gates passed. No violations. Proceed to Phase 0 research.

### Post-Design Check (Phase 1)

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Privacy & Security First | ✅ PASS | Research confirmed Bearer token approach, Keychain integration |
| 2. Read-Only Simplicity | ✅ PASS | Display-only implementation, no photo upload endpoints |
| 3. Native iOS Experience | ✅ PASS | SwiftUI components (AvatarView), respects accessibility |
| 4. Clean Architecture | ✅ PASS | AuthenticatedImageLoading protocol, dependency injection |
| 5. API-First Design | ✅ PASS | contact.information.avatar parsed, follows API contract |
| 6. Performance & Responsiveness | ✅ PASS | NSCache + URLCache confirmed optimal for iOS |
| 7. Testing Standards | ✅ PASS | Unit tests for ImageLoader, ViewModel; manual device testing |
| 8. Code Quality | ✅ PASS | Swift optionals, enum state machines, no force unwraps |
| 9. Documentation | ✅ PASS | data-model.md, contracts/avatar-api.md, quickstart.md created |
| 10. Decision-Making | ✅ PASS | Custom solution chosen over dependencies (constitution compliance) |
| 11. API Documentation Accuracy | ⚠️ TODO | Update OpenAPI spec after verifying actual avatar API behavior |

**Result**: ✅ All gates passed. Constitution principle 11 requires OpenAPI spec update after implementation confirms API behavior.

## Project Structure

### Documentation (this feature)

```text
specs/001-003-avatar-authentication/
├── spec.md              # Feature specification (user stories, requirements)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: authentication analysis, iOS patterns
├── data-model.md        # Phase 1 output: Swift models, cache structures
├── quickstart.md        # Phase 1 output: 10-step implementation guide
├── contracts/
│   └── avatar-api.md    # Phase 1 output: Monica API endpoints, auth headers
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT YET CREATED)
```

### Source Code (repository root)

```text
MonicaClient/
├── Models/
│   ├── Contact.swift               # MODIFY: Add avatar computed properties
│   └── AvatarInfo.swift            # NEW: Avatar data from API
├── Services/
│   ├── MonicaAPIClient.swift       # EXISTING: Already has Bearer token auth
│   ├── AuthenticatedImageLoader.swift  # NEW: Custom image loader with auth
│   └── ImageLoader.swift           # NEW: ObservableObject for SwiftUI
├── Views/
│   ├── Components/
│   │   ├── AvatarView.swift        # NEW: Reusable avatar component
│   │   └── InitialsAvatarView.swift # NEW: Fallback initials view
│   ├── ContactsListView.swift      # MODIFY: Integrate AvatarView
│   └── ContactDetailView.swift     # MODIFY: Use AvatarView for header
└── Utilities/
    └── Color+Extensions.swift      # NEW: Hex color parsing

MonicaClientTests/
├── UnitTests/
│   ├── Services/
│   │   ├── AuthenticatedImageLoaderTests.swift  # NEW: Cache, auth tests
│   │   └── ImageLoaderTests.swift               # NEW: State machine tests
│   └── ViewModels/
│       └── AvatarViewModelTests.swift           # NEW: If MVVM wrapper needed
└── IntegrationTests/
    └── AvatarLoadingIntegrationTests.swift      # NEW: End-to-end image load
```

**Structure Decision**: Mobile app (iOS native SwiftUI). Using existing MonicaClient/ directory structure. New Services/ components for image loading, new Views/Components/ for reusable avatar UI. Minimal modifications to existing views (ContactsListView, ContactDetailView) to integrate AvatarView.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. All constitution principles satisfied by design.

## Phase Outputs

### Phase 0: Research (✅ Complete)
- **File**: `research.md` (577 lines)
- **Decisions Made**:
  - Authentication: Bearer token headers (consistent with MonicaAPIClient)
  - Image Library: Custom URLSession (zero dependencies)
  - Caching: NSCache (L1 memory) + URLCache (L2 disk)
  - Fallback: Hash-based initials using Monica's default_avatar_color
- **Key Findings**:
  - Monica API provides avatar data at `contact.information.avatar`
  - Four sources: default, gravatar, adorable (deprecated), photo
  - Gravatar URLs must skip auth headers
  - SwiftUI AsyncImage doesn't support custom auth → need custom loader

### Phase 1: Design & Contracts (✅ Complete)
- **Files Created**:
  - `data-model.md` (15,919 bytes): Swift structs, enums, cache models
  - `contracts/avatar-api.md` (17,792 bytes): API endpoints, auth patterns
  - `quickstart.md` (28,637 bytes): 10-step implementation guide
- **Key Structures**:
  - `AvatarInfo`: Codable struct for API response
  - `AvatarSource`: Enum (default, photo, gravatar, adorable)
  - `AuthenticatedImageLoader`: URLSession-based loader with NSCache
  - `ImageLoader`: ObservableObject for SwiftUI binding
  - `AvatarView`: SwiftUI component with state machine
- **API Contracts**:
  - `GET /api/contacts/{id}` → Returns avatar in `information.avatar`
  - `GET /storage/photos/{filename}` → Requires Bearer token
  - Gravatar: `https://www.gravatar.com/avatar/{hash}` → No auth

### Phase 2: Task Breakdown (⏳ Pending)
- **Next Command**: `/speckit.tasks`
- **Expected Output**: `tasks.md` with dependency-ordered implementation tasks
- **Estimated Tasks**: 15-20 tasks across setup, implementation, testing

## Implementation Timeline

**Total Estimate**: 4-6 hours (based on quickstart.md breakdown)

| Phase | Duration | Tasks |
|-------|----------|-------|
| Setup & Models | 45 min | Update Contact model, create AvatarInfo, Color helper |
| Image Loading | 1.75 hr | AuthenticatedImageLoader, ImageLoader ObservableObject |
| UI Components | 1 hr | AvatarView, InitialsAvatarView, integration |
| Caching & Cleanup | 30 min | URLCache config, logout cache clearing |
| Testing | 1.5 hr | Unit tests (70%+ coverage), integration tests |
| Polish | 30 min | Performance profiling, accessibility check |

## Dependencies

**Internal**:
- MonicaAPIClient (existing): Provides Bearer token, base URL
- KeychainManager (existing): Stores API credentials
- Contact model (existing): Needs avatar-related extensions
- AuthenticationManager (existing): Logout hook for cache clearing

**External**: None (zero-dependency requirement)

**iOS Frameworks**:
- SwiftUI: AvatarView component
- Foundation: URLSession, NSCache, URLCache
- UIKit: UIImage (bridged from Data)

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Monica API avatar data format differs from docs | Medium | High | Verify with real API, update OpenAPI spec (principle 11) |
| Gravatar URLs get auth headers incorrectly | Low | Medium | Check URL host before adding headers |
| Memory pressure from 100+ cached images | Medium | Medium | NSCache auto-evicts, cost limits enforced |
| Slow network causes UI jank | Low | High | Progressive loading, placeholder initials |
| Bearer token expires mid-load | Low | Medium | Use fresh token from MonicaAPIClient per request |

## Success Criteria

**Functional** (from spec.md):
- ✅ SC-001: 95% of contacts with valid photos display successfully
- ✅ SC-002: Cached photos load in < 200ms
- ✅ SC-003: 100% graceful fallback to initials on failures
- ✅ SC-004: 60fps scrolling in contact lists
- ✅ SC-005: Both custom and Gravatar photos display correctly
- ✅ SC-006: Handle 100+ contacts without performance degradation
- ✅ SC-007: First load < 2 seconds on standard mobile connection
- ✅ SC-008: Cached photos persist across app restarts
- ✅ SC-009: Invalid URLs fall back to initials in < 1 second
- ✅ SC-010: Users can visually identify contacts by photo

**Technical**:
- Zero external dependencies
- 70%+ test coverage for ImageLoader and ViewModels
- No force unwraps in image loading logic
- Accessibility labels for all avatar views
- Dark mode support verified

## Next Steps

1. **Run** `/speckit.tasks` to generate task breakdown
2. **Review** tasks.md for dependency ordering
3. **Run** `/speckit.implement` to execute implementation plan
4. **Verify** actual Monica API avatar response format
5. **Update** `docs/monica-api-openapi.yaml` if API differs from documentation (constitution principle 11)
6. **Test** on real Monica instance with various avatar types
7. **Profile** memory usage with 100+ contacts
8. **Submit** PR after all tests pass
