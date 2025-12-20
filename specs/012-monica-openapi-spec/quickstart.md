# Quickstart: Monica v4 OpenAPI Specification

## Overview

This feature generates a complete OpenAPI 3.0+ specification for the Monica v4 REST API by analyzing the PHP codebase.

## Output

**Primary Deliverable**: `docs/monica-api-openapi.json`

A valid OpenAPI 3.0+ JSON specification that documents:
- ~150 API endpoints
- 45+ response schemas
- 30+ request schemas
- Authentication requirements
- Error response formats
- Pagination patterns

## Using the Specification

### 1. Validate the Spec

```bash
# Using spectral
npx @stoplight/spectral-cli lint docs/monica-api-openapi.json

# Using swagger-cli
npx swagger-cli validate docs/monica-api-openapi.json
```

### 2. Generate API Clients

**TypeScript/JavaScript**:
```bash
npx openapi-generator-cli generate \
  -i docs/monica-api-openapi.json \
  -g typescript-fetch \
  -o ./generated/typescript-client
```

**Swift**:
```bash
npx openapi-generator-cli generate \
  -i docs/monica-api-openapi.json \
  -g swift5 \
  -o ./generated/swift-client
```

### 3. View Interactive Documentation

```bash
# Using Swagger UI
docker run -p 8080:8080 \
  -e SWAGGER_JSON=/spec/monica-api-openapi.json \
  -v $(pwd)/docs:/spec \
  swaggerapi/swagger-ui

# Or use ReDoc
npx redoc-cli serve docs/monica-api-openapi.json
```

### 4. Import to Postman/Insomnia

Both tools support direct OpenAPI import:
1. Open Postman/Insomnia
2. Import → File → Select `monica-api-openapi.json`
3. All endpoints will be created with proper schemas

## Specification Structure

```
openapi: "3.0.3"
info:
  title: Monica Personal CRM API
  version: "4.x.x"

servers:
  - url: "{server}/api"

security:
  - bearerAuth: []

tags:
  - Contacts
  - Activities
  - Notes
  - Reminders
  - ... (16 tags total)

paths:
  /contacts: ...
  /contacts/{contact}: ...
  ... (~150 endpoints)

components:
  schemas:
    Contact: ...
    Note: ...
    ... (~80 schemas)

  parameters:
    limitParam: ...
    pageParam: ...
    ... (shared parameters)

  responses:
    Unauthorized: ...
    NotFound: ...
    ... (standard error responses)
```

## Key Patterns

### Authentication
All requests require Bearer token:
```
Authorization: Bearer {oauth_token}
```

### Pagination
List endpoints support:
- `?page=N` - Page number (default: 1)
- `?limit=N` - Items per page (default: 15, max: 100)
- `?sort=field` or `?sort=-field` - Sort ascending/descending

### Error Responses
```json
{
  "error": {
    "message": "Error description",
    "error_code": 31
  }
}
```

### Standard Response
```json
{
  "data": { ... },
  "links": { "first": "...", "next": "..." },
  "meta": { "total": 100, "per_page": 15 }
}
```

## Versioning

The specification version matches Monica v4.x releases:
- File: `openapi-monica-4.1.2.json`
- Info version: `"4.1.2"`

Update the spec when Monica releases new API changes.

## Validation Checklist

Before using the generated spec:

- [ ] Passes OpenAPI 3.0 schema validation
- [ ] All 150+ endpoints documented
- [ ] Request schemas match validation rules
- [ ] Response schemas match Resource classes
- [ ] Error codes 30-42 documented
- [ ] Authentication scheme correct
- [ ] Pagination parameters complete

## Troubleshooting

### Generated client has type errors
- Check that optional fields are marked `nullable: true`
- Verify date formats use `format: date-time`

### Missing endpoints
- Compare against `routes/api.php` in Monica source
- Check for new routes added in recent versions

### Schema mismatch with actual API
- Resource classes may have conditional fields
- Use `?with=` parameter documentation for expansions
