# Implementation Plan: Conversation Tracking

**Branch**: `005-conversation-tracking` | **Date**: 2025-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-conversation-tracking/spec.md`

## Summary

Implement conversation tracking feature for Monica iOS Client, enabling users to record in-person, email, and text conversations with contacts including timestamps and detailed notes. Following the backend-only architecture established by call logging, this feature syncs directly with Monica's Conversations API with no local persistence, providing multi-channel communication tracking alongside phone call history.

**Technical Approach**: MVVM architecture with SwiftUI views and direct API integration using the Monica v4.x Conversations API. Conversations are created, retrieved, updated, and deleted directly via API calls with no offline support, matching the call logging implementation pattern for consistency.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await support
**Primary Dependencies**: SwiftUI, Foundation, Monica v4.x Conversations API (zero external dependencies)
**Storage**: Backend-only (Monica API), no local persistence
**Testing**: XCTest for ViewModels and API logic (deferred to post-MVP per constitution)
**Target Platform**: iOS 15+
**Project Type**: Mobile (iOS native)
**Performance Goals**: <2s conversation history load, <30s to log conversation with notes
**Constraints**: Backend-only architecture, no offline support, network-dependent
**Scale/Scope**: Support 1000+ conversation logs per contact without performance degradation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Compliance Analysis

✅ **Privacy & Security First**: Conversations stored on user's Monica instance, HTTPS communication, API token authentication
✅ **Read-Only Simplicity (MVP Phase)**: Architecture supports CRUD operations via Monica API, follows established backend-only pattern
✅ **Native iOS Experience**: SwiftUI with native List, Form, NavigationStack patterns matching call logging
✅ **Clean Architecture**: MVVM with separated API service, ViewModel, and Views (no storage layer needed)
✅ **API-First Design**: Direct Monica Conversations API integration at `/api/conversations`
✅ **Performance & Responsiveness**: API calls with loading states, optimistic UI updates, error handling
✅ **Testing Standards**: Unit test structure ready (deferred to post-MVP per principle 7)
✅ **Code Quality**: Result types for error handling, no force unwraps, Swift naming conventions
✅ **Documentation**: Inline comments for API integration logic, file headers for all components
✅ **Decision-Making**: User experience prioritized (empty states, loading indicators, error messages, quick logging)
✅ **API Documentation Accuracy**: Will verify and update `docs/monica-api-openapi.yaml` for Conversations API endpoints

**Gates Status**: ✅ All gates passed - no violations requiring justification

## Project Structure

### Documentation (this feature)

```text
specs/005-conversation-tracking/
├── spec.md              # Feature specification (completed via /speckit.specify)
├── plan.md              # This file (completed via /speckit.plan)
├── data-model.md        # Phase 1 data model (will be created)
├── contracts/           # API contracts (will be created)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

Note: research.md and quickstart.md omitted as conversation tracking follows established patterns from call logging (004-call-logging).

### Source Code (repository root)

```text
MonicaClient/
├── Models/
│   └── Conversation.swift                          # API response/request model
│
└── Features/ConversationTracking/
    ├── Services/
    │   └── ConversationAPIService.swift            # Monica Conversations API integration
    │
    ├── ViewModels/
    │   └── ConversationViewModel.swift             # Business logic & form state
    │
    └── Views/
        ├── ConversationListView.swift              # List of conversations
        ├── ConversationRowView.swift               # Individual row display
        └── ConversationFormView.swift              # Create/edit form
```

**Structure Decision**: Feature-based organization under `Features/ConversationTracking/` follows existing project patterns (Features/Contacts, Features/CallLogging). API models live in `Models/` alongside other entities. No Storage layer needed due to backend-only architecture - API service communicates directly with Monica Conversations API.

## Complexity Tracking

No constitution violations - complexity is minimal and justified:
- **Backend-only architecture**: Matches call logging pattern, reduces MVP scope per Principle 2 (Read-Only Simplicity)
- **MVVM pattern**: Standard iOS architecture per Principle 4 (Clean Architecture)
- **Direct API integration**: Simplest approach for backend-only data, no sync complexity

## Phase 1: Data Model & Contracts

### API Models

#### Conversation (Codable)

**Purpose**: API response/request model for Monica Conversations API

```swift
struct Conversation: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?  // Optional: categorizes conversation type
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Field Definitions**:
- `id`: Server-assigned unique identifier
- `contactId`: Foreign key to Contact
- `happenedAt`: Timestamp when conversation occurred (ISO 8601)
- `contactFieldTypeId`: Optional category for conversation type (in-person, email, text, etc.)
- `notes`: Free-form text describing conversation content (max 10,000 characters per spec)
- `createdAt`: Server timestamp when record was created
- `updatedAt`: Server timestamp when record was last modified

---

#### ConversationCreateRequest (Encodable)

**Purpose**: Request payload for creating new conversations

```swift
struct ConversationCreateRequest: Encodable {
    let contactId: Int
    let happenedAt: Date
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}
```

---

#### ConversationUpdateRequest (Encodable)

**Purpose**: Request payload for updating existing conversations

```swift
struct ConversationUpdateRequest: Encodable {
    let happenedAt: Date?
    let contactFieldTypeId: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case happenedAt = "happened_at"
        case contactFieldTypeId = "contact_field_type_id"
        case notes
    }
}
```

---

### API Contracts

See [contracts/conversations-api.md](./contracts/conversations-api.md) for full API contract documentation.
