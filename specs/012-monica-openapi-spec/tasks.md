# Tasks: Monica v4 OpenAPI Specification Generator

**Input**: Design documents from `/specs/012-monica-openapi-spec/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No automated tests requested. Validation via OpenAPI validators.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Output file**: `docs/monica-api-openapi.json`
- **Source analysis**: `/tmp/monica-v4/` (Monica v4 PHP codebase)
- **Spec artifacts**: `specs/012-monica-openapi-spec/`

---

## Phase 1: Setup (OpenAPI Specification Foundation)

**Purpose**: Initialize the OpenAPI specification structure with metadata and common components

- [ ] T001 Create base OpenAPI 3.0+ structure in docs/monica-api-openapi.json with info, servers, security sections
- [ ] T002 [P] Add security scheme (Bearer token) in components/securitySchemes
- [ ] T003 [P] Add shared parameters (limitParam, pageParam, sortParam, contactId) in components/parameters
- [ ] T004 [P] Add standard error responses (Unauthorized, NotFound, ValidationError, ServerError) in components/responses
- [ ] T005 [P] Add pagination schemas (PaginationLinks, PaginationMeta) in components/schemas
- [ ] T006 [P] Add error response schema (ErrorResponse) in components/schemas
- [ ] T007 [P] Add delete response schema (DeleteResponse) in components/schemas
- [ ] T008 Define API tags structure for endpoint organization (16 tags: Contacts, Activities, Notes, etc.)

**Checkpoint**: Base specification structure ready with all shared components

---

## Phase 2: Foundational (Core Entity Schemas)

**Purpose**: Document fundamental schemas that most endpoints depend on

**⚠️ CRITICAL**: User story phases depend on these core schemas being complete

- [ ] T009 [P] Add Contact schema with all 50+ fields in components/schemas/Contact
- [ ] T010 [P] Add ContactShort schema (abbreviated contact) in components/schemas/ContactShort
- [ ] T011 [P] Add ContactInformation nested schema (relationships, dates, career, avatar) in components/schemas
- [ ] T012 [P] Add ContactStatistics schema in components/schemas/ContactStatistics
- [ ] T013 [P] Add AccountRef schema in components/schemas/AccountRef
- [ ] T014 [P] Add SpecialDate schema (for birthdate, deceased_date) in components/schemas/SpecialDate
- [ ] T015 [P] Add Avatar schema in components/schemas/Avatar
- [ ] T016 [P] Add Address schema in components/schemas/Address
- [ ] T017 [P] Add Tag schema in components/schemas/Tag
- [ ] T018 [P] Add Note schema in components/schemas/Note
- [ ] T019 [P] Add Activity schema with nested ActivityType in components/schemas/Activity
- [ ] T020 [P] Add ActivityType schema in components/schemas/ActivityType
- [ ] T021 [P] Add Reminder schema in components/schemas/Reminder
- [ ] T022 [P] Add Task schema in components/schemas/Task
- [ ] T023 [P] Add Call schema in components/schemas/Call
- [ ] T024 [P] Add Conversation schema with Message in components/schemas/Conversation
- [ ] T025 [P] Add Gift schema in components/schemas/Gift
- [ ] T026 [P] Add Debt schema in components/schemas/Debt
- [ ] T027 [P] Add LifeEvent schema in components/schemas/LifeEvent
- [ ] T028 [P] Add Photo schema in components/schemas/Photo
- [ ] T029 [P] Add Document schema in components/schemas/Document
- [ ] T030 [P] Add Gender schema in components/schemas/Gender
- [ ] T031 [P] Add Pet schema in components/schemas/Pet
- [ ] T032 [P] Add ContactField schema in components/schemas/ContactField
- [ ] T033 [P] Add RelationshipType schema in components/schemas/RelationshipType
- [ ] T034 [P] Add Relationship schema in components/schemas/Relationship

**Checkpoint**: All core entity schemas defined - endpoint documentation can begin

---

## Phase 3: User Story 1 - Generate Complete OpenAPI Specification (Priority: P1) 🎯 MVP

**Goal**: Document all ~150 API endpoints with correct paths, methods, and basic responses

**Independent Test**: Validate specification with `npx @stoplight/spectral-cli lint docs/monica-api-openapi.json`

### Implementation for User Story 1

#### Contact Endpoints (~15 endpoints)
- [ ] T035 [US1] Add GET /contacts endpoint with pagination in paths/contacts
- [ ] T036 [US1] Add POST /contacts endpoint with CreateContactRequest in paths/contacts
- [ ] T037 [US1] Add GET /contacts/{contact} endpoint in paths/contacts/{contact}
- [ ] T038 [US1] Add PUT /contacts/{contact} endpoint in paths/contacts/{contact}
- [ ] T039 [US1] Add DELETE /contacts/{contact} endpoint in paths/contacts/{contact}
- [ ] T040 [P] [US1] Add PUT /contacts/{contact}/work endpoint
- [ ] T041 [P] [US1] Add PUT /contacts/{contact}/food endpoint
- [ ] T042 [P] [US1] Add PUT /contacts/{contact}/introduction endpoint
- [ ] T043 [P] [US1] Add PUT /contacts/{contact}/avatar endpoint
- [ ] T044 [P] [US1] Add contact sub-resource list endpoints (relationships, addresses, notes, etc.)

#### Tag Endpoints (~9 endpoints)
- [ ] T045 [P] [US1] Add CRUD endpoints for /tags in paths/tags
- [ ] T046 [P] [US1] Add GET /tags/{tag}/contacts endpoint
- [ ] T047 [P] [US1] Add tag management endpoints for contacts (setTags, unsetTags, unsetTag)

#### Note, Task, Reminder Endpoints (~15 endpoints)
- [ ] T048 [P] [US1] Add CRUD endpoints for /notes in paths/notes
- [ ] T049 [P] [US1] Add CRUD endpoints for /tasks in paths/tasks
- [ ] T050 [P] [US1] Add CRUD endpoints for /reminders in paths/reminders
- [ ] T051 [P] [US1] Add GET /reminders/upcoming/{month} endpoint

#### Activity Endpoints (~8 endpoints)
- [ ] T052 [P] [US1] Add CRUD endpoints for /activities in paths/activities
- [ ] T053 [P] [US1] Add CRUD endpoints for /activitytypes in paths/activitytypes
- [ ] T054 [P] [US1] Add CRUD endpoints for /activitytypecategories in paths/activitytypecategories

#### Call and Conversation Endpoints (~10 endpoints)
- [ ] T055 [P] [US1] Add CRUD endpoints for /calls in paths/calls
- [ ] T056 [P] [US1] Add CRUD endpoints for /conversations in paths/conversations
- [ ] T057 [P] [US1] Add message endpoints for /conversations/{conversation}/messages

#### Gift and Debt Endpoints (~10 endpoints)
- [ ] T058 [P] [US1] Add CRUD endpoints for /gifts in paths/gifts
- [ ] T059 [P] [US1] Add PUT /gifts/{gift}/photo/{photo} endpoint
- [ ] T060 [P] [US1] Add CRUD endpoints for /debts in paths/debts

#### Life Events Endpoints (~5 endpoints)
- [ ] T061 [P] [US1] Add CRUD endpoints for /lifeevents in paths/lifeevents

#### Document and Photo Endpoints (~8 endpoints)
- [ ] T062 [P] [US1] Add endpoints for /documents (GET, POST, DELETE - no PUT)
- [ ] T063 [P] [US1] Add endpoints for /photos (GET, POST, DELETE - no PUT)

#### Relationship Endpoints (~6 endpoints)
- [ ] T064 [P] [US1] Add CRUD endpoints for /relationships (except index)
- [ ] T065 [P] [US1] Add read-only endpoints for /relationshiptypes
- [ ] T066 [P] [US1] Add read-only endpoints for /relationshiptypegroups

#### Address and Contact Field Endpoints
- [ ] T067 [P] [US1] Add CRUD endpoints for /addresses in paths/addresses
- [ ] T068 [P] [US1] Add CRUD endpoints for /contactfields (except index)
- [ ] T069 [P] [US1] Add CRUD endpoints for /contactfieldtypes (settings)

#### Account/User Endpoints (~10 endpoints)
- [ ] T070 [P] [US1] Add GET/POST /me endpoints in paths/me
- [ ] T071 [P] [US1] Add compliance endpoints (/me/compliance)
- [ ] T072 [P] [US1] Add /me/contact endpoints
- [ ] T073 [P] [US1] Add CRUD endpoints for /genders
- [ ] T074 [P] [US1] Add CRUD endpoints for /places
- [ ] T075 [P] [US1] Add CRUD endpoints for /companies
- [ ] T076 [P] [US1] Add CRUD endpoints for /occupations
- [ ] T077 [P] [US1] Add CRUD endpoints for /pets

#### Settings and Configuration Endpoints (~15 endpoints)
- [ ] T078 [P] [US1] Add read-only endpoints for /currencies
- [ ] T079 [P] [US1] Add read-only endpoints for /compliance
- [ ] T080 [P] [US1] Add read-only endpoints for /countries
- [ ] T081 [P] [US1] Add read-only endpoints for /statistics (public)
- [ ] T082 [P] [US1] Add /logs endpoint (audit logs)
- [ ] T083 [P] [US1] Add /journal endpoints

#### Validation
- [ ] T084 [US1] Run OpenAPI validator (spectral) to verify specification is valid
- [ ] T085 [US1] Verify all routes from /tmp/monica-v4/routes/api.php are documented

**Checkpoint**: US1 complete - All ~150 endpoints documented with basic request/response structures

---

## Phase 4: User Story 2 - Document All Request/Response Schemas (Priority: P1)

**Goal**: Add detailed request schemas with validation rules and response schemas matching Resource classes

**Independent Test**: Compare 10 random endpoint schemas against actual API responses

### Implementation for User Story 2

#### Request Schemas
- [ ] T086 [P] [US2] Add CreateContactRequest schema with all validation rules
- [ ] T087 [P] [US2] Add UpdateContactRequest schema
- [ ] T088 [P] [US2] Add CreateNoteRequest schema (body, contact_id, is_favorited)
- [ ] T089 [P] [US2] Add CreateActivityRequest schema
- [ ] T090 [P] [US2] Add CreateReminderRequest schema
- [ ] T091 [P] [US2] Add CreateTaskRequest schema
- [ ] T092 [P] [US2] Add CreateCallRequest schema
- [ ] T093 [P] [US2] Add CreateConversationRequest and CreateMessageRequest schemas
- [ ] T094 [P] [US2] Add CreateGiftRequest schema
- [ ] T095 [P] [US2] Add CreateDebtRequest schema
- [ ] T096 [P] [US2] Add CreateLifeEventRequest schema
- [ ] T097 [P] [US2] Add CreateRelationshipRequest schema
- [ ] T098 [P] [US2] Add CreateAddressRequest schema
- [ ] T099 [P] [US2] Add CreateTagRequest schema
- [ ] T100 [P] [US2] Add UpdateAvatarRequest schema (source, photo_id)

#### Response Wrappers
- [ ] T101 [P] [US2] Add ContactResponse wrapper schema
- [ ] T102 [P] [US2] Add ContactListResponse wrapper schema with pagination
- [ ] T103 [P] [US2] Add NoteResponse and NoteListResponse schemas
- [ ] T104 [P] [US2] Add ActivityResponse and ActivityListResponse schemas
- [ ] T105 [P] [US2] Add response wrappers for all remaining entities

#### Schema Refinement
- [ ] T106 [US2] Add nullable: true for all optional fields across schemas
- [ ] T107 [US2] Add maxLength constraints from Laravel validation rules
- [ ] T108 [US2] Add enum constraints where applicable (avatar source, debt status, etc.)
- [ ] T109 [US2] Add format specifications (date-time, uri, email, uuid)
- [ ] T110 [US2] Verify Contact schema has all 50+ fields from ContactBase trait

**Checkpoint**: US2 complete - All schemas have accurate field types, constraints, and nullable markers

---

## Phase 5: User Story 3 - Document Authentication & Error Responses (Priority: P2)

**Goal**: Complete documentation of auth requirements and all error response formats

**Independent Test**: Verify error codes 30-42 are documented; test unauthenticated request response

### Implementation for User Story 3

- [ ] T111 [US3] Document Bearer token authentication in info.description
- [ ] T112 [US3] Add 401 response to all authenticated endpoints
- [ ] T113 [US3] Add 403 response where applicable (permission checks)
- [ ] T114 [US3] Document error code 30 (limit too big) on list endpoints
- [ ] T115 [US3] Document error code 31 (not found) on GET/PUT/DELETE endpoints
- [ ] T116 [US3] Document error code 32 (validation error) on POST/PUT endpoints
- [ ] T117 [US3] Document error code 39 (invalid sort) on list endpoints
- [ ] T118 [US3] Document error code 42 (unauthorized) on all authenticated endpoints
- [ ] T119 [US3] Add examples for each error response type
- [ ] T120 [US3] Verify all 13 error codes (30-42) are documented

**Checkpoint**: US3 complete - Authentication and all error responses fully documented

---

## Phase 6: User Story 4 - Document Pagination & Query Parameters (Priority: P2)

**Goal**: Complete documentation of pagination and query parameters for list endpoints

**Independent Test**: Verify pagination parameters on /contacts endpoint match actual behavior

### Implementation for User Story 4

- [ ] T121 [US4] Add page parameter to all list endpoints
- [ ] T122 [US4] Add limit parameter to all list endpoints (max: 100, default: 15)
- [ ] T123 [US4] Add sort parameter to applicable endpoints with valid enum values
- [ ] T124 [US4] Add query search parameter to /contacts endpoint
- [ ] T125 [US4] Add with expansion parameter to /contacts endpoint (?with=contactfields)
- [ ] T126 [US4] Document pagination response structure (links, meta) on all list responses
- [ ] T127 [US4] Add examples of paginated responses with meta/links

**Checkpoint**: US4 complete - All pagination and query parameters documented

---

## Phase 7: User Story 5 - Generate Human-Readable Documentation (Priority: P3)

**Goal**: Add examples and descriptions for Swagger UI/ReDoc rendering

**Independent Test**: Load spec in Swagger UI and verify all endpoints are browsable

### Implementation for User Story 5

- [ ] T128 [P] [US5] Add example values for Contact schema
- [ ] T129 [P] [US5] Add example values for Note, Activity, Reminder schemas
- [ ] T130 [P] [US5] Add example request bodies for POST endpoints
- [ ] T131 [P] [US5] Add example responses for all endpoint operations
- [ ] T132 [P] [US5] Add descriptions to all schema properties
- [ ] T133 [P] [US5] Add operation summaries and descriptions to all endpoints
- [ ] T134 [P] [US5] Organize endpoints by tags for navigation
- [ ] T135 [US5] Verify spec loads correctly in Swagger UI

**Checkpoint**: US5 complete - Specification is fully browsable in documentation viewers

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and versioning

- [ ] T136 Run final OpenAPI validation (spectral lint) on docs/monica-api-openapi.json
- [ ] T137 Compare endpoint count against routes/api.php (~150 endpoints expected)
- [ ] T138 Verify schema count matches Resource classes (~45 schemas expected)
- [ ] T139 Test client generation (TypeScript/Swift) compiles without errors
- [ ] T140 Update spec version to match Monica v4.x version
- [ ] T141 Add changelog/version history to info section
- [ ] T142 Run quickstart.md validation steps
- [ ] T143 Update specs/012-monica-openapi-spec/checklists/requirements.md with completion status

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational - Documents all endpoints (MVP)
- **US2 (Phase 4)**: Can start after Foundational, parallel with US1
- **US3 (Phase 5)**: Can start after Setup, parallel with US1/US2
- **US4 (Phase 6)**: Depends on US1 (endpoints must exist first)
- **US5 (Phase 7)**: Depends on US1 + US2 (schemas must be complete)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 | Foundational | US2, US3 |
| US2 | Foundational | US1, US3 |
| US3 | Setup | US1, US2, US4 |
| US4 | US1 | US3 |
| US5 | US1, US2 | None |

### Parallel Opportunities

Phase 2 (Foundational) has **26 parallel tasks** (T009-T034) - all schemas can be written simultaneously.

Phase 3 (US1) has **47 parallel endpoint documentation tasks** (T040-T083).

Phase 4 (US2) has **20 parallel schema tasks** (T086-T105).

---

## Parallel Example: Phase 2 Foundational

```bash
# Launch all core schema tasks in parallel:
Task: "Add Contact schema with all 50+ fields in components/schemas/Contact"
Task: "Add Note schema in components/schemas/Note"
Task: "Add Activity schema with nested ActivityType in components/schemas/Activity"
# ... (26 total parallel tasks)
```

## Parallel Example: User Story 1

```bash
# After foundational complete, launch all endpoint documentation in parallel:
Task: "Add CRUD endpoints for /notes in paths/notes"
Task: "Add CRUD endpoints for /tasks in paths/tasks"
Task: "Add CRUD endpoints for /reminders in paths/reminders"
# ... (47+ parallel endpoint tasks)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (8 tasks)
2. Complete Phase 2: Foundational (26 tasks)
3. Complete Phase 3: User Story 1 (51 tasks)
4. **STOP and VALIDATE**: Run OpenAPI validator
5. Spec is usable for basic client generation

### Incremental Delivery

1. Setup + Foundational → Foundation ready (34 tasks)
2. Add US1 → All endpoints documented (MVP!)
3. Add US2 → Full schema accuracy
4. Add US3 → Auth/errors complete
5. Add US4 → Pagination complete
6. Add US5 → Documentation-ready
7. Polish → Production-ready

### Task Summary

| Phase | Story | Tasks | Parallel |
|-------|-------|-------|----------|
| 1 | Setup | 8 | 6 |
| 2 | Foundational | 26 | 26 |
| 3 | US1 | 51 | 47 |
| 4 | US2 | 25 | 20 |
| 5 | US3 | 10 | 0 |
| 6 | US4 | 7 | 0 |
| 7 | US5 | 8 | 6 |
| 8 | Polish | 8 | 0 |
| **Total** | | **143** | **105** |

---

## Notes

- [P] tasks = different files/sections, no dependencies
- [Story] label maps task to specific user story for traceability
- All endpoint tasks write to docs/monica-api-openapi.json (single output file)
- Source analysis from /tmp/monica-v4/ PHP codebase
- Validation via spectral-cli or swagger-cli
- Version file as openapi-monica-{version}.json matching Monica release
