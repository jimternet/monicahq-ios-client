<!-- Sync Impact Report
Version change: 1.1.0 → 1.2.0
Modified principles: None
Added sections:
  - Principle 11: "API Documentation Accuracy" (new principle requiring OpenAPI spec updates when API discrepancies are discovered)
  - Governance: Added mandate for docs/monica-api-openapi.yaml updates
Removed sections: None
Templates requiring updates:
  ✅ .specify/templates/plan-template.md (verified - no changes needed, constitution check will include new principle)
  ✅ .specify/templates/spec-template.md (verified - no changes needed)
  ✅ .specify/templates/tasks-template.md (verified - no changes needed)
  ✅ .specify/templates/commands/*.md (N/A - no command templates exist)
Follow-up TODOs: None
Bump rationale: MINOR version bump warranted due to:
  - New principle added (API Documentation Accuracy)
  - Expands project governance to cover API documentation maintenance
  - Non-breaking addition that doesn't remove or redefine existing principles
  - Establishes new requirement for docs/monica-api-openapi.yaml maintenance
-->

# Monica iOS Client Constitution

## Project Vision

A lightweight, privacy-first iOS client for Monica CRM that allows users
to browse, search, and view their personal relationship data and assets
on the go, following iOS native conventions and patterns.

## Core Principles

### 1. Privacy & Security First
- User data stays private; no analytics on sensitive content
- All communication with Monica API over HTTPS
- Support both cloud (monicahq.com) and self-hosted instances
- Store minimal data locally; respect user privacy settings
- Never share data with third parties

**Rationale**: Monica CRM handles deeply personal relationship data.
Users must trust that their private information remains secure and
is never monetized or shared.

### 2. Read-Only Simplicity (MVP Phase)
- MVP (v1.0) is read-only to reduce complexity and security surface
- Design architecture to be extensible for write operations in v2+
- Keep feature scope focused; say no to scope creep during MVP
- Post-MVP features planned via specifications but deferred for implementation
- Defer offline-first, real-time sync, and macOS to v2+

**Rationale**: Starting read-only reduces MVP risk while allowing
comprehensive v2+ planning. Architecture MUST support future write
operations without major refactoring.

### 3. Native iOS Experience
- Use SwiftUI and modern iOS conventions (List, NavigationStack, etc.)
- Leverage iOS share sheet and file handling for v2+ (not MVP)
- Respect system-level settings (dark mode, accessibility, dynamic type)
- Follow Apple's Human Interface Guidelines
- Support iOS 15+ (or define minimum version explicitly)

**Rationale**: Users expect native iOS behavior. Cross-platform
frameworks sacrifice quality for convenience—not acceptable for
this project.

### 4. Clean Architecture
- MVVM or similar pattern for testability
- Separate API layer, data layer, and UI concerns
- Use Dependency Injection for testability
- Avoid massive view controllers or spaghetti logic

**Rationale**: Clean separation enables testing, reduces bugs, and
makes future feature additions predictable and safe.

### 5. API-First Design
- Design around Monica's public API; no web scraping
- Handle API errors gracefully with user-friendly messages
- Cache appropriately; respect API rate limits
- Document API assumptions and version requirements

**Rationale**: Monica's API is the contract. Any implementation that
bypasses it creates fragility and security risks.

### 6. Performance & Responsiveness
- List views load quickly (lazy loading, pagination where needed)
- Search is instant or clearly shows loading state
- No janky animations or UI jank
- Profile app startup time; optimize critical paths

**Rationale**: Users abandon apps that feel slow. Performance is a
feature, not an optimization task.

### 7. Testing Standards
- Unit tests for ViewModels and API logic (minimum 70% coverage for core logic)
- Integration tests for API layer
- No tests required for pure SwiftUI views (low ROI)
- Manual testing on device before each release

**Rationale**: Tests prevent regressions but have diminishing returns.
Focus on business logic; skip UI snapshot testing.

### 8. Code Quality
- Follow Swift style guide (clear naming, no abbreviations)
- No force unwraps (!) except in controlled contexts
- Prefer struct/enum over class for value types
- Use Result types for error handling, not exceptions

**Rationale**: Crashes from force unwraps are avoidable. Result types
make error paths explicit and type-safe.

### 9. Documentation
- README: setup, API token, building locally
- Inline comments for non-obvious logic only
- Architecture diagram in docs/
- Changelog for each release

**Rationale**: Code should be self-documenting. Comments explain
"why," not "what." Architecture docs prevent knowledge silos.

### 10. Decision-Making
- Decisions prioritize user experience over engineer preference
- When in doubt, choose simplicity over flexibility
- Use GitHub Issues for design discussions (not Slack)
- Require code review for all PRs before merge

**Rationale**: User value trumps technical elegance. Documented
decisions in Issues create searchable project history.

### 11. API Documentation Accuracy
- When bugs or discrepancies are found in `docs/monica-api-openapi.yaml`
- MUST update the OpenAPI specification to reflect the actual API behavior
- Document discovered API quirks, undocumented endpoints, or field mismatches
- Keep OpenAPI spec synchronized with implementation findings
- All API changes discovered during development MUST be documented

**Rationale**: The OpenAPI specification at `docs/monica-api-openapi.yaml`
serves as the single source of truth for Monica API contracts. When
implementation reveals API behavior that differs from documentation,
the spec must be corrected to prevent propagating misinformation and
to aid future development.

## Success Metrics (MVP)

- App launches in < 2 seconds on average device
- Search returns results in < 500ms
- Zero crashes in testing (target 100% stability)
- Successfully displays contacts from real Monica instances
- Supports authentication (API token)

## Governance

- This constitution supersedes all other practices and conventions
- Amendments require documentation, approval from project lead, and migration plan for affected code
- All pull requests MUST verify compliance with core principles
- Technical debt that violates principles MUST be explicitly justified and tracked for resolution
- Use `.specify/` directory for project-specific runtime development guidance
- Feature specifications follow SpecKit workflow: specify → clarify → plan → tasks → implement
- When API documentation bugs are discovered, updates to `docs/monica-api-openapi.yaml` are mandatory

**Version**: 1.2.0 | **Ratified**: 2025-10-26 | **Last Amended**: 2025-01-19
