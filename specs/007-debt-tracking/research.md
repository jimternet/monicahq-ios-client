# Research: Financial Debt Tracking

**Feature**: 007-debt-tracking
**Date**: 2025-12-03
**Source**: Monica v4.x at `/tmp/monica-v4/`

## API Verification

### Debt Endpoints (Verified)

| Endpoint | Method | Purpose | Source |
|----------|--------|---------|--------|
| `/api/debts` | GET | List all debts | `routes/api.php`, `ApiDebtController@index` |
| `/api/debts` | POST | Create debt | `routes/api.php`, `ApiDebtController@store` |
| `/api/debts/{id}` | GET | Get single debt | `routes/api.php`, `ApiDebtController@show` |
| `/api/debts/{id}` | PUT | Update debt | `routes/api.php`, `ApiDebtController@update` |
| `/api/debts/{id}` | DELETE | Delete debt | `routes/api.php`, `ApiDebtController@destroy` |
| `/api/contacts/{id}/debts` | GET | Debts for contact | `routes/api.php`, `ApiDebtController@debts` |

### API Response Structure

From `app/Http/Resources/Debt/Debt.php`:

```json
{
  "id": 123,
  "uuid": "abc-123-def",
  "object": "debt",
  "in_debt": "yes",
  "status": "inprogress",
  "amount": 5000,
  "value": "50.00",
  "amount_with_currency": "$50.00",
  "reason": "Dinner loan",
  "account": { "id": 1 },
  "contact": { /* ContactShort resource */ },
  "created_at": "2025-12-03T10:00:00Z",
  "updated_at": "2025-12-03T10:00:00Z"
}
```

### API Field Mappings

| API Field | Type | Description | iOS Model Field |
|-----------|------|-------------|-----------------|
| `id` | int | Unique identifier | `id: Int` |
| `uuid` | string | UUID | `uuid: String` |
| `in_debt` | string | "yes" = contact owes user, "no" = user owes contact | `inDebt: DebtDirection` |
| `status` | string | "inprogress" or "completed" | `status: DebtStatus` |
| `amount` | int | Raw amount in smallest currency unit | `amount: Int` |
| `value` | string | Formatted decimal value | `value: String` |
| `amount_with_currency` | string | Display string with currency symbol | `amountWithCurrency: String` |
| `reason` | string? | Optional description | `reason: String?` |
| `contact` | object | Nested contact info | `contact: DebtContact` |
| `created_at` | datetime | Creation timestamp | `createdAt: Date` |
| `updated_at` | datetime | Last update timestamp | `updatedAt: Date` |

### Request Payload Validation

From `ApiDebtController::validateUpdate()`:

```php
$validator = Validator::make($request->all(), [
    'in_debt' => ['required', 'string', Rule::in(['yes', 'no'])],
    'status' => ['required', 'string', Rule::in(['inprogress', 'completed'])],
    'amount' => 'required|numeric',
    'reason' => 'string|max:1000000|nullable',
    'contact_id' => 'required|integer',
]);
```

**Key Finding**: `in_debt` is a string ("yes"/"no"), NOT a boolean.

### Currency Handling

From `app/Traits/AmountFormatter.php` and migrations:
- Debts have a `currency_id` foreign key to `currencies` table
- Amount stored as decimal(13,2)
- `displayValue` method formats with currency symbol
- Currency follows user's account settings by default

**Decision**: Use `amount_with_currency` from API response for display; don't implement client-side currency formatting.

## Design Decisions

### Decision 1: Direction Field Handling

**Decision**: Create `DebtDirection` enum mapping "yes"/"no" to semantic values

**Rationale**: The API uses strings "yes"/"no" which is unintuitive. An enum provides type safety and clear semantics.

**Alternatives Considered**:
- Raw string handling: Rejected due to lack of type safety
- Boolean conversion at API layer: Rejected as it would lose API fidelity

**Implementation**:
```swift
enum DebtDirection: String, Codable {
    case theyOweMe = "yes"    // contact owes user
    case iOweThem = "no"      // user owes contact
}
```

### Decision 2: Status Field Handling

**Decision**: Create `DebtStatus` enum for "inprogress"/"completed"

**Rationale**: Type safety and clearer semantics than raw strings.

**Implementation**:
```swift
enum DebtStatus: String, Codable {
    case outstanding = "inprogress"
    case settled = "completed"
}
```

### Decision 3: Net Balance Calculation

**Decision**: Calculate net balance client-side from fetched debts

**Rationale**: Monica API doesn't provide aggregate endpoints. Client-side calculation allows:
- Per-currency balances (spec requirement)
- Immediate updates when debts change
- No additional API calls

**Alternatives Considered**:
- Server-side calculation: Not available in Monica API
- Cached balance with sync: Over-engineered for use case

### Decision 4: Global Debts View

**Decision**: Fetch all debts via `/api/debts` endpoint with pagination

**Rationale**: Monica provides a global debts endpoint that returns all debts across contacts. This is more efficient than fetching per-contact.

### Decision 5: Existing Model Update

**Decision**: Update existing `Debt` struct in `Contact.swift` rather than creating new model

**Rationale**:
- Model already exists with basic fields
- Follows existing codebase pattern
- Avoids model duplication

**Updates Needed**:
- Add `uuid` field
- Change `inDebt: Bool` to `inDebt: String` (or create direction enum)
- Add `value` and `amountWithCurrency` fields
- Add nested `contact` object for global view

## Best Practices Applied

### SwiftUI Patterns
- Use `@StateObject` for ViewModel in parent views
- Use `@ObservedObject` in child views
- Async/await for all API calls
- Pull-to-refresh for list views

### MVVM Architecture
- ViewModel handles all business logic
- Views are purely declarative
- API service injected for testability

### Error Handling
- Use `Result` type for API responses
- Display user-friendly error messages
- Log technical errors for debugging

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| How does API handle currency? | `amount_with_currency` includes formatted value; no client formatting needed |
| What's the direction field format? | String "yes"/"no", NOT boolean |
| Is partial payment supported? | No - debts are full amounts, marked complete when paid |
| Can direction be changed on edit? | Yes - API allows updating `in_debt` field |
