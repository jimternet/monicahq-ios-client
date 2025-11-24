# API Contract: Address Management

**Feature**: 002-contact-addresses
**Date**: 2025-11-22
**API Version**: Monica API v4.x

## Base URL

```
{instance_url}/api
```

Where `{instance_url}` is either:
- `https://app.monicahq.com` (cloud)
- User's self-hosted instance URL

## Authentication

All endpoints require Bearer token authentication:

```
Authorization: Bearer {api_token}
```

---

## Endpoints

### 1. List Contact Addresses

Retrieve all addresses associated with a contact.

**Request**:
```
GET /api/contacts/{contact_id}/addresses
```

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| contact_id | Int | Yes | Contact identifier |

**Response** (200 OK):
```json
{
  "data": [
    {
      "id": 123,
      "object": "address",
      "name": "Home",
      "street": "123 Main Street",
      "city": "San Francisco",
      "province": "California",
      "postal_code": "94102",
      "country": {
        "id": 1,
        "object": "country",
        "name": "United States",
        "iso": "US"
      },
      "latitude": 37.7749,
      "longitude": -122.4194,
      "contact": {
        "id": 456
      },
      "account": {
        "id": 1
      },
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z"
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
    "per_page": 50,
    "to": 1,
    "total": 1
  }
}
```

**Error Responses**:
| Status | Description |
|--------|-------------|
| 401 | Unauthorized - Invalid or expired token |
| 404 | Contact not found |

---

### 2. Create Address

Add a new address to a contact.

**Request**:
```
POST /api/contacts/{contact_id}/addresses
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| contact_id | Int | Yes | Contact identifier |

**Request Body**:
```json
{
  "name": "Home",
  "street": "123 Main Street",
  "city": "San Francisco",
  "province": "California",
  "postal_code": "94102",
  "country_id": 1
}
```

**Body Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | String | No | Label (Home, Work, custom) |
| street | String | No | Street address |
| city | String | No | City name |
| province | String | No | State/province |
| postal_code | String | No | ZIP/postal code |
| country_id | Int | No | Country ID from /api/countries |

**Response** (201 Created):
```json
{
  "data": {
    "id": 124,
    "object": "address",
    "name": "Home",
    "street": "123 Main Street",
    "city": "San Francisco",
    "province": "California",
    "postal_code": "94102",
    "country": {
      "id": 1,
      "object": "country",
      "name": "United States",
      "iso": "US"
    },
    "latitude": null,
    "longitude": null,
    "contact": {
      "id": 456
    },
    "account": {
      "id": 1
    },
    "created_at": "2025-11-22T15:00:00Z",
    "updated_at": "2025-11-22T15:00:00Z"
  }
}
```

**Error Responses**:
| Status | Description |
|--------|-------------|
| 400 | Validation error - Invalid fields |
| 401 | Unauthorized |
| 404 | Contact not found |
| 422 | Unprocessable entity - Missing required data |

---

### 3. Get Single Address

Retrieve a specific address by ID.

**Request**:
```
GET /api/addresses/{id}
```

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | Int | Yes | Address identifier |

**Response** (200 OK):
```json
{
  "data": {
    "id": 123,
    "object": "address",
    "name": "Home",
    "street": "123 Main Street",
    "city": "San Francisco",
    "province": "California",
    "postal_code": "94102",
    "country": {
      "id": 1,
      "object": "country",
      "name": "United States",
      "iso": "US"
    },
    "latitude": 37.7749,
    "longitude": -122.4194,
    "contact": {
      "id": 456
    },
    "account": {
      "id": 1
    },
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

**Error Responses**:
| Status | Description |
|--------|-------------|
| 401 | Unauthorized |
| 404 | Address not found |

---

### 4. Update Address

Modify an existing address.

**Request**:
```
PUT /api/addresses/{id}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | Int | Yes | Address identifier |

**Request Body**:
```json
{
  "name": "Work",
  "street": "456 Market Street",
  "city": "San Francisco",
  "province": "California",
  "postal_code": "94103",
  "country_id": 1
}
```

**Response** (200 OK):
```json
{
  "data": {
    "id": 123,
    "object": "address",
    "name": "Work",
    "street": "456 Market Street",
    "city": "San Francisco",
    "province": "California",
    "postal_code": "94103",
    "country": {
      "id": 1,
      "object": "country",
      "name": "United States",
      "iso": "US"
    },
    "latitude": null,
    "longitude": null,
    "contact": {
      "id": 456
    },
    "account": {
      "id": 1
    },
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-11-22T15:30:00Z"
  }
}
```

**Error Responses**:
| Status | Description |
|--------|-------------|
| 400 | Validation error |
| 401 | Unauthorized |
| 404 | Address not found |
| 422 | Unprocessable entity |

---

### 5. Delete Address

Remove an address.

**Request**:
```
DELETE /api/addresses/{id}
```

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | Int | Yes | Address identifier |

**Response** (200 OK):
```json
{
  "deleted": true,
  "id": 123
}
```

**Error Responses**:
| Status | Description |
|--------|-------------|
| 401 | Unauthorized |
| 404 | Address not found |

---

### 6. List Countries

Retrieve all available countries for address forms.

**Request**:
```
GET /api/countries
```

**Response** (200 OK):
```json
{
  "data": [
    {
      "id": 1,
      "object": "country",
      "name": "Afghanistan",
      "iso": "AF"
    },
    {
      "id": 2,
      "object": "country",
      "name": "Albania",
      "iso": "AL"
    },
    ...
    {
      "id": 250,
      "object": "country",
      "name": "Zimbabwe",
      "iso": "ZW"
    }
  ]
}
```

**Notes**:
- List is not paginated (typically ~250 countries)
- Should be cached client-side with 24-hour TTL
- Countries are sorted alphabetically by name

---

## Error Response Format

All error responses follow this structure:

```json
{
  "error": {
    "message": "The given data was invalid.",
    "error_code": 32,
    "errors": {
      "field_name": [
        "Validation error message"
      ]
    }
  }
}
```

---

## Rate Limiting

- Standard rate limit: 60 requests per minute
- Rate limit headers:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Unix timestamp when limit resets

**429 Too Many Requests Response**:
```json
{
  "error": {
    "message": "Rate limit exceeded. Please wait before making another request.",
    "error_code": 429
  }
}
```

---

## Testing Scenarios

### Happy Path Tests

1. **List addresses** - Contact with 3 addresses returns all
2. **Create address** - Valid data creates new address
3. **Update address** - Modified fields persist
4. **Delete address** - Address removed from contact
5. **List countries** - Returns 200+ countries

### Edge Case Tests

1. **Empty address list** - Contact with no addresses returns empty array
2. **Create minimal address** - Only city field provided
3. **Update single field** - Only name changed
4. **Invalid country_id** - Returns 422 error
5. **Duplicate address** - Same data for same contact (allowed)

### Error Tests

1. **Unauthorized** - Invalid token returns 401
2. **Contact not found** - Invalid contact_id returns 404
3. **Address not found** - Invalid address id returns 404
4. **Rate limited** - Exceeding limit returns 429
