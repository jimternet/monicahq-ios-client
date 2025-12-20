# Research: Monica v4 API Analysis

**Feature**: 012-monica-openapi-spec
**Date**: 2025-12-10

## Summary

Comprehensive analysis of Monica v4 API codebase (`/tmp/monica-v4`) to inform OpenAPI specification generation.

---

## 1. API Route Inventory

### Route File Location
`/tmp/monica-v4/routes/api.php`

### Authentication
- All routes protected by `auth:api` middleware (OAuth 2.0 Bearer token)
- Two public endpoints: `/statistics` and `/countries`

### Complete Endpoint List

#### Account & User
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /me | Account\ApiUserController@show | Current user profile |
| GET | /me/compliance | Account\ApiUserController@getSignedPolicies | Get signed policies |
| GET | /me/compliance/{id} | Account\ApiUserController@get | Get specific policy |
| POST | /me/compliance | Account\ApiUserController@set | Sign policy |
| POST | /me/contact | ApiMeController@store | Set user as contact |
| DELETE | /me/contact | ApiMeController@destroy | Unset user as contact |

#### Contacts (Full CRUD)
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /contacts | ApiContactController@index | List contacts |
| POST | /contacts | ApiContactController@store | Create contact |
| GET | /contacts/{contact} | ApiContactController@show | Get contact |
| PUT | /contacts/{contact} | ApiContactController@update | Update contact |
| DELETE | /contacts/{contact} | ApiContactController@destroy | Delete contact |
| PUT | /contacts/{contact}/work | ApiContactController@updateWork | Update work info |
| PUT | /contacts/{contact}/food | ApiContactController@updateFoodPreferences | Update food prefs |
| PUT | /contacts/{contact}/introduction | ApiContactController@updateIntroduction | Update intro |
| PUT | /contacts/{contact}/avatar | Contact\ApiAvatarController@update | Update avatar |
| GET | /contacts/{contact}/logs | Contact\ApiAuditLogController@index | Get audit logs |

#### Contact Sub-Resources
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /contacts/{contact}/relationships | ApiRelationshipController@index | List relationships |
| GET | /contacts/{contact}/addresses | Contact\ApiAddressController@addresses | List addresses |
| GET | /contacts/{contact}/contactfields | ApiContactFieldController@contactFields | List fields |
| GET | /contacts/{contact}/pets | ApiPetController@pets | List pets |
| GET | /contacts/{contact}/notes | ApiNoteController@notes | List notes |
| GET | /contacts/{contact}/calls | Contact\ApiCallController@calls | List calls |
| GET | /contacts/{contact}/conversations | Contact\ApiConversationController@conversations | List conversations |
| GET | /contacts/{contact}/activities | ApiActivitiesController@activities | List activities |
| GET | /contacts/{contact}/reminders | ApiReminderController@reminders | List reminders |
| GET | /contacts/{contact}/tasks | ApiTaskController@tasks | List tasks |
| GET | /contacts/{contact}/gifts | ApiGiftController@gifts | List gifts |
| GET | /contacts/{contact}/debts | ApiDebtController@debts | List debts |
| GET | /contacts/{contact}/documents | Contact\ApiDocumentController@contact | List documents |
| GET | /contacts/{contact}/photos | Contact\ApiPhotoController@contact | List photos |

#### Tags
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /tags | ApiTagController@index | List tags |
| POST | /tags | ApiTagController@store | Create tag |
| GET | /tags/{tag} | ApiTagController@show | Get tag |
| PUT | /tags/{tag} | ApiTagController@update | Update tag |
| DELETE | /tags/{tag} | ApiTagController@destroy | Delete tag |
| GET | /tags/{tag}/contacts | ApiTagController@contacts | Get contacts with tag |
| POST | /contacts/{contact}/setTags | ApiContactTagController@setTags | Set tags |
| POST | /contacts/{contact}/unsetTags | ApiContactTagController@unsetTags | Remove tags |
| POST | /contacts/{contact}/unsetTag | ApiContactTagController@unsetTag | Remove single tag |

#### Core Resources (CRUD)
Standard CRUD for: genders, places, addresses, contactfields, pets, companies, occupations, notes, calls, conversations, activities, reminders, tasks, gifts, debts, journal, lifeevents

#### Configuration (Read-Only)
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /relationshiptypegroups | ApiRelationshipTypeGroupController@index | List relationship type groups |
| GET | /relationshiptypes | ApiRelationshipTypeController@index | List relationship types |
| GET | /countries | Misc\ApiCountryController@index | List countries |
| GET | /currencies | Settings\ApiCurrencyController@index | List currencies |
| GET | /compliance | Settings\ApiComplianceController@index | List compliance items |
| GET | /statistics | Statistics\ApiStatisticsController@index | Get statistics |
| GET | /logs | Settings\ApiAuditLogController@index | Get audit logs |

#### Activity Configuration (Full CRUD)
| Method | Path | Controller | Description |
|--------|------|------------|-------------|
| GET | /activitytypes | Account\Activity\ApiActivityTypeController@index | List activity types |
| GET | /activitytypecategories | Account\Activity\ApiActivityTypeCategoryController@index | List categories |

#### File Uploads
| Method | Path | Controller | Content-Type |
|--------|------|------------|--------------|
| POST | /photos | Contact\ApiPhotoController@store | multipart/form-data |
| POST | /documents | Contact\ApiDocumentController@store | multipart/form-data |

### Route Statistics
- **Total Endpoints**: ~150+
- **Resource Controllers**: 39
- **Public Endpoints**: 2 (/statistics, /countries)
- **CRUD Resources**: 25+

---

## 2. Laravel Resource Pattern Analysis

### Standard Resource Structure

Every resource includes:
```json
{
  "id": integer,
  "uuid": string,
  "object": "resource_type",
  "account": { "id": integer },
  "created_at": "ISO8601 timestamp",
  "updated_at": "ISO8601 timestamp"
}
```

### Resource Examples

#### Contact Resource (Complex)
Key fields: id, uuid, object, hash_id, first_name, last_name, nickname, complete_name, initials, description, gender, gender_type, is_starred, is_partial, is_active, is_dead, is_me

Nested objects:
- `information.relationships` - love/family/friend/work groups
- `information.dates` - birthdate, deceased_date
- `information.career` - job, company
- `information.avatar` - url, source, default_avatar_color
- `addresses[]` - Address resources
- `tags[]` - Tag resources
- `statistics` - counts for calls, notes, activities, etc.
- `contactFields[]` - optional, with `?with=contactfields`

#### Note Resource (Simple)
Fields: id, uuid, object, body, is_favorited, favorited_at, url, account, contact (ContactShort), created_at, updated_at

#### Activity Resource (Related Data)
Fields: id, uuid, object, summary, description, happened_at, activity_type (nested), attendees (count + contacts), emotions[], url, account, created_at, updated_at

### Conditional Fields Pattern
```php
$this->when($condition, new Resource($this->relation))
```
Used for partial contacts and optional expansions.

---

## 3. Validation Rule Patterns

### Location
Validation rules are in **Service Classes**, not controllers.
Path pattern: `/tmp/monica-v4/app/Services/{Domain}/{Entity}/Create{Entity}.php`

### Common Rule Patterns

| Pattern | Example | Usage |
|---------|---------|-------|
| Required | `'field' => 'required'` | Mandatory fields |
| Nullable | `'field' => 'nullable\|string'` | Optional fields |
| Exists | `'account_id' => 'exists:accounts,id'` | Foreign key validation |
| Max length | `'name' => 'max:255'` | String limits |
| Boolean | `'is_active' => 'boolean'` | Flag fields |
| Enum | `Rule::in(['a', 'b', 'c'])` | Fixed options |
| Conditional | `'photo_id' => 'required_if:source,photo'` | Dependent fields |
| File | `'photo' => 'file\|image'` | Upload validation |
| Either/Or | `'photo' => 'required_without:data'` | Alternative inputs |

### Contact Creation Validation (Example)
```php
'first_name' => 'required|string|max:255',
'last_name' => 'nullable|string|max:255',
'gender_id' => 'nullable|integer|exists:genders,id',
'is_birthdate_known' => 'required|boolean',
'birthdate_day' => 'nullable|integer',
```

---

## 4. Error Response Patterns

### Error Response Format
```json
{
  "error": {
    "message": "string or array",
    "error_code": integer
  }
}
```

### Error Codes (from config/api.php)
| Code | HTTP | Description |
|------|------|-------------|
| 30 | 400 | Limit parameter too big |
| 31 | 404 | Resource not found |
| 32 | 422 | Validation/save error |
| 33 | 500 | Too many parameters |
| 34 | 429 | Rate limit exceeded |
| 35 | 422 | Email already taken |
| 36 | 422 | Invalid partial contact relationship |
| 37 | 400 | JSON parsing error |
| 38 | 422 | Date must be in future |
| 39 | 400 | Invalid sort criteria |
| 40 | 500 | Invalid query |
| 41 | 422 | Invalid parameters |
| 42 | 401 | Not authorized |

### Validation Error Response
```json
{
  "error": {
    "message": [
      "The body field is required.",
      "The contact_id must be an integer."
    ],
    "error_code": 32
  }
}
```

---

## 5. Pagination Pattern

### Configuration
- **Max per page**: 100 (configurable: `MAX_API_LIMIT_PER_PAGE`)
- **Default per page**: 15 (Laravel default)
- **Timestamp format**: `Y-m-d\TH:i:s\Z`

### Query Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| page | 1 | Page number |
| limit | 15 | Items per page (max 100) |
| sort | created_at | Sort field |
| sort (desc) | -created_at | Descending sort (prefix -) |

### Valid Sort Fields
`created_at`, `updated_at`, `completed_at`, `called_at`, `favorited_at`

### Paginated Response Structure
```json
{
  "data": [...],
  "links": {
    "first": "http://example.com/api/contacts?page=1",
    "last": "http://example.com/api/contacts?page=10",
    "prev": null,
    "next": "http://example.com/api/contacts?page=2"
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 10,
    "path": "http://example.com/api/contacts",
    "per_page": 15,
    "to": 15,
    "total": 150
  }
}
```

---

## 6. File Upload Handling

### Photo Upload
**Endpoint**: `POST /photos`
**Content-Type**: `multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| contact_id | integer | Yes | Contact to attach to |
| photo | file | Yes* | Image file upload |
| data | string | Yes* | Base64 image data |
| extension | string | No | File extension hint |

*Either `photo` or `data` required, not both.

### Document Upload
**Endpoint**: `POST /documents`
**Content-Type**: `multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| contact_id | integer | Yes | Contact to attach to |
| document | file | Yes | Any file type |

### Avatar Update
**Endpoint**: `PUT /contacts/{contact}/avatar`
**Content-Type**: `application/json`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| source | string | Yes | One of: default, adorable, gravatar, photo |
| photo_id | integer | Conditional | Required if source=photo |

---

## 7. Key Decisions for OpenAPI Spec

### Decision 1: Output Format
**Choice**: JSON only
**Rationale**: User preference; better for programmatic consumption

### Decision 2: Conditional Fields
**Choice**: Document all as optional with descriptions
**Rationale**: Complete coverage without multiple schema variants

### Decision 3: Versioning
**Choice**: Match Monica v4.x version
**Rationale**: Clear relationship between spec and source

### Decision 4: Authentication Scheme
**Choice**: OAuth 2.0 Bearer token
**Source**: `auth:api` middleware across all routes

### Decision 5: Base URL
**Choice**: `/api` prefix for all endpoints
**Source**: routes/api.php configuration

---

## Appendix: File Counts

| Category | Count |
|----------|-------|
| API Controllers | 39 |
| Resource Classes | 45 |
| Model Classes | 65 |
| Unique Endpoints | ~150+ |
| Error Codes | 13 |
