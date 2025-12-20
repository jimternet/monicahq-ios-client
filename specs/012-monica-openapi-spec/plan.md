# Implementation Plan: Monica v4 OpenAPI Specification Generator

**Branch**: `012-monica-openapi-spec` | **Date**: 2025-12-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-monica-openapi-spec/spec.md`

## Summary

Reverse-engineer a complete, accurate OpenAPI 3.0+ specification in JSON format from the Monica v4 PHP codebase by systematically analyzing all API routes, controllers, resources, validation rules, and models. The specification will document ~100+ endpoints across 40 controllers with full request/response schemas, enabling auto-generation of type-safe API clients.

## Technical Context

**Language/Version**: PHP 8.x (Monica v4 source) → JSON (OpenAPI 3.0+ output)
**Primary Dependencies**: Monica v4 codebase at `/tmp/monica-v4`, Laravel framework patterns
**Storage**: N/A (static specification generation)
**Testing**: OpenAPI validators (spectral, swagger-cli), live API comparison
**Target Platform**: Documentation artifact (openapi-monica-{version}.json)
**Project Type**: Single deliverable (OpenAPI specification file)
**Performance Goals**: N/A (one-time generation)
**Constraints**: 100% endpoint coverage, 100% schema accuracy
**Scale/Scope**: ~100+ endpoints, 40 controllers, 45 resources, 65 models

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| 1. Privacy & Security First | ✅ PASS | Spec documents public API, no private data |
| 2. Read-Only Simplicity | ✅ PASS | Documentation artifact, no runtime code |
| 3. Native iOS Experience | ⚪ N/A | Not an iOS UI feature |
| 4. Clean Architecture | ✅ PASS | Well-organized spec structure |
| 5. API-First Design | ✅ PASS | **Core alignment** - Documents Monica's API contract |
| 6. Performance & Responsiveness | ⚪ N/A | Static artifact |
| 7. Testing Standards | ✅ PASS | Validated via OpenAPI validators + live API tests |
| 8. Code Quality | ✅ PASS | Follows OpenAPI 3.0+ standards |
| 9. Documentation | ✅ PASS | **Core purpose** - Creates authoritative API docs |
| 10. Decision-Making | ✅ PASS | Simplicity prioritized (JSON-only, single file) |
| 11. API Documentation Accuracy | ✅ PASS | **Primary goal** - Creates/updates monica-api-openapi.yaml |

**Gate Status**: ✅ PASSED - Feature directly supports Constitution Principle 11 (API Documentation Accuracy)

## Project Structure

### Documentation (this feature)

```text
specs/012-monica-openapi-spec/
├── plan.md              # This file
├── research.md          # Phase 0: API pattern analysis
├── data-model.md        # Phase 1: Entity/schema inventory
├── quickstart.md        # Phase 1: How to use the spec
├── contracts/           # Phase 1: OpenAPI component templates
└── tasks.md             # Phase 2: Implementation tasks
```

### Source Code (repository root)

```text
docs/
└── monica-api-openapi.json   # Primary deliverable (OpenAPI 3.0+ JSON)
```

**Structure Decision**: Single output file at `docs/monica-api-openapi.json`, versioned to match Monica v4.x release. No source code changes required - this is a documentation artifact.

## Complexity Tracking

> No violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | - | - |

---

## Phase 0: Research

### Research Tasks

1. **Monica v4 API Route Inventory** - Extract complete endpoint list from `routes/api.php`
2. **Laravel Resource Pattern Analysis** - Understand how Resources transform Models to JSON
3. **Validation Rule Extraction** - Map controller/service validation to request schemas
4. **Error Response Patterns** - Document error codes and response structures
5. **Pagination & Query Parameter Patterns** - Identify common patterns across endpoints
6. **File Upload Handling** - Document multipart endpoints (photos, documents)

### Research Output

See: [research.md](./research.md)

---

## Phase 1: Design

### Data Model

See: [data-model.md](./data-model.md)

### Contracts

See: [contracts/](./contracts/)

### Quickstart

See: [quickstart.md](./quickstart.md)
