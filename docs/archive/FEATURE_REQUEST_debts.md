# Feature Request: Debts Tracking

## Overview
Track money lent to or borrowed from contacts - who owes you, who you owe, with amounts and reasons.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/debts` - List all debts
- `GET /api/debts/{id}` - Get single debt
- `POST /api/debts` - Create debt
- `PUT /api/debts/{id}` - Update debt
- `DELETE /api/debts/{id}` - Delete debt
- `GET /api/contacts/{contact}/debts` - Get debts for specific contact

## Proposed Models

```swift
struct Debt: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let inDebt: String // "yes" = contact owes you, "no" = you owe contact
    let status: String // "inprogress", "complete"
    let amount: Double
    let amountCurrency: String
    let reason: String?
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case status
        case amount
        case amountCurrency = "amount_currency"
        case reason
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isOwedToMe: Bool {
        return inDebt == "yes"
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = amountCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amountCurrency) \(amount)"
    }
}

struct DebtCreatePayload: Codable {
    let contactId: Int
    let inDebt: String
    let amount: Double
    let amountCurrency: String
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case inDebt = "in_debt"
        case amount
        case amountCurrency = "amount_currency"
        case reason
    }
}
```

## UI Components Needed

### 1. DebtsListView (Global)
- Summary card: Total owed to you vs Total you owe
- Net balance calculation
- Segmented control: "They owe me" / "I owe them" / "All"
- List debts with contact name, amount, reason
- Mark as complete action

### 2. ContactDebtsSection
- Show on contact detail page
- Quick summary: net balance with this contact
- List of individual debts
- Add new debt button
- Mark complete swipe action

### 3. NewDebtView
- Direction toggle: "They owe me" / "I owe them"
- Amount input with currency picker
- Reason text field
- Contact selector (if from global view)

### 4. DebtDetailView
- Full debt information
- Edit capability
- Mark as complete button
- Delete option
- History if debt was partially paid

## Implementation Priority
**MEDIUM** - Useful for tracking financial obligations but not core relationship management

## Key Features
1. Track direction of debt (who owes whom)
2. Multiple currencies support
3. Mark debts as complete
4. Calculate net balance per contact
5. Global summary across all contacts

## Visual Design
- Use color coding: Green for "owed to you", Red for "you owe"
- Clear iconography for debt direction
- Currency-aware formatting
- Progress indicator if partial payment support added

## Dashboard Integration
- Optional widget showing total outstanding debts
- Quick action to log debt settlement
- Alert for large unpaid debts

## Related Files
- Contact.swift - Add `debts: [Debt]?` field
- MonicaAPIClient.swift - Add debt CRUD methods
- ContactDetailView.swift - Add debts section

## Notes
- Consider partial payment tracking
- Export debt summary feature
- Privacy: debts are personal financial info - handle with care
- Use device's preferred currency as default
