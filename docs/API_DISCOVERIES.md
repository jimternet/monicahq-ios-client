# Monica API Discoveries

This document records undocumented or incorrectly documented aspects of the Monica API discovered during implementation.

## Contact Update Endpoint (PUT /api/contacts/{id})

### Discovery Date: 2024-11-08

### Issue
The Monica API returns a 422 "Unprocessable Entity" error when updating contacts without the following required fields:
- `is_birthdate_known` (boolean)
- `is_deceased` (boolean) 
- `is_deceased_date_known` (boolean)

### Error Response
```json
{
  "error": {
    "message": [
      "The is birthdate known field is required.",
      "The is deceased field is required.",
      "The is deceased date known field is required."
    ],
    "error_code": 32
  }
}
```

### Solution
Always include these fields in contact update requests, even when not modifying birthdate or deceased status:

```json
{
  "first_name": "John",
  "last_name": "Doe",
  "is_birthdate_known": true,     // Required - set based on whether birthdate is provided
  "is_deceased": false,           // Required - whether contact is deceased
  "is_deceased_date_known": false, // Required - set based on whether deceased date is known
  "birthdate": "1990-01-15",      // Optional - only if is_birthdate_known is true
  "deceased_date": null           // Optional - only if is_deceased_date_known is true
}
```

### Implementation
- Updated `ContactUpdatePayload` struct to include required fields
- Modified `updateContact()` method to always send these fields
- Updated OpenAPI specification at `docs/monica-api-openapi.yaml`

### Testing
Use the test script `test_contact_update.sh` to verify the fix works with your Monica instance.

---

## Contact Update Response Format (PUT /api/contacts/{id})

### Discovery Date: 2024-11-08

### Issue
The Monica API returns contact update responses wrapped in a `data` object, not as direct Contact objects.

### Response Format
```json
{
  "data": {
    "id": 3121,
    "first_name": "Aaron",
    "last_name": "Drake",
    // ... rest of contact fields
  }
}
```

### Solution
Created `ContactApiResponse` wrapper struct and updated decoding logic to handle both wrapped and direct responses:

```swift
struct ContactApiResponse: Codable {
    let data: Contact
}

// In updateContact method:
if responseString.contains("\"data\":") {
    let wrappedResponse = try decoder.decode(ContactApiResponse.self, from: data)
    return wrappedResponse.data
} else {
    return try decoder.decode(Contact.self, from: data)
}
```

---

## Birthdate Fields Requirement (PUT /api/contacts/{id})

### Discovery Date: 2024-11-09

### Issue
The Monica API requires a specific birthdate structure with separate day/month/year fields instead of a single birthdate string.

### Error Response
```json
{
  "error": {
    "message": [
      "The day field is required.",
      "The month field is required."
    ],
    "error_code": 32
  }
}
```

### Solution
Use the correct Monica API birthdate structure:

```json
{
  "first_name": "Aaron",
  "last_name": "Drake",
  "nickname": "Draker",
  "gender_id": null,
  "birthdate_day": 15,
  "birthdate_month": 1,
  "birthdate_year": 1976,
  "birthdate_is_age_based": false,
  "is_birthdate_known": true,
  "birthdate_age": null,
  "is_partial": false,
  "is_deceased": false,
  "deceased_date": null,
  "deceased_date_is_age_based": false,
  "deceased_date_is_year_unknown": false,
  "deceased_date_age": null,
  "is_deceased_date_known": false
}
```

### Implementation
- Completely restructured `ContactUpdatePayload` to match Monica API specification
- Added proper birthdate fields: `birthdate_day`, `birthdate_month`, `birthdate_year`
- Added deceased date fields and age-based birthdate support
- Modified `updateContact()` method to extract date components using `Calendar.current.component()`
- All required boolean flags now properly set according to Monica API requirements
- Updated OpenAPI specification at `docs/monica-api-openapi.yaml` with correct ContactUpdate schema

---

## Task Schema (GET/POST/PUT /api/tasks)

### Discovery Date: 2024-11-18

### Issue
The Monica API v4.x Task schema is simpler than initially assumed. The API does NOT support:
- Priority levels (low, medium, high, urgent)
- Due dates
- Completion timestamps

### Actual Task Response Schema
```json
{
  "data": {
    "id": 123,
    "contact_id": 2940,
    "title": "Call about project",
    "description": "Follow up on the proposal",
    "completed": false,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Solution
Simplified the `MonicaTask` model to only include fields that the API actually provides:

```swift
struct MonicaTask: Codable, Identifiable {
    let id: Int
    let contactId: Int?
    let title: String
    let description: String?
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case title
        case description
        case isCompleted = "completed"  // Note: API uses "completed" not "is_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### Implementation
- Removed `TaskPriority` enum and `priority` field
- Removed `dueDate` and `completedAt` optional Date fields
- Updated API client methods `createTask()` and `updateTask()` to remove priority/dueDate parameters
- Updated `TaskRowView`, `AddTaskView`, and `EditTaskView` to remove UI for priority and due dates
- Fixed field name from `"is_completed"` to `"completed"` in CodingKeys

### Testing
Tasks now decode successfully from the API without throwing `keyNotFound` errors.

---

## Task Update Requirement (PUT /api/tasks/{id})

### Discovery Date: 2024-11-18

### Issue
The Monica API requires the `title` field even when updating only the `completed` status of a task.

### Error Response
```json
{
  "error": {
    "message": ["The title field is required."],
    "error_code": 32
  }
}
```

### Solution
Always include the task's existing `title` (and optionally `description`) when updating any task field:

```swift
// Toggling completion status
let response = try await apiClient.updateTask(
    id: task.id,
    title: task.title,           // Required - include existing title
    description: task.description, // Optional - but good practice to include
    isCompleted: !task.isCompleted
)
```

### Implementation
- Updated `toggleTaskCompletion()` in ContactDetailView to always pass title and description
- Even though `updateTask()` method has optional parameters, the API requires `title` to be present

---

## Gift Schema (GET /api/gifts)

### Discovery Date: 2024-11-18

### Issue
The Monica API does not return `contact_id` field when fetching gifts, even though it's required when creating gifts.

### Error Response
```
keyNotFound(CodingKeys(stringValue: "contact_id", intValue: nil))
```

### Solution
Make `contactId` optional in the Gift model:

```swift
struct Gift: Codable, Identifiable {
    let id: Int
    let contactId: Int?  // Optional - API doesn't return this when fetching
    let name: String
    let comment: String?
    let status: String  // "idea", "offered", or "received"
    let url: String?
    let value: Double?
    let createdAt: Date
    let updatedAt: Date
}
```

### Implementation
- Changed `contactId` from `Int` to `Int?` in Gift model
- When creating gifts, we still provide the `contact_id` in the request body
- When fetching gifts, the field is missing from the response and is decoded as nil

### Additional Issue: Value Field Type
The API returns `value` as a String instead of a number, requiring custom decoding:

```swift
// Custom decoding to handle value as either String or Double
init(from decoder: Decoder) throws {
    // ... other fields ...

    // Handle value as either String or Double
    if let valueString = try? container.decodeIfPresent(String.self, forKey: .value) {
        value = Double(valueString)
    } else {
        value = try container.decodeIfPresent(Double.self, forKey: .value)
    }
}
```

---

## Additional Discoveries

(Add future API discoveries here as they are encountered)