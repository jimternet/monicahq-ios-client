# Implementation Plan: Financial Debt Tracking

**Branch**: `007-debt-tracking` | **Date**: 2025-12-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-debt-tracking/spec.md`

## Summary

Implement comprehensive debt tracking feature allowing users to record, view, and manage financial obligations with contacts. Users can log debts with amounts, currencies, and reasons; view per-contact and global debt summaries; mark debts as settled; and edit/delete records. API verified against Monica v4.x source code at `/tmp/monica-v4/`.

## Technical Context

**Language/Version**: Swift 5.5+ with async/await
**Primary Dependencies**: SwiftUI, Foundation, Monica v4.x Debts API (zero external dependencies)
**Storage**: Backend-only (Monica API), no local persistence
**Testing**: XCTest for ViewModels and API layer
**Target Platform**: iOS 15+
**Project Type**: Mobile (iOS client for Monica CRM)
**Performance Goals**: Debt history loads within 2 seconds for 50+ records
**Constraints**: Backend-only architecture, no offline support, HTTPS-only API communication
**Scale/Scope**: Per-contact debt lists and global summary view

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Privacy & Security First | ✅ Pass | All debt data transmitted over HTTPS via Monica API; no local persistence |
| 2. Read-Only Simplicity (MVP) | ⚠️ Justified | Write operations required for debt tracking; architecture already supports writes |
| 3. Native iOS Experience | ✅ Pass | SwiftUI with native iOS patterns (List, NavigationStack, sheets) |
| 4. Clean Architecture | ✅ Pass | MVVM pattern: DebtViewModel, DebtAPIService, Views separated |
| 5. API-First Design | ✅ Pass | Verified against Monica v4.x source at `/tmp/monica-v4/` |
| 6. Performance & Responsiveness | ✅ Pass | Lazy loading, pagination for large debt lists |
| 7. Testing Standards | ✅ Pass | Unit tests for ViewModel and API layer |
| 8. Code Quality | ✅ Pass | Result types for errors, structs for models, no force unwraps |
| 9. Documentation | ✅ Pass | Inline comments for non-obvious logic only |
| 10. Decision-Making | ✅ Pass | Following spec clarifications from user |
| 11. API Documentation Accuracy | ✅ Pass | Will update OpenAPI if API discrepancies found |

## Project Structure

### Documentation (this feature)

```text
specs/007-debt-tracking/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
MonicaClient/
├── Features/
│   └── DebtTracking/
│       ├── Models/
│       │   └── Debt.swift              # Already exists in Models/Contact.swift
│       ├── Services/
│       │   └── DebtAPIService.swift    # NEW: Debt-specific API service
│       ├── ViewModels/
│       │   └── DebtViewModel.swift     # NEW: MVVM ViewModel
│       └── Views/
│           ├── DebtListView.swift      # NEW: Per-contact debt list
│           ├── DebtFormView.swift      # NEW: Create/edit debt
│           ├── DebtRowView.swift       # NEW: Single debt row
│           ├── DebtSummaryView.swift   # NEW: Net balance display
│           └── GlobalDebtsView.swift   # NEW: All debts across contacts
├── Models/
│   └── Contact.swift                    # Already has Debt model (needs update)
├── Services/
│   └── MonicaAPIClient.swift            # Already has debt CRUD methods
└── Views/
    └── ContactDetailView.swift          # Integration point for debt section

MonicaClientTests/
└── Features/
    └── DebtTracking/
        ├── DebtViewModelTests.swift     # NEW
        └── DebtAPIServiceTests.swift    # NEW
```

**Structure Decision**: Feature module pattern under `Features/DebtTracking/` following existing patterns (ConversationTracking, CallLogging). Reuses existing Debt model from Contact.swift with enhancements.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Write operations (Principle 2) | Core feature requires CRUD on debts | Read-only would make debt tracking useless |
