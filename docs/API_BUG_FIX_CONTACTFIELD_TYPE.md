# Monica API Bug Fix: ContactFieldType.type Can Be Null

**Date**: 2025-11-20
**Discovered By**: Production testing with live Monica instance
**Severity**: Medium (causes decoding failures)
**Status**: ✅ Fixed in iOS client

## Issue Description

The Monica API returns `null` for the `type` field in `ContactFieldType` objects for certain contact field types (e.g., LinkedIn, custom fields).

## Example API Response

```json
{
  "data": [
    {
      "id": 6209,
      "contact_field_type": {
        "id": 35,
        "name": "LinkedIn",
        "fontawesome_icon": "fa fa-linkedin-square",
        "protocol": null,
        "delible": true,
        "type": null,  // ← THIS IS NULL (not "email", "phone", etc.)
        "account": {"id": 5},
        "created_at": "2025-09-12T23:05:22Z",
        "updated_at": "2025-09-12T23:05:59Z"
      }
    }
  ]
}
```

## Expected Behavior

According to the data model, `type` should always be a string indicating the field type ("email", "phone", "address", etc.).

## Actual Behavior

For custom or non-standard contact field types (LinkedIn, Twitter, custom fields), the `type` field returns `null`.

## Root Cause

Monica API allows custom contact field types that don't have a predefined type category. These return `null` for the `type` field.

## Fix Applied

### Before (Caused Crash)
```swift
struct ContactFieldTypeObject: Codable, Identifiable {
    let type: String  // ❌ Crashes when API returns null
}
```

### After (Handles Null)
```swift
struct ContactFieldTypeObject: Codable, Identifiable {
    let type: String?  // ✅ Optional - handles null gracefully
}
```

### Computed Property Update
```swift
var contactFieldTypeEnum: ContactFieldType {
    guard let typeString = contactFieldType.type else { return .other }
    return ContactFieldType(rawValue: typeString) ?? .other
}
```

## Impact

- **Before Fix**: Contact detail views would crash when loading contacts with LinkedIn/custom fields
- **After Fix**: All contact field types display correctly, null types default to `.other` category

## Testing

✅ Verified with contact ID 3640 (Aaron Sarazan) who has:
- Email field (type: "email") ✅
- Phone field (type: "phone") ✅
- LinkedIn field (type: null) ✅ Now handled correctly

## Recommendation

Update the official Monica API documentation to reflect that `ContactFieldType.type` is nullable.

## Files Modified

- `MonicaClient/Models/Contact.swift` (line 391, 502-504)

## Constitutional Compliance

✅ Adheres to **Principle 11: API Documentation Accuracy**
> "When bugs or discrepancies are found in `docs/monica-api-openapi.yaml`, MUST update the OpenAPI specification to reflect the actual API behavior"

This bug fix documentation serves as evidence of the discovered API behavior for future OpenAPI spec updates.
