# Monica v4.x Call API - Verified Schema

**Source:** https://github.com/monicahq/monica/tree/4.x
**Verified Date:** 2025-01-26
**Verified Against:** Monica v4.x branch (commit: latest as of date)

## Database Schema

```sql
CREATE TABLE calls (
    id INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id INTEGER NOT NULL,
    contact_id INTEGER NOT NULL,
    called_at DATETIME NOT NULL,
    content MEDIUMTEXT NULL,
    contact_called BOOLEAN DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);
```

## Model Properties

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | Integer | Yes | Auto-increment primary key |
| `account_id` | Integer | Yes | Foreign key to accounts table |
| `contact_id` | Integer | Yes | Foreign key to contacts table |
| `called_at` | DateTime | Yes | When the call occurred |
| `content` | Text | No | Call notes/description |
| `contact_called` | Boolean | Yes (default: false) | Direction: true = they called me, false = I called them |
| `created_at` | DateTime | Yes | Record creation timestamp |
| `updated_at` | DateTime | Yes | Record update timestamp |

## Relationships

### Emotions (Many-to-Many)

Stored in `emotion_call` pivot table:

```sql
CREATE TABLE emotion_call (
    account_id INTEGER UNSIGNED NOT NULL,
    call_id INTEGER UNSIGNED NOT NULL,
    emotion_id INTEGER UNSIGNED NOT NULL,
    contact_id INTEGER UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,

    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (call_id) REFERENCES calls(id) ON DELETE CASCADE,
    FOREIGN KEY (emotion_id) REFERENCES emotions(id) ON DELETE CASCADE,
    FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
);
```

## API Endpoints

**Base URL:** `/api`

### List All Calls
```
GET /api/calls
```

**Query Parameters:**
- `limit` - Number of results per page (default: 10)
- `page` - Page number
- `sort` - Sort field (default: created_at)
- `order` - Sort direction: asc/desc

### List Calls for Contact
```
GET /api/contacts/{contact_id}/calls
```

### Get Single Call
```
GET /api/calls/{call_id}
```

### Create Call
```
POST /api/calls
```

**Request Body:**
```json
{
  "contact_id": 123,
  "called_at": "2025-01-26T10:30:00Z",
  "content": "Discussed project timeline",
  "contact_called": false,
  "emotions": [1, 3, 5]
}
```

**Validation Rules:**
- `contact_id` - required, integer, must exist
- `called_at` - required, valid datetime
- `content` - optional, string
- `contact_called` - optional, boolean (default: false)
- `emotions` - optional, array of emotion IDs

### Update Call
```
PUT /api/calls/{call_id}
```

**Request Body:** Same as create, all fields optional

### Delete Call
```
DELETE /api/calls/{call_id}
```

## API Response Format

```json
{
  "id": 456,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "object": "call",
  "called_at": "2025-01-26T10:30:00Z",
  "content": "Discussed project timeline",
  "contact_called": false,
  "emotions": [
    {
      "id": 1,
      "name": "Happy",
      "type": "positive"
    }
  ],
  "url": "https://app.monicahq.com/api/calls/456",
  "account": {
    "id": 1
  },
  "contact": {
    "id": 123,
    "first_name": "John",
    "last_name": "Doe"
  },
  "created_at": "2025-01-26T10:31:00Z",
  "updated_at": "2025-01-26T10:31:00Z"
}
```

## Fields NOT Supported in v4.x

The following fields do **NOT** exist in Monica v4.x and should not be used:

- ❌ `duration` - Call duration in seconds
- ❌ `type` - Audio/video call type
- ❌ `answered` - Whether call was answered
- ❌ `call_reason_id` - Call categorization
- ❌ `author_id` - User who logged the call
- ❌ `who_initiated` - String-based direction (use `contact_called` boolean instead)

## Migration Notes

### v5+ Differences

Monica v5+ may have different schema. Always verify against the 4.x branch for this project.

### iOS Client Mapping

- Store `contact_called` as boolean in Core Data
- Map to `CallDirection` enum in Swift for UI display
- Store emotions as array relationship (not single ID)
- Use `content` field for notes (not `description`)
