# Feature Specification: Monica v4 OpenAPI Specification Generator

**Feature Branch**: `012-monica-openapi-spec`
**Created**: 2025-12-10
**Status**: Draft
**Input**: User description: "Reverse engineer a complete and accurate OpenAPI specification from the Monica v4 PHP codebase by deeply analyzing all API routes, controllers, resources, services, and models"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate Complete OpenAPI Specification (Priority: P1)

As a developer building a Monica client application, I want a complete and accurate OpenAPI 3.0+ specification file so that I can auto-generate type-safe API clients, understand all available endpoints, and ensure my application correctly integrates with the Monica API.

**Why this priority**: Without a complete OpenAPI spec, developers must reverse-engineer API behavior through trial and error, leading to bugs, missed endpoints, and incorrect data models. This is the core deliverable that enables all other use cases.

**Independent Test**: Can be fully tested by generating the OpenAPI spec file and validating it against the OpenAPI 3.0 schema using standard validation tools (e.g., spectral, swagger-cli). The specification should pass validation with zero errors.

**Acceptance Scenarios**:

1. **Given** the Monica v4 codebase at `/tmp/monica-v4`, **When** the specification generation process completes, **Then** a valid OpenAPI 3.0+ YAML/JSON file is produced that passes schema validation
2. **Given** the generated OpenAPI specification, **When** compared against the actual API routes in `routes/api.php`, **Then** 100% of documented API endpoints are present in the specification
3. **Given** the generated OpenAPI specification, **When** used to generate a TypeScript/Swift client, **Then** the generated client compiles without type errors

---

### User Story 2 - Document All Request/Response Schemas (Priority: P1)

As a developer, I want accurate request and response schemas for every endpoint so that I can understand exactly what data to send and what to expect back without reading PHP source code.

**Why this priority**: Incorrect schemas lead to runtime errors and broken integrations. This is equally critical to endpoint documentation.

**Independent Test**: Can be tested by selecting 10 random endpoints, making real API calls, and verifying the response structure matches the documented schema exactly.

**Acceptance Scenarios**:

1. **Given** any POST/PUT/PATCH endpoint in the spec, **When** I examine its requestBody schema, **Then** all required and optional fields are documented with correct types
2. **Given** any endpoint in the spec, **When** I examine its response schema, **Then** the schema matches the actual Resource class output from Monica v4
3. **Given** a Contact resource response, **When** compared to the specification, **Then** all 50+ fields are documented including nested objects (tags, addresses, contactFields, etc.)

---

### User Story 3 - Document Authentication & Error Responses (Priority: P2)

As a developer, I want clear documentation of authentication requirements and all possible error responses so that I can implement proper auth flows and error handling in my application.

**Why this priority**: Authentication is required for all API access, and proper error handling prevents crashes and improves user experience. However, this is secondary to having the endpoints and schemas documented first.

**Independent Test**: Can be tested by making unauthenticated requests and verifying all documented error codes/formats match actual API behavior.

**Acceptance Scenarios**:

1. **Given** the OpenAPI specification, **When** I examine the security schemes section, **Then** Bearer token authentication is documented with correct header format
2. **Given** any endpoint, **When** I examine possible responses, **Then** error responses (400, 401, 403, 404, 422, 500) are documented with their JSON structure
3. **Given** the error codes defined in Monica's `config/api.php`, **When** compared to the specification, **Then** all error codes (30-42) are documented with descriptions

---

### User Story 4 - Document Pagination & Query Parameters (Priority: P2)

As a developer, I want documentation of pagination patterns and available query parameters so that I can efficiently retrieve large datasets and filter/search results.

**Why this priority**: Pagination and filtering are essential for production apps with real data volumes, but developers can build basic integrations without this.

**Independent Test**: Can be tested by verifying pagination parameters work as documented on list endpoints.

**Acceptance Scenarios**:

1. **Given** any list endpoint (e.g., /contacts, /notes), **When** I examine query parameters, **Then** `page`, `limit`, and sort parameters are documented
2. **Given** the contacts endpoint, **When** I examine query parameters, **Then** the `query` search parameter and `with` expansion parameter are documented
3. **Given** paginated responses, **When** I examine the response schema, **Then** `meta` (pagination info) and `links` (navigation URLs) are documented

---

### User Story 5 - Generate Human-Readable API Documentation (Priority: P3)

As a developer new to Monica, I want browsable API documentation (like Swagger UI or ReDoc) so that I can explore the API interactively and understand its capabilities.

**Why this priority**: While helpful for developer experience, this is a nice-to-have that builds on the core OpenAPI spec. The spec itself can be loaded into any documentation viewer.

**Independent Test**: Can be tested by loading the OpenAPI spec into Swagger UI or ReDoc and verifying all endpoints are browsable with examples.

**Acceptance Scenarios**:

1. **Given** the OpenAPI specification, **When** loaded into Swagger UI, **Then** all endpoints are navigable and organized by tag/category
2. **Given** any endpoint in the documentation, **When** viewing its details, **Then** example request/response bodies are shown
3. **Given** the documentation, **When** searching for "contact", **Then** all contact-related endpoints are discoverable

---

### Edge Cases

- Conditional fields (appearing only under certain conditions like `?with=` expansion) are documented as optional fields with descriptions noting when they appear
- How are nested resources documented (e.g., ContactWithContactFields vs Contact)?
- What happens with endpoints that accept file uploads (photos, documents)?
- How are polymorphic responses handled (different response shapes based on parameters)?
- What happens with deprecated endpoints or fields?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST generate a valid OpenAPI 3.0+ specification file in JSON format
- **FR-002**: System MUST document ALL 40+ API controllers and their endpoints from the Monica v4 codebase
- **FR-003**: System MUST extract request schemas from controller validation rules and service class validation
- **FR-004**: System MUST extract response schemas from Resource classes (45 resource files)
- **FR-005**: System MUST document all 65 model entities and their relationships
- **FR-006**: System MUST document authentication requirements (Bearer token via `auth:api` middleware)
- **FR-007**: System MUST document all error responses with codes, messages, and JSON structure
- **FR-008**: System MUST document pagination parameters and response format for list endpoints
- **FR-009**: System MUST document nested routes (e.g., `/contacts/{contact}/notes` AND `/notes`)
- **FR-010**: System MUST include field descriptions extracted from model/resource comments
- **FR-011**: System MUST mark required vs optional fields correctly based on validation rules
- **FR-012**: System MUST document query parameters (search, sort, filter, `with` expansion)
- **FR-013**: System MUST document file upload endpoints with correct content-type specifications
- **FR-014**: System MUST organize endpoints into logical tags/groups matching Monica's domain structure
- **FR-015**: System MUST version the OpenAPI spec to match the Monica v4.x version it documents (e.g., openapi-monica-4.1.2.json)

### Key Entities

- **API Endpoint**: A unique URL path + HTTP method combination with its request/response schemas
- **Schema/Model**: A reusable data structure definition (Contact, Note, Activity, etc.)
- **Resource**: The JSON transformation layer that converts models to API responses
- **Validation Rule**: Laravel validation rules that define required fields and constraints
- **Security Scheme**: Authentication mechanism (Bearer token for Monica)

### API Scope Summary (from codebase analysis)

The specification must cover:

| Category              | Endpoints | Controllers | Resources |
|-----------------------|-----------|-------------|-----------|
| Contacts              | ~15       | 4           | 5         |
| Activities            | ~8        | 3           | 3         |
| Relationships         | ~6        | 3           | 4         |
| Notes/Tasks/Reminders | ~15       | 3           | 3         |
| Calls/Conversations   | ~10       | 3           | 3         |
| Gifts/Debts           | ~10       | 2           | 2         |
| Documents/Photos      | ~8        | 2           | 2         |
| Life Events           | ~5        | 1           | 3         |
| Settings/Config       | ~15       | 7           | 5         |
| Account/User          | ~10       | 4           | 2         |
| **Total**             | **~100+** | **40**      | **45**    |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Generated OpenAPI specification passes validation with zero errors using standard OpenAPI validators
- **SC-002**: 100% of API routes from `routes/api.php` are documented in the specification
- **SC-003**: 100% of Resource class fields are accurately represented in response schemas
- **SC-004**: Auto-generated API clients (TypeScript, Swift) compile without type errors when using the specification
- **SC-005**: All 40 API controllers have their endpoints fully documented
- **SC-006**: All required vs optional field designations match Laravel validation rules
- **SC-007**: Response schemas for 10 randomly selected endpoints match actual API responses with 100% field accuracy
- **SC-008**: Error response codes 30-42 (as defined in Monica config) are all documented
- **SC-009**: File upload endpoints correctly specify multipart/form-data content type

## Clarifications

### Session 2025-12-10

- Q: Which output format should be the primary deliverable? → A: JSON only
- Q: How should conditional/optional fields be represented in the OpenAPI schema? → A: Document all possible fields as optional with descriptions noting conditions
- Q: How should the OpenAPI spec be versioned? → A: Match Monica v4.x version (e.g., openapi-monica-4.1.2.json)

## Assumptions

- The Monica v4 codebase at `/tmp/monica-v4` is complete and represents the current stable API
- Laravel validation rules in controllers/services accurately reflect API requirements
- Resource classes accurately represent the full API response structure
- The API uses standard REST conventions with JSON request/response bodies
- Bearer token authentication is the only supported authentication method for the API
- Standard HTTP status codes are used consistently across all endpoints
