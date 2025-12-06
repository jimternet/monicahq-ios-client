# Implementation Plan: Contact Relationships Management

**Branch**: `008-contact-relationships` | **Date**: 2025-12-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-contact-relationships/spec.md`

## Summary

Implement full CRUD operations for contact relationships, enabling users to define, view, edit, and delete connections between contacts with bidirectional relationship support. The feature builds on existing read-only relationship display to add create, edit, and delete capabilities with proper validation and reverse relationship inference.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await
**Primary Dependencies**: SwiftUI, Foundation, Monica v4.x Relationships API (zero external dependencies)
**Storage**: Backend-only (Monica API), no local persistence
**Testing**: XCTest, manual device testing
**Target Platform**: iOS 16+
**Project Type**: Mobile (iOS native SwiftUI)
**Performance Goals**: Relationship operations complete in <2 seconds, type picker loads in <1 second
**Constraints**: Must handle bidirectional relationships correctly, infer gendered reverse types from contact gender field
**Scale/Scope**: ~20 relationships per contact typical, ~50 relationship types

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Privacy & Security First | ✅ Pass | All data via HTTPS API, no local sensitive storage |
| 2. Read-Only Simplicity (MVP Phase) | ⚠️ Deviation | Adding write operations post-MVP; justified as planned extension |
| 3. Native iOS Experience | ✅ Pass | SwiftUI with iOS HIG patterns |
| 4. Clean Architecture | ✅ Pass | MVVM pattern, separated API/ViewModel/View layers |
| 5. API-First Design | ✅ Pass | Using Monica public API endpoints |
| 6. Performance & Responsiveness | ✅ Pass | Lazy loading, cached relationship types |
| 7. Testing Standards | ✅ Pass | Unit tests for ViewModel logic |
| 8. Code Quality | ✅ Pass | Result types, no force unwraps |
| 9. Documentation | ✅ Pass | Inline comments for non-obvious logic |
| 10. Decision-Making | ✅ Pass | User experience prioritized |
| 11. API Documentation Accuracy | ✅ Pass | Will update OpenAPI if discrepancies found |

## Project Structure

### Documentation (this feature)

```text
specs/008-contact-relationships/
├── plan.md              # This file
├── research.md          # Phase 0 output - API verification
├── data-model.md        # Phase 1 output - Entity definitions
├── quickstart.md        # Phase 1 output - Developer guide
├── contracts/           # Phase 1 output - OpenAPI spec
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
MonicaClient/
├── Features/
│   └── ContactRelationships/     # NEW: Feature module
│       ├── Models/
│       │   └── RelationshipEnums.swift
│       ├── Services/
│       │   └── RelationshipAPIService.swift
│       ├── ViewModels/
│       │   └── RelationshipViewModel.swift
│       └── Views/
│           ├── RelationshipFormView.swift
│           ├── RelationshipListView.swift
│           ├── RelationshipTypePicker.swift
│           └── ContactSearchView.swift
├── Models/
│   └── Contact.swift             # EXISTING: Already has Relationship, RelationshipType models
├── Services/
│   └── MonicaAPIClient.swift     # EXISTING: Already has relationship CRUD methods
└── Views/
    └── ContactDetailView.swift   # UPDATE: Add relationship section with add button
```

**Structure Decision**: Feature module pattern under `Features/ContactRelationships/` following existing patterns (DebtTracking, ConversationTracking). Leverages existing models and API methods in MonicaAPIClient.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Post-MVP write operations | Core relationship management value requires create/edit/delete | Read-only doesn't deliver user value for this feature |
