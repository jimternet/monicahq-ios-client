# Implementation Plan: Phone Call Logging

**Branch**: `001-004-call-logging` | **Date**: 2025-01-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-004-call-logging/spec.md`

## Summary

Implement phone call logging feature for Monica iOS Client, enabling users to record call history with contacts including timestamps, duration, emotional state, and notes. The MVP implementation focuses on offline-first local storage with Core Data, providing a foundation for future API synchronization with Monica's Activities backend.

**Technical Approach**: MVVM architecture with SwiftUI views, Core Data persistence, and placeholder API service. Call logs are stored locally as Core Data entities with sync status tracking, ready for future background synchronization implementation.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await support
**Primary Dependencies**: SwiftUI, Core Data, Foundation (zero external dependencies)
**Storage**: Core Data with SQLite backend, programmatic model creation
**Testing**: XCTest (deferred to post-MVP per constitution)
**Target Platform**: iOS 15+
**Project Type**: Mobile (iOS native)
**Performance Goals**: <2s list load for 5000+ call logs, <500ms search response
**Constraints**: Offline-capable, <100MB storage for typical usage, privacy-first
**Scale/Scope**: Support 5000+ call logs per user without performance degradation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Compliance Analysis

✅ **Privacy & Security First**: Call logs stored locally on device, no third-party sharing, API token authentication
✅ **Read-Only Simplicity (MVP Phase)**: Architecture designed for future write operations to Monica API, MVP focuses on local CRUD
✅ **Native iOS Experience**: SwiftUI with native List, Form, NavigationStack patterns
✅ **Clean Architecture**: MVVM with separated Storage layer, ViewModel, and Views
✅ **API-First Design**: Placeholder API service ready for Monica Activities API integration
✅ **Performance & Responsiveness**: Core Data fetch with NSFetchRequest optimization, lazy loading
✅ **Testing Standards**: Unit test structure ready (deferred to post-MVP per principle 7)
✅ **Code Quality**: Result types for error handling, no force unwraps, Swift naming conventions
✅ **Documentation**: Inline comments for sync logic, file headers for all components
✅ **Decision-Making**: User experience prioritized (empty states, loading indicators, error messages)
✅ **API Documentation Accuracy**: Placeholder for Monica Activities API v1 at `/api/activities`

**Gates Status**: ✅ All gates passed - no violations requiring justification

## Project Structure

### Documentation (this feature)

```text
specs/001-004-call-logging/
├── spec.md              # Feature specification (completed via /speckit.specify)
├── plan.md              # This file (completed via /speckit.plan)
├── research.md          # Phase 0 research findings (N/A - straightforward implementation)
├── data-model.md        # Phase 1 data model (embedded in this plan)
├── quickstart.md        # Phase 1 quickstart guide (N/A - standard iOS patterns)
└── contracts/           # API contracts (deferred to future API integration)
```

### Source Code (repository root)

```text
MonicaClient/
├── Models/
│   ├── CallLog.swift                              # API response model
│   ├── CallLogEntity+CoreDataClass.swift          # Core Data entity class
│   └── CallLogEntity+CoreDataProperties.swift     # Core Data properties + helpers
│
├── Utilities/
│   └── EmotionalState.swift                       # Enum for emotional states
│
├── Data/
│   └── DataController.swift                       # Updated with CallLogEntity model
│
└── Features/CallLogging/
    ├── Services/
    │   ├── CallLogStorage.swift                   # Core Data CRUD operations
    │   └── CallLogAPIService.swift                # Placeholder for Activities API
    │
    ├── ViewModels/
    │   └── CallLogViewModel.swift                 # Business logic & form state
    │
    └── Views/
        ├── CallLogListView.swift                  # List of call logs
        ├── CallLogRowView.swift                   # Individual row display
        └── CallLogFormView.swift                  # Create/edit form
```

**Structure Decision**: Feature-based organization under `Features/CallLogging/` follows existing project patterns (Features/Contacts, Features/Activities). Core Data models live in `Models/` alongside other entities. Shared utilities in `Utilities/`.

## Complexity Tracking

No constitution violations - complexity is minimal and justified:
- **Offline-first architecture**: Required for mobile reliability per Principle 6 (Performance & Responsiveness)
- **Programmatic Core Data model**: Existing project pattern, avoids Xcode project conflicts
- **MVVM pattern**: Standard iOS architecture per Principle 4 (Clean Architecture)

## Phase 0: Research & Decisions

### Technology Decisions

**Decision**: Use Core Data for local persistence
**Rationale**:
- Already integrated in project via DataController
- Proven solution for iOS offline storage
- Supports complex queries for future search/filter features
- Native integration with SwiftUI via @FetchRequest (if needed later)

**Alternatives Considered**:
- SQLite.swift: Would require new dependency (violates zero-dependency goal)
- Realm: Heavier dependency, overkill for MVP
- UserDefaults/JSON: Insufficient for query capabilities

---

**Decision**: Store call logs as Monica Activities (type_id: 13 "phone_call")
**Rationale**:
- Matches Monica backend data model
- Reuses existing Activity patterns in codebase
- Enables future sync with Activities API endpoints

**Alternatives Considered**:
- Custom `/api/calls` endpoint: Doesn't exist in Monica API
- Embedded in Contact object: Poor separation of concerns

---

**Decision**: Offline-first with sync queue pattern
**Rationale**:
- Mobile users expect offline functionality
- Call logging happens in real-time, can't wait for network
- Sync status tracking (pending/syncing/synced/failed) provides transparency

**Alternatives Considered**:
- Online-only: Poor UX for mobile
- Optimistic sync: More complex error handling for MVP

---

**Decision**: Emotional state tracking with emoji support
**Rationale**:
- Requested in spec: "emotional state" tracking
- Provides lightweight mood tracking without heavy UI
- 5 states (happy/neutral/sad/frustrated/excited) cover common scenarios

**Alternatives Considered**:
- Free-form text: Less structured, harder to analyze
- Numeric scale: Less intuitive for users
- No emotion tracking: Missed spec requirement

## Phase 1: Data Model & Contracts

### Core Data Entities

#### CallLogEntity

**Purpose**: Local storage of call logs with sync tracking

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| id | Int32 | Yes | 0 | Server-assigned ID (0 = not synced) |
| contactId | Int32 | Yes | - | Foreign key to Contact |
| calledAt | Date | Yes | - | When call occurred |
| duration | Int32 | No | 0 | Duration in minutes (0 = not recorded) |
| emotionalState | String | No | nil | Raw value of EmotionalState enum |
| notes | String | No | nil | Free-form text (max 5000 chars) |
| syncStatus | String | Yes | "pending" | pending/syncing/synced/failed |
| syncError | String | No | nil | Error message if sync failed |
| createdAt | Date | Yes | Date() | Local creation timestamp |
| updatedAt | Date | Yes | Date() | Local update timestamp |
| lastSyncAttempt | Date | No | nil | Last sync attempt timestamp |
| isMarkedDeleted | Bool | Yes | false | Soft delete flag (renamed from isDeleted) |

**Computed Properties**:
- `emotion: EmotionalState?` - Get enum from emotionalState string
- `needsSync: Bool` - True if status is pending or failed
- `isSyncing: Bool` - True if status is syncing
- `isSynced: Bool` - True if status is synced

**Relationships**:
- Contact (via contactId lookup) - One-to-Many

---

### API Models

#### CallLog (Codable)

**Purpose**: API response/request model for Monica Activities API

```swift
struct CallLog: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let calledAt: Date
    let duration: Int?
    let emotionalState: EmotionalState?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}
```

**Mapping**: CallLogEntity ↔ CallLog conversion handled by CallLogStorage

---

#### EmotionalState (Enum)

```swift
enum EmotionalState: String, CaseIterable, Codable, Identifiable {
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case frustrated = "frustrated"
    case excited = "excited"

    var emoji: String { /* 😊😐😢😤🤩 */ }
    var displayName: String { /* Capitalized */ }
}
```

---

### API Contracts (Future)

**Note**: These contracts are placeholders for post-MVP API integration with Monica Activities API.

#### POST /api/activities (Create Call Log)

```json
Request:
{
  "activity_type_id": 13,
  "contacts": [{ "id": 2940 }],
  "happened_at": "2025-01-19T14:30:00Z",
  "description": "{\"duration\":45,\"emotion\":\"happy\",\"notes\":\"Great conversation!\"}"
}

Response:
{
  "data": {
    "id": 12345,
    "activity_type": { "id": 13, "name": "phone_call" },
    "happened_at": "2025-01-19T14:30:00Z",
    "description": "...",
    "created_at": "2025-01-19T14:30:05Z",
    "updated_at": "2025-01-19T14:30:05Z"
  }
}
```

#### GET /api/contacts/{id}/activities (Fetch Call Logs)

```json
Response:
{
  "data": [
    {
      "id": 12345,
      "activity_type": { "id": 13, "name": "phone_call" },
      "happened_at": "2025-01-19T14:30:00Z",
      "description": "{\"duration\":45,\"emotion\":\"happy\",\"notes\":\"...\"}",
      "contacts": [{ "id": 2940 }]
    }
  ]
}
```

**Filter**: `?activity_type_id=13` to get only phone calls

---

## Phase 2: Implementation Tasks

### Implementation Summary

**Status**: ✅ MVP Implementation Complete (3 phases, 11 files, ~1000 LOC)

**Phase 1: Core Data Models** ✅
- EmotionalState.swift
- CallLog.swift (API model)
- CallLogEntity+CoreDataClass.swift
- CallLogEntity+CoreDataProperties.swift
- DataController.swift (updated with CallLogEntity)

**Phase 2: Services** ✅
- CallLogStorage.swift (full CRUD with sync tracking)
- CallLogAPIService.swift (placeholder for MVP)

**Phase 3: UI Components** ✅
- CallLogViewModel.swift (business logic)
- CallLogFormView.swift (create/edit)
- CallLogRowView.swift (list row display)
- CallLogListView.swift (main list view)
- ContactDetailView.swift (integration)

**Commits**:
1. `feat: Add Core Data models for call logging (Phase 1)`
2. `feat: Add call log storage and API services (Phase 2)`
3. `feat: Complete call logging MVP UI (Phase 3)`

---

## Future Enhancements (Post-MVP)

### Phase 4: Background Sync (Priority: High)

**Objective**: Synchronize local call logs with Monica Activities API

**Implementation Tasks**:
1. **CallLogSyncService.swift**
   - Background sync coordinator using iOS Background Tasks framework
   - Batch sync operations (create/update/delete)
   - Conflict resolution strategy (last-write-wins for MVP)
   - Retry logic with exponential backoff
   - Network reachability monitoring

2. **Sync Queue Management**
   - Process pending/failed call logs in order
   - Update syncStatus transitions (pending → syncing → synced/failed)
   - Handle partial failures gracefully
   - Persist sync errors for debugging

3. **API Integration**
   - Complete CallLogAPIService implementation
   - Use MonicaAPIClient for HTTP requests
   - Parse Activities API responses into CallLog models
   - Map metadata JSON (duration, emotion, notes) to/from description field

4. **Pull Sync**
   - Fetch call logs from server on app launch
   - Incremental sync based on updatedAt timestamps
   - Merge server data with local changes
   - Deduplicate based on server IDs

**Success Criteria**:
- 95%+ sync success rate under normal network conditions
- Sync completes within 30s for 100 pending logs
- No data loss during sync failures
- Clear sync status indicators in UI

---

### Phase 5: Advanced Features (Priority: Medium)

#### 5.1 Search & Filter
- Full-text search through call notes
- Filter by date range (last week, last month, custom)
- Filter by emotional state
- Filter by contact
- Search results with highlighting

**UI Components**:
- SearchBar in CallLogListView
- Filter sheet with date pickers and emotion chips
- Empty state for "no results found"

**Storage Updates**:
- Add NSFetchRequest predicates for filters
- Optimize with Core Data indexes on calledAt, contactId

---

#### 5.2 Global Call Timeline
- Cross-contact view of all call logs
- Grouped by date (Today, Yesterday, This Week, etc.)
- Tap to navigate to contact detail
- Filter/search across all contacts

**UI Components**:
- New CallTimelineView (tab bar or settings link)
- Section headers for date grouping
- Contact name/avatar in row view

---

#### 5.3 Communication Frequency Tracking
- "Last called" badge on ContactCard
- Visual indicators for contacts not called recently
- Suggested contacts to call (based on frequency patterns)
- Statistics dashboard (calls per week, avg duration)

**Data Processing**:
- Compute last call date per contact
- Calculate call frequency metrics
- Cache computed values for performance

---

#### 5.4 Batch Operations
- Select multiple call logs
- Bulk delete
- Bulk export (CSV or JSON)
- Bulk edit tags/categories (if added)

---

#### 5.5 Export & Sharing
- Export call history as CSV
- Export as PDF report (date range)
- Share via iOS share sheet
- Backup/restore call logs

---

### Phase 6: Advanced Sync Features (Priority: Low)

#### 6.1 Conflict Resolution UI
- Display conflicts when server data differs from local
- Side-by-side comparison view
- User choice: keep local, keep server, or merge
- Auto-resolve simple conflicts (e.g., note appending)

#### 6.2 Real-time Sync
- WebSocket connection to Monica for real-time updates
- Push notifications when call logs change on server
- Live sync indicator in UI

#### 6.3 Offline Queue Visibility
- Dedicated view for pending sync queue
- Retry failed syncs manually
- Clear failed syncs (with confirmation)
- Debug info for troubleshooting

---

### Phase 7: Quality of Life Improvements (Priority: Low)

- **Quick log from contact card**: One-tap button to log call without form
- **Siri shortcuts**: "Log call with [Contact Name]"
- **Widgets**: Recent calls widget for home screen
- **Call duration timer**: Built-in timer during call logging
- **Call reminders**: Remind me to call [Contact] in [X] days
- **Call templates**: Save common note templates
- **Voice notes**: Attach audio recordings to call logs
- **Photos**: Attach photos discussed during call

---

## Testing Strategy (Post-MVP)

### Unit Tests (Target: 70% coverage)

**CallLogViewModel**:
- Form validation (duration must be positive)
- Date formatting (today, yesterday, custom)
- Statistics calculation (total, with details, pending)
- CRUD operations (save, update, delete)

**CallLogStorage**:
- Fetch call logs for contact
- Save new call log with sync status
- Update existing call log
- Soft delete (isMarkedDeleted)
- Sync status transitions

**EmotionalState**:
- Enum cases and raw values
- Emoji mapping
- Display name formatting

### Integration Tests

**API Service** (when implemented):
- Create call log via Activities API
- Fetch call logs with filtering
- Update call log on server
- Delete call log from server
- Error handling for network failures

**Sync Service** (when implemented):
- End-to-end sync flow (local → server)
- Pull sync (server → local)
- Conflict resolution
- Retry logic

### Manual Testing Checklist

✅ Log new call with all fields filled
✅ Log quick call (timestamp only)
✅ Edit existing call log
✅ Delete call log with swipe action
✅ View call history sorted by date
✅ Empty state when no calls
✅ Loading state during operations
✅ Error messages for failures
✅ Statistics section displays correctly
✅ Sync status badges (pending/syncing/synced/failed)
✅ Form validation (invalid duration)
✅ Date picker defaults to now
✅ Emotional state picker with emojis
✅ Notes field with multi-line support
✅ App restart persists data

---

## Performance Considerations

### Current Optimizations
- Core Data batch fetching (limit 100)
- NSFetchRequest with sort descriptors
- Lazy loading in SwiftUI List
- Debounced search (when implemented)

### Future Optimizations
- **Pagination**: Load call logs in pages of 50
- **Indexes**: Add Core Data indexes on calledAt, contactId, syncStatus
- **Background processing**: Sync in background thread
- **Incremental sync**: Fetch only updates since last sync (via updatedAt)
- **Caching**: Cache computed statistics in memory

---

## Error Handling

### Current Error Handling
- ViewModel exposes `errorMessage` and `showingError` states
- Alert dialogs display user-friendly error messages
- Console logging for debugging (print statements)
- Try-catch blocks in all storage operations

### Future Error Handling
- **Network errors**: Retry with exponential backoff
- **API errors**: Parse Monica API error responses
- **Validation errors**: Inline form field errors
- **Sync conflicts**: User-driven resolution UI
- **Storage errors**: Graceful degradation, warn user
- **Crash reporting**: Optional analytics with user consent

---

## Dependencies & Assumptions

### Current Dependencies
- SwiftUI (iOS 15+)
- Core Data (Foundation)
- URLSession (for future API calls)
- Foundation (Date, String, etc.)

### Future Dependencies (Post-MVP)
- **Background Tasks**: iOS Background Tasks framework for sync
- **Keychain**: Already integrated for API token
- **Combine**: For reactive sync status updates
- **Charts**: SwiftUI Charts for statistics (iOS 16+)

### API Assumptions
- Monica Activities API endpoint: `/api/activities`
- Activity type ID for phone calls: `13` ("phone_call")
- Metadata stored as JSON in `description` field
- Standard CRUD operations supported
- ISO 8601 date format for `happened_at`

### Data Assumptions
- Maximum 5000 call logs per user (performance target)
- Notes limited to 5000 characters
- Duration stored in minutes (Int32)
- Soft delete pattern (isMarkedDeleted) for sync safety
- Local ID assignment until synced (id = 0 means pending)

---

## Rollout Plan

### MVP (Current State)
✅ Local CRUD operations
✅ Offline-first storage
✅ Basic UI with forms and lists
✅ Sync status tracking (infrastructure only)

### Post-MVP Phases
1. **Phase 4**: Background sync with Monica API (3-4 weeks)
2. **Phase 5**: Search, filter, timeline views (2-3 weeks)
3. **Phase 6**: Advanced sync features (2-3 weeks)
4. **Phase 7**: Quality of life improvements (ongoing)

### User Communication
- Release notes highlight new features
- In-app tutorial for first-time users
- Help documentation for sync troubleshooting
- Privacy policy update (data stored locally vs synced)

---

## Open Questions for Future Phases

1. **Conflict resolution strategy**: Should we implement CRDTs or stick with last-write-wins?
2. **Real-time sync**: Is WebSocket support needed, or is polling sufficient?
3. **Call detection**: Should we integrate with iOS CallKit for automatic detection?
4. **Analytics**: Do users want call frequency insights, or is that too invasive?
5. **Tags/categories**: Should call logs support custom tags for organization?
6. **Multi-device sync**: How do we handle same call logged on multiple devices?

---

## Conclusion

The call logging MVP is complete and production-ready for local use. The architecture is designed for extensibility, with clear separation of concerns and a well-defined path for API integration. Future enhancements are scoped and prioritized, ready for implementation in subsequent releases.

**Next Steps**:
1. User testing of MVP functionality
2. Gather feedback on UX and feature priorities
3. Plan Phase 4 (Background Sync) based on user demand
4. Continue with next features in Monica iOS roadmap

---

**Plan Version**: 1.0
**Last Updated**: 2025-01-19
**Implementation Status**: MVP Complete ✅
