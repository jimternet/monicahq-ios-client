# Monica Conversations API Contract

**Base URL**: `https://{monica-instance}/api`
**Authentication**: Bearer token in `Authorization` header
**API Version**: Monica v4.x

## Endpoints

### List Conversations for Contact

**Endpoint**: `GET /api/conversations`
**Query Parameters**:
- `contact_id` (required): Filter conversations by contact ID

**Response**: 200 OK
```json
{
  "data": [
    {
      "id": 123,
      "object": "conversation",
      "contact_id": 456,
      "happened_at": "2025-01-26T14:30:00Z",
      "contact_field_type_id": 10,
      "notes": "Discussed upcoming project plans and timeline.",
      "created_at": "2025-01-26T14:35:00Z",
      "updated_at": "2025-01-26T14:35:00Z"
    }
  ],
  "links": {
    "first": "...",
    "last": "...",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "path": "...",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Contact not found
- `422 Unprocessable Entity`: Invalid query parameters

---

### Get Conversation by ID

**Endpoint**: `GET /api/conversations/{id}`

**Response**: 200 OK
```json
{
  "data": {
    "id": 123,
    "object": "conversation",
    "contact_id": 456,
    "happened_at": "2025-01-26T14:30:00Z",
    "contact_field_type_id": 10,
    "notes": "Discussed upcoming project plans and timeline.",
    "created_at": "2025-01-26T14:35:00Z",
    "updated_at": "2025-01-26T14:35:00Z"
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Conversation not found

---

### Create Conversation

**Endpoint**: `POST /api/conversations`

**Request Body**:
```json
{
  "contact_id": 456,
  "happened_at": "2025-01-26T14:30:00Z",
  "contact_field_type_id": 10,
  "notes": "Discussed upcoming project plans and timeline."
}
```

**Field Constraints**:
- `contact_id` (required): Must be a valid contact ID
- `happened_at` (required): ISO 8601 timestamp, cannot be in the future
- `contact_field_type_id` (optional): Integer, conversation type category
- `notes` (optional): String, max 10,000 characters

**Response**: 201 Created
```json
{
  "data": {
    "id": 123,
    "object": "conversation",
    "contact_id": 456,
    "happened_at": "2025-01-26T14:30:00Z",
    "contact_field_type_id": 10,
    "notes": "Discussed upcoming project plans and timeline.",
    "created_at": "2025-01-26T14:35:00Z",
    "updated_at": "2025-01-26T14:35:00Z"
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Contact not found
- `422 Unprocessable Entity`: Validation errors (future date, missing required fields, notes too long)

---

### Update Conversation

**Endpoint**: `PUT /api/conversations/{id}`

**Request Body** (all fields optional):
```json
{
  "happened_at": "2025-01-26T15:00:00Z",
  "contact_field_type_id": 11,
  "notes": "Updated notes with additional details."
}
```

**Field Constraints**:
- `happened_at` (optional): ISO 8601 timestamp, cannot be in the future
- `contact_field_type_id` (optional): Integer, conversation type category
- `notes` (optional): String, max 10,000 characters

**Response**: 200 OK
```json
{
  "data": {
    "id": 123,
    "object": "conversation",
    "contact_id": 456,
    "happened_at": "2025-01-26T15:00:00Z",
    "contact_field_type_id": 11,
    "notes": "Updated notes with additional details.",
    "created_at": "2025-01-26T14:35:00Z",
    "updated_at": "2025-01-26T15:05:00Z"
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Conversation not found
- `422 Unprocessable Entity`: Validation errors (future date, notes too long)

---

### Delete Conversation

**Endpoint**: `DELETE /api/conversations/{id}`

**Response**: 200 OK
```json
{
  "deleted": true,
  "id": 123
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing API token
- `404 Not Found`: Conversation not found

---

## Data Types

### Conversation Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | Integer | Yes | Unique identifier |
| object | String | Yes | Always "conversation" |
| contact_id | Integer | Yes | Associated contact ID |
| happened_at | ISO 8601 | Yes | When conversation occurred |
| contact_field_type_id | Integer | No | Conversation type category |
| notes | String | No | Conversation details (max 10,000 chars) |
| created_at | ISO 8601 | Yes | Record creation timestamp |
| updated_at | ISO 8601 | Yes | Record update timestamp |

## Notes

- **Pagination**: List endpoint supports pagination via `page` query parameter
- **Date Format**: All timestamps in ISO 8601 format with timezone
- **Future Dates**: API MUST reject `happened_at` dates in the future with 422 error
- **Character Limit**: Notes field enforced at 10,000 characters per spec FR-008
- **Contact Field Types**: `contact_field_type_id` values are instance-specific; common values may include types for "in-person", "email", "text", etc.

## OpenAPI Specification

This contract will be formalized in `/docs/monica-api-openapi.yaml` once implementation validates actual API behavior. Any discrepancies found during development MUST be documented per Constitution Principle 11.
