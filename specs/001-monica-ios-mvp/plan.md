# Implementation Plan: Monica iOS Client MVP

**Branch**: `001-monica-ios-mvp` | **Date**: 2025-11-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-monica-ios-mvp/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a native iOS client for Monica CRM that enables users to authenticate, browse, search, and view contacts with related information (activities, notes, tasks, relationships, tags, gifts) in a read-only format. The MVP prioritizes simplicity, privacy, and native iOS experience with SwiftUI, zero external dependencies, and secure Keychain storage for API credentials.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await support
**Primary Dependencies**: SwiftUI, URLSession, Foundation, Security (Keychain) - zero external dependencies for MVP
**Storage**: Keychain for API tokens, UserDefaults for non-sensitive settings, in-memory caching for contacts (offline-first deferred to v2+)
**Testing**: XCTest with minimum 70% coverage for ViewModels and API logic, manual device testing before releases
**Target Platform**: iOS 15+ (iPhone 12 and newer as primary target)
**Project Type**: Mobile (iOS native) - single Xcode project structure
**Performance Goals**:
  - App launch < 2 seconds on average device
  - Contact search results < 500ms
  - Contact list initial load < 2 seconds (50 contacts)
  - Contact detail screen < 1 second
  - Maintain 60fps scrolling with 500+ contacts
**Constraints**:
  - Read-only operations only (MVP)
  - HTTPS-only API communication
  - API timeout 10 seconds
  - <200ms for search responses (with debounce)
  - 100% stability target (zero crashes)
  - Monica API v4.x+ compliance
**Scale/Scope**:
  - Support users with 10-10,000 contacts
  - ~10 screens for MVP
  - Pagination: 50 contacts per page, 10 activities per load
  - Single instance authentication (multi-account in v2+)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle Alignment

| Principle | Status | Notes |
|-----------|--------|-------|
| **1. Privacy & Security First** | ✅ PASS | Keychain for tokens, HTTPS-only, no analytics on sensitive data |
| **2. Read-Only Simplicity (MVP)** | ✅ PASS | MVP is read-only, architecture designed for v2+ write operations |
| **3. Native iOS Experience** | ✅ PASS | SwiftUI, iOS 15+, follows HIG, respects system settings |
| **4. Clean Architecture** | ✅ PASS | MVVM pattern planned, DI for testability, API/Data/UI separation |
| **5. API-First Design** | ✅ PASS | Monica API v4.x compliance, graceful error handling, rate limit respect |
| **6. Performance & Responsiveness** | ✅ PASS | All performance goals defined in Technical Context, 60fps target |
| **7. Testing Standards** | ✅ PASS | 70% coverage target for core logic, XCTest, manual device testing |
| **8. Code Quality** | ✅ PASS | Swift style guide, no force unwraps, Result types for errors |
| **9. Documentation** | ✅ PASS | README, architecture docs, changelog planned |
| **10. Decision-Making** | ✅ PASS | Simplicity over flexibility, GitHub Issues for discussions |
| **11. API Documentation Accuracy** | ✅ PASS | OpenAPI spec updates mandatory when discrepancies found |

### Success Metrics Validation

| Metric | Target | Spec Reference |
|--------|--------|----------------|
| App launch time | < 2 seconds | SC-001 |
| Search response | < 500ms | SC-002 |
| Contact list load | < 2 seconds (50 contacts) | SC-003 |
| Contact detail load | < 1 second | SC-004 |
| Stability | 100% (zero crashes) | SC-005 |
| Auth success rate | 90% first attempt | SC-007 |
| Scrolling performance | 60fps with 500+ contacts | SC-008 |
| Error display | < 1 second | SC-009 |
| API timeout handling | 10 seconds with retry | SC-010 |

**Gate Result**: ✅ **PASS** - All constitutional principles are satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
MonicaClient/                    # Xcode project root
├── Models/                      # Data models
│   ├── Contact.swift
│   ├── Activity.swift
│   ├── Note.swift
│   ├── Task.swift
│   ├── Gift.swift
│   ├── Relationship.swift
│   └── Tag.swift
├── Services/                    # Business logic layer
│   ├── APIService.swift         # Monica API client
│   ├── AuthService.swift        # Authentication & token management
│   ├── KeychainService.swift    # Secure token storage
│   └── ContactService.swift     # Contact-specific operations
├── ViewModels/                  # MVVM ViewModels
│   ├── AuthViewModel.swift
│   ├── ContactListViewModel.swift
│   ├── ContactDetailViewModel.swift
│   └── SettingsViewModel.swift
├── Views/                       # SwiftUI views
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── AuthView.swift
│   ├── Contacts/
│   │   ├── ContactListView.swift
│   │   ├── ContactRowView.swift
│   │   ├── ContactDetailView.swift
│   │   └── ContactSearchBar.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/              # Reusable UI components
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       └── EmptyStateView.swift
├── Utilities/                   # Helper extensions
│   ├── DateFormatter+Extensions.swift
│   ├── String+Extensions.swift
│   └── Result+Extensions.swift
└── App/
    ├── MonicaClientApp.swift    # App entry point
    └── ContentView.swift        # Root view coordinator

MonicaClientTests/               # XCTest suite
├── ViewModelTests/
│   ├── AuthViewModelTests.swift
│   ├── ContactListViewModelTests.swift
│   └── ContactDetailViewModelTests.swift
├── ServiceTests/
│   ├── APIServiceTests.swift
│   ├── AuthServiceTests.swift
│   └── KeychainServiceTests.swift
└── Mocks/
    ├── MockAPIService.swift
    └── MockKeychainService.swift

docs/                            # Documentation
├── architecture.md              # Architecture overview
├── monica-api-openapi.yaml      # Monica API specification
└── README.md                    # Setup & usage guide
```

**Structure Decision**: iOS native single-project structure following MVVM pattern. This aligns with Principle 3 (Native iOS Experience) and Principle 4 (Clean Architecture). SwiftUI views are separated from ViewModels, with a dedicated Services layer for API and authentication logic. Tests mirror the source structure for clarity.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations to justify** - Constitution Check passed completely.

---

## Phase 0: Research (Complete)

**Artifacts Generated**:
- ✅ [research.md](./research.md) - Technical decisions and best practices documented

**Key Research Findings**:
- Swift async/await for all asynchronous operations
- Keychain Services for secure token storage
- MVVM architecture with SwiftUI
- URLSession for API communication (zero external dependencies)
- Result type error handling
- Search debouncing at 300ms
- Pagination: 50 contacts per page with "Load More" button
- XCTest with 70% coverage target for ViewModels/Services

**All NEEDS CLARIFICATION items resolved**: ✅ COMPLETE

---

## Phase 1: Design & Contracts (Complete)

**Artifacts Generated**:
- ✅ [data-model.md](./data-model.md) - Complete data model with entities, relationships, and validation rules
- ✅ [contracts/monica-api-client.md](./contracts/monica-api-client.md) - API contract specifications
- ✅ [quickstart.md](./quickstart.md) - Developer quickstart guide
- ✅ [CLAUDE.md](/CLAUDE.md) - Updated agent context with Swift 5.5+, SwiftUI, and Keychain technologies

**Data Model Summary**:
- **Core Entities**: Contact, Activity, Note, Task, Gift, Tag, Relationship
- **API Wrappers**: APIResponse<T>, PaginationMeta, PaginationLinks
- **Display Models**: ContactDisplayModel with computed properties
- **Validation Rules**: Comprehensive field and business logic validation
- **Caching Strategy**: In-memory with 5-minute TTL, LRU eviction

**API Contracts Summary**:
- Monica API v4.x compliance
- RESTful endpoints for all MVP operations (GET only)
- Bearer token authentication
- Pagination support with limit/offset
- Comprehensive error handling (401, 429, 500, timeouts, network failures)

---

## Post-Design Constitution Check (Phase 1)

*Re-evaluation after completing design artifacts*

### Design Artifact Validation

| Principle | Post-Design Status | Evidence |
|-----------|-------------------|----------|
| **1. Privacy & Security First** | ✅ PASS | Keychain implementation in data-model.md, HTTPS enforcement in contracts |
| **2. Read-Only Simplicity (MVP)** | ✅ PASS | All API contracts are GET operations only, no write endpoints |
| **3. Native iOS Experience** | ✅ PASS | MVVM + SwiftUI architecture detailed in research.md, iOS 15+ target |
| **4. Clean Architecture** | ✅ PASS | Clear layer separation in project structure, DI patterns in research.md |
| **5. API-First Design** | ✅ PASS | Complete API contracts defined, Monica API v4.x compliance validated |
| **6. Performance & Responsiveness** | ✅ PASS | Pagination strategy, caching layer, 60fps optimization in data-model.md |
| **7. Testing Standards** | ✅ PASS | Test structure defined, 70% coverage target, XCTest patterns documented |
| **8. Code Quality** | ✅ PASS | Swift conventions, Result types, no force unwraps in research.md |
| **9. Documentation** | ✅ PASS | All Phase 0 & 1 artifacts complete (research, data-model, contracts, quickstart) |
| **10. Decision-Making** | ✅ PASS | Simplicity prioritized (in-memory over CoreData, native URLSession over Alamofire) |
| **11. API Documentation Accuracy** | ✅ PASS | OpenAPI spec updates planned in research.md and contracts |

### Architecture Validation

**MVVM Pattern Compliance**:
- ✅ Models: Codable structs matching API responses
- ✅ Views: SwiftUI with minimal logic
- ✅ ViewModels: @MainActor ObservableObject with @Published state
- ✅ Services: API, Auth, Keychain separation

**Zero External Dependencies**:
- ✅ URLSession (native) for networking
- ✅ Keychain Services (native) for security
- ✅ SwiftUI (native) for UI
- ✅ XCTest (native) for testing

**Performance Architecture**:
- ✅ Pagination: 50 items per page
- ✅ Caching: In-memory with TTL
- ✅ Lazy loading: Contact details on-demand
- ✅ Debouncing: 300ms for search

**Post-Design Gate Result**: ✅ **PASS** - All design artifacts align with constitutional principles. Architecture is sound and ready for Phase 2 task generation.

---

## Next Steps

The planning phase is complete. To proceed with implementation:

1. **Generate Tasks**: Run `/speckit.tasks` to create actionable task list from this plan
2. **Begin Implementation**: Run `/speckit.implement` to execute tasks systematically
3. **Track Progress**: Use generated `tasks.md` for dependency-ordered implementation

**Phase 2 Ready**: ✅ All prerequisites satisfied for task generation and implementation.
