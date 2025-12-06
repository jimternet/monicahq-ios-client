# Data Model: Financial Debt Tracking

**Feature**: 007-debt-tracking
**Date**: 2025-12-03

## Entity Relationship

```
┌─────────────┐       ┌─────────────┐
│   Contact   │──1:N──│    Debt     │
└─────────────┘       └─────────────┘
       │                     │
       │                     │
       └────── Account ──────┘
```

## Entities

### Debt (Updated)

**Location**: `MonicaClient/Models/Contact.swift` (update existing struct)

```swift
/// Debt tracking between user and contact
/// API: Monica v4.x /api/debts
struct Debt: Codable, Identifiable {
    let id: Int
    let uuid: String
    let inDebt: String           // "yes" = they owe me, "no" = I owe them
    let status: String           // "inprogress" or "completed"
    let amount: Double           // Raw numeric amount
    let value: String            // Formatted decimal string (e.g., "50.00")
    let amountWithCurrency: String  // Display string (e.g., "$50.00")
    let reason: String?
    let contact: DebtContact?    // Nested contact for global view
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case inDebt = "in_debt"
        case status
        case amount
        case value
        case amountWithCurrency = "amount_with_currency"
        case reason
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### DebtContact (New)

**Location**: `MonicaClient/Models/Contact.swift`

```swift
/// Minimal contact info embedded in Debt response
/// Matches ContactShort resource from Monica API
struct DebtContact: Codable, Identifiable {
    let id: Int
    let uuid: String
    let hashId: String
    let firstName: String?
    let lastName: String?
    let completeName: String
    let initials: String

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case hashId = "hash_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case completeName = "complete_name"
        case initials
    }
}
```

### DebtDirection (New Helper Enum)

**Location**: `MonicaClient/Features/DebtTracking/Models/DebtEnums.swift`

```swift
/// Semantic wrapper for debt direction
/// Maps Monica API "yes"/"no" to meaningful values
enum DebtDirection: String, CaseIterable {
    case theyOweMe = "yes"    // Contact owes user money
    case iOweThem = "no"      // User owes contact money

    var displayLabel: String {
        switch self {
        case .theyOweMe: return "They owe me"
        case .iOweThem: return "I owe them"
        }
    }

    var shortLabel: String {
        switch self {
        case .theyOweMe: return "Owed to you"
        case .iOweThem: return "You owe"
        }
    }

    var color: Color {
        switch self {
        case .theyOweMe: return .green
        case .iOweThem: return .red
        }
    }
}
```

### DebtStatus (New Helper Enum)

**Location**: `MonicaClient/Features/DebtTracking/Models/DebtEnums.swift`

```swift
/// Semantic wrapper for debt status
enum DebtStatus: String, CaseIterable {
    case outstanding = "inprogress"
    case settled = "completed"

    var displayLabel: String {
        switch self {
        case .outstanding: return "Outstanding"
        case .settled: return "Settled"
        }
    }

    var icon: String {
        switch self {
        case .outstanding: return "clock"
        case .settled: return "checkmark.circle.fill"
        }
    }
}
```

### NetBalance (New Computed Model)

**Location**: `MonicaClient/Features/DebtTracking/Models/NetBalance.swift`

```swift
/// Calculated net balance for a contact (per currency)
/// Positive = contact owes user, Negative = user owes contact
struct NetBalance: Identifiable {
    let currency: String          // Currency symbol/code from amountWithCurrency
    let theyOweMe: Double         // Sum of debts where direction = "yes"
    let iOweThem: Double          // Sum of debts where direction = "no"

    var id: String { currency }

    var netAmount: Double {
        theyOweMe - iOweThem
    }

    var displayNet: String {
        let sign = netAmount >= 0 ? "+" : ""
        return "\(sign)\(currency)\(String(format: "%.2f", abs(netAmount)))"
    }

    var isPositive: Bool {
        netAmount >= 0
    }

    var summary: String {
        if netAmount > 0 {
            return "They owe you \(currency)\(String(format: "%.2f", netAmount))"
        } else if netAmount < 0 {
            return "You owe \(currency)\(String(format: "%.2f", abs(netAmount)))"
        } else {
            return "Settled"
        }
    }
}
```

## API Payloads

### DebtCreatePayload (Update Existing)

**Location**: `MonicaClient/Models/Contact.swift`

```swift
struct DebtCreatePayload: Codable {
    let contactId: Int
    let inDebt: String           // "yes" or "no"
    let status: String           // "inprogress" or "completed"
    let amount: Double
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case reason
    }
}
```

### DebtUpdatePayload (Update Existing)

**Location**: `MonicaClient/Models/Contact.swift`

```swift
struct DebtUpdatePayload: Codable {
    let contactId: Int           // Required by API
    let inDebt: String?          // Can update direction
    let status: String?
    let amount: Double?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case reason
    }
}
```

## Validation Rules

| Field | Rule | Error Message |
|-------|------|---------------|
| amount | Must be > 0 | "Amount must be greater than zero" |
| inDebt | Must be "yes" or "no" | "Direction is required" |
| status | Must be "inprogress" or "completed" | "Status is required" |
| contactId | Must exist and belong to user | "Invalid contact" |
| reason | Max 1,000,000 chars | "Reason is too long" |

## State Transitions

```
                    ┌──────────────┐
                    │   Created    │
                    │ (inprogress) │
                    └──────┬───────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
     ┌──────────┐   ┌──────────┐   ┌──────────┐
     │  Edited  │   │ Settled  │   │ Deleted  │
     │          │   │(completed)│   │          │
     └──────────┘   └──────────┘   └──────────┘
            │              │
            │              │
            ▼              ▼
      (back to      (can still
       inprogress)   be edited)
```

## Computed Properties

### Debt Extensions

```swift
extension Debt {
    /// Direction enum from raw string
    var direction: DebtDirection {
        DebtDirection(rawValue: inDebt) ?? .theyOweMe
    }

    /// Status enum from raw string
    var debtStatus: DebtStatus {
        DebtStatus(rawValue: status) ?? .outstanding
    }

    /// Whether debt is still outstanding
    var isOutstanding: Bool {
        status == "inprogress"
    }

    /// Whether debt is settled
    var isSettled: Bool {
        status == "completed"
    }

    /// Display name for contact (from nested object or fallback)
    var contactName: String {
        contact?.completeName ?? "Unknown"
    }

    /// Formatted creation date
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// Formatted settled date (if applicable)
    var settledDate: String? {
        guard isSettled else { return nil }
        return updatedAt.formatted(date: .abbreviated, time: .omitted)
    }
}
```

## Sample Data

```json
{
  "data": [
    {
      "id": 1,
      "uuid": "abc-123",
      "in_debt": "yes",
      "status": "inprogress",
      "amount": 5000,
      "value": "50.00",
      "amount_with_currency": "$50.00",
      "reason": "Lunch on Tuesday",
      "contact": {
        "id": 42,
        "uuid": "def-456",
        "hash_id": "h123",
        "first_name": "John",
        "last_name": "Doe",
        "complete_name": "John Doe",
        "initials": "JD"
      },
      "created_at": "2025-12-01T10:00:00Z",
      "updated_at": "2025-12-01T10:00:00Z"
    }
  ]
}
```
