# Data Model: Monica v4 API Schemas

**Feature**: 012-monica-openapi-spec
**Date**: 2025-12-10

## Overview

This document defines the OpenAPI component schemas derived from Monica v4 Resource classes.

---

## Core Schema Patterns

### Standard Fields (All Resources)
```yaml
id:
  type: integer
  description: Primary key
uuid:
  type: string
  format: uuid
  description: Unique identifier
object:
  type: string
  description: Resource type identifier
account:
  type: object
  properties:
    id:
      type: integer
created_at:
  type: string
  format: date-time
updated_at:
  type: string
  format: date-time
```

### Timestamps
- **Format**: ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`)
- **Timezone**: UTC

---

## Entity Schemas

### Contact
**Object**: `contact`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "contact" |
| hash_id | string | Yes | Hashed identifier |
| first_name | string | Yes | First name |
| last_name | string | No | Last name |
| nickname | string | No | Nickname |
| complete_name | string | Yes | Full formatted name |
| initials | string | Yes | Initials |
| description | string | No | Description/bio |
| gender | string | No | Gender label |
| gender_type | string | No | Gender type |
| is_starred | boolean | Yes | Favorited flag |
| is_partial | boolean | Yes | Partial contact flag |
| is_active | boolean | Yes | Active flag |
| is_dead | boolean | Yes | Deceased flag |
| is_me | boolean | Yes | Is current user |
| information | object | Yes | Nested contact info |
| addresses | array | Yes | Address[] |
| tags | array | Yes | Tag[] |
| statistics | object | Yes | Activity counts |
| contactFields | array | No | ContactField[] (with ?with=contactfields) |
| notes | array | No | Note[] (last 3, conditional) |
| url | string | Yes | API URL |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

**Nested: information**
```yaml
relationships:
  love: { total: integer, contacts: ContactShort[] }
  family: { total: integer, contacts: ContactShort[] }
  friend: { total: integer, contacts: ContactShort[] }
  work: { total: integer, contacts: ContactShort[] }
dates:
  birthdate: { is_age_based: boolean?, is_year_unknown: boolean?, date: datetime? }
  deceased_date: { is_age_based: boolean?, is_year_unknown: boolean?, date: datetime? }
career:
  job: string?
  company: string?
avatar:
  url: string?
  source: string
  default_avatar_color: string
food_preferences: string?
how_you_met:
  general_information: string?
  first_met_date: object?
  first_met_through_contact: ContactShort?
```

---

### ContactShort
**Object**: `contact` (abbreviated)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "contact" |
| hash_id | string | Yes | Hashed identifier |
| first_name | string | Yes | First name |
| last_name | string | No | Last name |
| complete_name | string | Yes | Full name |
| initials | string | Yes | Initials |

---

### Note
**Object**: `note`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "note" |
| body | string | Yes | Note content |
| is_favorited | boolean | Yes | Favorited flag |
| favorited_at | datetime | No | When favorited |
| url | string | Yes | API URL |
| account | object | Yes | Account reference |
| contact | ContactShort | Yes | Associated contact |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Activity
**Object**: `activity`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "activity" |
| summary | string | Yes | Activity summary |
| description | string | No | Detailed description |
| happened_at | date | Yes | When it happened |
| activity_type | ActivityType | Yes | Activity type |
| attendees | object | Yes | { total: int, contacts: ContactShort[] } |
| emotions | Emotion[] | Yes | Associated emotions |
| url | string | Yes | API URL |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### ActivityType
**Object**: `activitytype`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "activitytype" |
| name | string | Yes | Type name |
| location_type | string | No | Location type |
| activity_type_category | ActivityTypeCategory | Yes | Parent category |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Address
**Object**: `address`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "address" |
| name | string | No | Address label |
| street | string | No | Street address |
| city | string | No | City |
| province | string | No | State/province |
| postal_code | string | No | Postal/ZIP code |
| country | Country | No | Country reference |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Tag
**Object**: `tag`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "tag" |
| name | string | Yes | Tag name |
| name_slug | string | Yes | URL-safe name |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Reminder
**Object**: `reminder`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "reminder" |
| title | string | Yes | Reminder title |
| description | string | No | Description |
| frequency_type | string | Yes | one_time/week/month/year |
| frequency_number | integer | Yes | Frequency multiplier |
| initial_date | date | Yes | Start date |
| next_expected_date | date | Yes | Next occurrence |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Task
**Object**: `task`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "task" |
| title | string | Yes | Task title |
| description | string | No | Description |
| completed | boolean | Yes | Completion status |
| completed_at | datetime | No | When completed |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Call
**Object**: `call`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "call" |
| content | string | No | Call notes |
| called_at | datetime | Yes | When call occurred |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Conversation
**Object**: `conversation`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "conversation" |
| contact_field_type | ContactFieldType | Yes | Channel type |
| happened_at | datetime | Yes | When it occurred |
| messages | Message[] | Yes | Conversation messages |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Gift
**Object**: `gift`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "gift" |
| name | string | Yes | Gift name |
| comment | string | No | Notes |
| url | string | No | Product URL |
| value | number | No | Monetary value |
| is_for | string | Yes | Recipient context |
| has_been_offered | boolean | Yes | Already given flag |
| date_offered | date | No | When given |
| photo | Photo | No | Associated photo |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Debt
**Object**: `debt`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "debt" |
| in_debt | string | Yes | Direction: "yes" or "no" |
| status | string | Yes | Status: inprogress/complete |
| amount | number | Yes | Debt amount |
| amount_with_currency | string | Yes | Formatted amount |
| reason | string | No | Reason for debt |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### LifeEvent
**Object**: `lifeevent`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "lifeevent" |
| name | string | No | Event name |
| note | string | No | Notes |
| happened_at | datetime | Yes | When it happened |
| life_event_type | LifeEventType | Yes | Event type |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Photo
**Object**: `photo`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "photo" |
| original_filename | string | Yes | Original filename |
| new_filename | string | Yes | Storage filename |
| filesize | integer | Yes | Size in bytes |
| mime_type | string | Yes | MIME type |
| link | string | Yes | Download URL |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

### Document
**Object**: `document`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Primary key |
| uuid | string | Yes | UUID |
| object | string | Yes | Always "document" |
| original_filename | string | Yes | Original filename |
| new_filename | string | Yes | Storage filename |
| filesize | integer | Yes | Size in bytes |
| type | string | Yes | File type |
| mime_type | string | Yes | MIME type |
| link | string | Yes | Download URL |
| contact | ContactShort | Yes | Associated contact |
| account | object | Yes | Account reference |
| created_at | datetime | Yes | Created timestamp |
| updated_at | datetime | Yes | Updated timestamp |

---

## Response Wrappers

### Single Resource Response
```yaml
SingleResourceResponse:
  type: object
  properties:
    data:
      $ref: '#/components/schemas/{ResourceType}'
```

### Collection Response (Paginated)
```yaml
PaginatedResponse:
  type: object
  properties:
    data:
      type: array
      items:
        $ref: '#/components/schemas/{ResourceType}'
    links:
      $ref: '#/components/schemas/PaginationLinks'
    meta:
      $ref: '#/components/schemas/PaginationMeta'
```

### PaginationLinks
```yaml
PaginationLinks:
  type: object
  properties:
    first:
      type: string
      format: uri
    last:
      type: string
      format: uri
    prev:
      type: string
      format: uri
      nullable: true
    next:
      type: string
      format: uri
      nullable: true
```

### PaginationMeta
```yaml
PaginationMeta:
  type: object
  properties:
    current_page:
      type: integer
    from:
      type: integer
    last_page:
      type: integer
    path:
      type: string
      format: uri
    per_page:
      type: integer
    to:
      type: integer
    total:
      type: integer
```

---

## Error Response

### ErrorResponse
```yaml
ErrorResponse:
  type: object
  required:
    - error
  properties:
    error:
      type: object
      required:
        - message
        - error_code
      properties:
        message:
          oneOf:
            - type: string
            - type: array
              items:
                type: string
        error_code:
          type: integer
          enum: [30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42]
```

---

## Request Schemas

### CreateContact
```yaml
CreateContact:
  type: object
  required:
    - first_name
    - is_birthdate_known
    - is_deceased
    - is_deceased_date_known
  properties:
    first_name:
      type: string
      maxLength: 255
    middle_name:
      type: string
      maxLength: 255
    last_name:
      type: string
      maxLength: 255
    nickname:
      type: string
      maxLength: 255
    gender_id:
      type: integer
    description:
      type: string
      maxLength: 255
    is_partial:
      type: boolean
    is_birthdate_known:
      type: boolean
    birthdate_day:
      type: integer
    birthdate_month:
      type: integer
    birthdate_year:
      type: integer
    is_deceased:
      type: boolean
    is_deceased_date_known:
      type: boolean
```

### CreateNote
```yaml
CreateNote:
  type: object
  required:
    - body
    - contact_id
  properties:
    body:
      type: string
      maxLength: 100000
    contact_id:
      type: integer
    is_favorited:
      type: boolean
```

### UploadPhoto
```yaml
UploadPhoto:
  type: object
  required:
    - contact_id
  properties:
    contact_id:
      type: integer
    photo:
      type: string
      format: binary
      description: Image file (required if data not provided)
    data:
      type: string
      description: Base64 encoded image (required if photo not provided)
    extension:
      type: string
```

---

## Entity Count Summary

| Category | Count |
|----------|-------|
| Response Schemas | 45 |
| Request Schemas | ~30 |
| Shared Components | 10 |
| Error Schemas | 2 |
| **Total** | **~87** |
