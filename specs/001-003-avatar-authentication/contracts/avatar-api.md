# API Contracts: Avatar Authentication

**Feature**: Avatar Authentication & Display
**Date**: 2025-11-24
**API Version**: Monica API v1

## Overview

This document specifies the API contracts for avatar-related endpoints in the Monica CRM API. It covers contact avatar retrieval, photo management, and authentication requirements for image loading.

## Authentication

### Bearer Token Authentication

All Monica API requests require Bearer token authentication.

**Header Format**:
```http
Authorization: Bearer {api_token}
```

**Obtaining Token**:
- User creates API token in Monica web interface: Settings → API → Create Token
- Token has full account access (read/write)
- No expiration unless manually revoked

**Authentication Scope**:
- ✅ API endpoints (`/api/*`)
- ✅ Photo URLs (`/storage/photos/*`) - **assumed, requires validation**
- ❌ Gravatar URLs (external service, no auth required)
- ❌ Other external avatar services

## Contact Avatar Endpoint

### Get Contact Details

Retrieve contact information including avatar metadata.

**Endpoint**: `GET /api/contacts/{id}`

**Authentication**: Required (Bearer token)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Contact ID |

**Request Example**:
```http
GET /api/contacts/1 HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: application/json
```

**Response**: `200 OK`

```json
{
  "data": {
    "id": 1,
    "object": "contact",
    "hash_id": "h:Y5LOkAdWNDqgVomKPv",
    "first_name": "John",
    "last_name": "Doe",
    "nickname": null,
    "complete_name": "John Doe",
    "information": {
      "relationships": {
        "love": {
          "total": 0,
          "contacts": []
        },
        "family": {
          "total": 2,
          "contacts": []
        }
      },
      "dates": {
        "birthdate": {
          "is_age_based": false,
          "is_year_unknown": false,
          "date": "1985-03-15T00:00:00Z"
        }
      },
      "career": {
        "job": "Software Engineer",
        "company": "Tech Corp"
      },
      "avatar": {
        "url": "https://app.monicahq.com/storage/photos/abc123.jpg",
        "source": "photo",
        "default_avatar_color": "#b3d5fe"
      },
      "food_preferences": null,
      "how_you_met": {
        "general_information": "Met at conference",
        "first_met_date": "2020-01-15T00:00:00Z"
      }
    },
    "account": {
      "id": 1
    },
    "created_at": "2020-01-15T10:30:00Z",
    "updated_at": "2024-11-20T14:22:00Z"
  }
}
```

**Avatar Object Fields**:
| Field | Type | Description | Possible Values |
|-------|------|-------------|-----------------|
| `url` | string | URL to avatar image (empty for default) | URL string or empty `""` |
| `source` | string | Avatar source type | `"default"`, `"gravatar"`, `"photo"`, `"adorable"` |
| `default_avatar_color` | string | Hex color code for initials avatar | `"#b3d5fe"`, `"#ffd6a5"`, etc. |

**Avatar Source Types**:

1. **`"default"`** - Initials-based avatar
   - `url`: Empty string `""`
   - `default_avatar_color`: Always provided (hex code)
   - No network request needed

2. **`"gravatar"`** - Gravatar service
   - `url`: `"https://www.gravatar.com/avatar/{hash}?d=404"`
   - `default_avatar_color`: Provided as fallback
   - No authentication required (external service)

3. **`"photo"`** - User-uploaded photo
   - `url`: `"https://{monica-host}/storage/photos/{filename}"`
   - `default_avatar_color`: Provided as fallback
   - **Authentication required** (Bearer token)

4. **`"adorable"`** - Adorable.io service (deprecated)
   - `url`: External service URL
   - `default_avatar_color`: Provided as fallback
   - No authentication required

**Error Responses**:

| Status Code | Error | Description |
|-------------|-------|-------------|
| `401 Unauthorized` | Invalid or missing token | Authentication failed |
| `403 Forbidden` | Insufficient permissions | Token lacks contact read permission |
| `404 Not Found` | Contact not found | Contact ID doesn't exist |
| `429 Too Many Requests` | Rate limit exceeded | Too many API requests |
| `500 Internal Server Error` | Server error | Monica server error |

**Error Response Format**:
```json
{
  "error": {
    "message": "The resource you are looking for does not exist",
    "error_code": 31
  }
}
```

## Photo Management Endpoints

### List All Photos

Retrieve all photos in the account.

**Endpoint**: `GET /api/photos`

**Authentication**: Required (Bearer token)

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Results per page (default: 10) |
| `page` | integer | No | Page number (default: 1) |

**Request Example**:
```http
GET /api/photos?limit=50&page=1 HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: application/json
```

**Response**: `200 OK`

```json
{
  "data": [
    {
      "id": 123,
      "object": "photo",
      "original_filename": "john-profile.jpg",
      "new_filename": "photos/abc123.jpg",
      "filesize": 245678,
      "mime_type": "image/jpeg",
      "link": "https://app.monicahq.com/storage/photos/abc123.jpg",
      "account": {
        "id": 1
      },
      "created_at": "2024-03-15T10:30:00Z",
      "updated_at": "2024-03-15T10:30:00Z"
    }
  ],
  "links": {
    "first": "https://app.monicahq.com/api/photos?page=1",
    "last": "https://app.monicahq.com/api/photos?page=3",
    "prev": null,
    "next": "https://app.monicahq.com/api/photos?page=2"
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 3,
    "path": "https://app.monicahq.com/api/photos",
    "per_page": 50,
    "to": 50,
    "total": 142
  }
}
```

### Get Single Photo

Retrieve details about a specific photo.

**Endpoint**: `GET /api/photos/{id}`

**Authentication**: Required (Bearer token)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Photo ID |

**Request Example**:
```http
GET /api/photos/123 HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: application/json
```

**Response**: `200 OK`

```json
{
  "data": {
    "id": 123,
    "object": "photo",
    "original_filename": "john-profile.jpg",
    "new_filename": "photos/abc123.jpg",
    "filesize": 245678,
    "mime_type": "image/jpeg",
    "link": "https://app.monicahq.com/storage/photos/abc123.jpg",
    "account": {
      "id": 1
    },
    "created_at": "2024-03-15T10:30:00Z",
    "updated_at": "2024-03-15T10:30:00Z"
  }
}
```

### Upload Photo

Upload a new photo to Monica.

**Endpoint**: `POST /api/photos`

**Authentication**: Required (Bearer token)

**Content-Type**: `multipart/form-data`

**Form Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `photo` | file | Yes | Image file (JPEG, PNG, GIF) |

**Request Example**:
```http
POST /api/photos HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="photo"; filename="avatar.jpg"
Content-Type: image/jpeg

{binary image data}
------WebKitFormBoundary--
```

**Response**: `201 Created`

```json
{
  "data": {
    "id": 124,
    "object": "photo",
    "original_filename": "avatar.jpg",
    "new_filename": "photos/xyz789.jpg",
    "filesize": 198432,
    "mime_type": "image/jpeg",
    "link": "https://app.monicahq.com/storage/photos/xyz789.jpg",
    "account": {
      "id": 1
    },
    "created_at": "2024-11-24T15:45:00Z",
    "updated_at": "2024-11-24T15:45:00Z"
  }
}
```

### Delete Photo

Delete a photo from Monica.

**Endpoint**: `DELETE /api/photos/{id}`

**Authentication**: Required (Bearer token)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Photo ID |

**Request Example**:
```http
DELETE /api/photos/123 HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: application/json
```

**Response**: `200 OK`

```json
{
  "deleted": true,
  "id": 123
}
```

## Avatar Update Endpoint

### Update Contact Avatar

Set or update a contact's avatar.

**Endpoint**: `PUT /api/contacts/{contact}/avatar`

**Authentication**: Required (Bearer token)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `contact` | integer | Yes | Contact ID |

**Request Body**:
```json
{
  "source": "photo",
  "photo_id": 124
}
```

**Request Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | string | Yes | Avatar source: `"photo"`, `"gravatar"`, `"default"` |
| `photo_id` | integer | Conditional | Required if `source` is `"photo"` |

**Request Example**:
```http
PUT /api/contacts/1/avatar HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json
Accept: application/json

{
  "source": "photo",
  "photo_id": 124
}
```

**Response**: `200 OK`

```json
{
  "data": {
    "id": 1,
    "object": "contact",
    "information": {
      "avatar": {
        "url": "https://app.monicahq.com/storage/photos/xyz789.jpg",
        "source": "photo",
        "default_avatar_color": "#b3d5fe"
      }
    }
  }
}
```

## Image File Endpoints

### Fetch Avatar Image

Download the actual image file from Monica storage.

**Endpoint**: `GET /storage/photos/{filename}`

**Authentication**: **Required (Bearer token)** - *Assumed, needs validation*

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `filename` | string | Yes | Photo filename (e.g., `abc123.jpg`) |

**Request Example**:
```http
GET /storage/photos/abc123.jpg HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: image/*
```

**Response**: `200 OK`

```http
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Length: 245678
Cache-Control: public, max-age=86400
ETag: "abc123-1234567890"

{binary image data}
```

**Response Headers**:
| Header | Description |
|--------|-------------|
| `Content-Type` | MIME type of image (`image/jpeg`, `image/png`, etc.) |
| `Content-Length` | Size of image in bytes |
| `Cache-Control` | Caching directives (e.g., `max-age=86400` for 24 hours) |
| `ETag` | Entity tag for cache validation |
| `Last-Modified` | Last modification timestamp |

**Error Responses**:
| Status Code | Description |
|-------------|-------------|
| `401 Unauthorized` | Missing or invalid authentication |
| `403 Forbidden` | User doesn't have access to this photo |
| `404 Not Found` | Photo file doesn't exist |

**Important Notes**:
- Authentication mechanism for static files is **not fully documented**
- Implementation assumes Bearer token works (needs testing)
- If Bearer token fails, fallback to initials avatar
- Monica may use session cookies instead (web UI pattern)

## Gravatar Integration

### Gravatar URL Pattern

Monica integrates with Gravatar for email-based avatars.

**URL Format**:
```
https://www.gravatar.com/avatar/{hash}?d=404
```

**Hash Generation**:
```swift
import CryptoKit

func gravatarHash(email: String) -> String {
    let trimmed = email.lowercased().trimmingCharacters(in: .whitespaces)
    let data = Data(trimmed.utf8)
    let hash = Insecure.MD5.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}
```

**Query Parameters**:
| Parameter | Description |
|-----------|-------------|
| `d=404` | Return 404 if no Gravatar found (forces fallback) |
| `d=identicon` | Generate geometric pattern if no Gravatar |
| `d=mp` | Mystery person silhouette if no Gravatar |
| `s=200` | Size in pixels (square, 1-2048) |

**Authentication**: None required (external service)

**Request Example**:
```http
GET /avatar/5658ffccee7f0ebfda2b226238b1eb6e?d=404 HTTP/1.1
Host: www.gravatar.com
Accept: image/*
```

**Response**: `200 OK` or `404 Not Found`

## Caching Headers

### HTTP Cache-Control

Monica's photo responses include caching directives.

**Expected Cache Headers**:
```http
Cache-Control: public, max-age=86400
ETag: "abc123-1234567890"
Last-Modified: Tue, 15 Mar 2024 10:30:00 GMT
```

**Client Cache Strategy**:
1. **Respect `Cache-Control`**: Honor `max-age` directive
2. **ETag Validation**: Use `If-None-Match` for revalidation
3. **Conditional Requests**: Use `If-Modified-Since` header
4. **Default TTL**: 24 hours if no cache headers present

**Conditional Request Example**:
```http
GET /storage/photos/abc123.jpg HTTP/1.1
Host: app.monicahq.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
If-None-Match: "abc123-1234567890"
If-Modified-Since: Tue, 15 Mar 2024 10:30:00 GMT
```

**Response**: `304 Not Modified` (use cached version)

## Rate Limiting

### API Rate Limits

Monica API enforces rate limits to prevent abuse.

**Limits** (estimated):
- 60 requests per minute per user
- 1000 requests per hour per user

**Rate Limit Headers**:
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1700845200
```

**Exceeded Response**: `429 Too Many Requests`

```json
{
  "error": {
    "message": "Too many requests. Please wait before trying again.",
    "error_code": 429
  }
}
```

**Client Strategy**:
- Implement exponential backoff
- Respect `Retry-After` header
- Batch requests where possible
- Cache aggressively to reduce API calls

## Error Handling

### Standard Error Response

All Monica API errors follow consistent format.

**Error Response Structure**:
```json
{
  "error": {
    "message": "Human-readable error message",
    "error_code": 31
  }
}
```

**Common Error Codes**:
| Code | HTTP Status | Description |
|------|-------------|-------------|
| 30 | 400 | Validation error |
| 31 | 404 | Resource not found |
| 32 | 401 | Unauthenticated |
| 33 | 403 | Unauthorized (insufficient permissions) |
| 40 | 500 | Internal server error |
| 41 | 400 | Limit parameter error |

### Avatar-Specific Error Handling

**Decision Tree for Avatar Loading**:

```
1. Check contact.information.avatar.source
   ├─ "default" → Show initials (skip network)
   │
   ├─ "gravatar" or "photo" with URL
   │   ↓
   │   2. Attempt image load
   │      ├─ 200 OK → Display image
   │      ├─ 401/403 → Fallback to initials (log auth issue)
   │      ├─ 404 → Fallback to initials (photo deleted)
   │      ├─ 429 → Fallback to initials (rate limited)
   │      └─ Network error → Fallback to initials (show retry option)
   │
   └─ Empty/nil URL → Show initials (skip network)
```

## Security Considerations

### API Token Security

**Storage**:
- Store API token in iOS Keychain
- Never store in UserDefaults or plist files
- Mark as non-synchronizable (device-only)

**Transmission**:
- Always use HTTPS for API requests
- Token sent in `Authorization` header (not URL params)
- Validate SSL certificates

**Rotation**:
- Support token revocation/regeneration
- Clear cached images on token change
- Re-authenticate all pending requests

### Image URL Security

**Validation**:
```swift
func isValidImageURL(_ url: URL) -> Bool {
    // Ensure HTTPS
    guard url.scheme == "https" else { return false }

    // Validate host (Monica or Gravatar)
    guard let host = url.host,
          host.contains("monicahq.com") || host.contains("gravatar.com")
    else { return false }

    return true
}
```

**Content-Type Validation**:
```swift
func validateImageResponse(_ response: HTTPURLResponse) -> Bool {
    guard let contentType = response.value(forHTTPHeaderField: "Content-Type"),
          contentType.starts(with: "image/")
    else { return false }

    return true
}
```

## Implementation Checklist

- [ ] Implement Bearer token authentication for image requests
- [ ] Handle Gravatar URLs without authentication
- [ ] Parse `avatar` object from contact API response
- [ ] Respect HTTP cache headers (`Cache-Control`, `ETag`)
- [ ] Implement 24-hour default TTL for cached avatars
- [ ] Handle all error responses (401, 403, 404, 429, 500)
- [ ] Validate HTTPS and content types
- [ ] Clear avatar cache on logout
- [ ] Test photo URL authentication (Bearer vs session cookies)
- [ ] Implement rate limit backoff strategy
- [ ] Add conditional request support (`If-None-Match`)
- [ ] Validate image data before caching

## Testing Endpoints

### Test Scenarios

1. **Default Avatar** (no network request)
   - Contact with `source: "default"`
   - Verify initials + color displayed immediately

2. **Gravatar Avatar** (no auth)
   - Contact with `source: "gravatar"` and valid URL
   - Verify request has no `Authorization` header
   - Test 404 fallback to initials

3. **Photo Avatar** (authenticated)
   - Contact with `source: "photo"` and Monica URL
   - Verify request includes `Authorization: Bearer {token}`
   - Test successful load and caching

4. **Invalid Token** (401 error)
   - Request with expired/invalid token
   - Verify fallback to initials
   - Log authentication error

5. **Missing Photo** (404 error)
   - Contact with photo URL that doesn't exist
   - Verify fallback to initials

6. **Rate Limiting** (429 error)
   - Simulate rate limit exceeded
   - Verify exponential backoff
   - Fallback to initials with retry option

## References

- Monica API Documentation: https://www.monicahq.com/api
- Gravatar API: https://docs.gravatar.com/api/avatars/
- HTTP Caching RFC: https://tools.ietf.org/html/rfc7234
- Research Document: `/specs/001-003-avatar-authentication/research.md`
