# Quickstart: Financial Debt Tracking

**Feature**: 007-debt-tracking
**Date**: 2025-12-03

## Overview

This feature adds debt tracking to the Monica iOS client, allowing users to:
- Record money lent to or borrowed from contacts
- View per-contact and global debt summaries
- Mark debts as settled
- Edit and delete debt records

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ContactDetailView                        │
│                            │                                 │
│                    ┌───────▼───────┐                        │
│                    │ DebtsSection  │                        │
│                    └───────┬───────┘                        │
└────────────────────────────┼────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      DebtViewModel                           │
│  • fetchDebts(contactId)                                    │
│  • createDebt(...)                                          │
│  • updateDebt(...)                                          │
│  • deleteDebt(id)                                           │
│  • markAsSettled(id)                                        │
│  • calculateNetBalance()                                    │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    DebtAPIService                            │
│  Uses MonicaAPIClient for actual API calls                  │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Monica v4.x API                          │
│  /api/debts, /api/contacts/{id}/debts                       │
└─────────────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `Features/DebtTracking/ViewModels/DebtViewModel.swift` | Business logic, state management |
| `Features/DebtTracking/Views/DebtListView.swift` | Per-contact debt list |
| `Features/DebtTracking/Views/DebtFormView.swift` | Create/edit debt form |
| `Features/DebtTracking/Views/GlobalDebtsView.swift` | All debts view |
| `Models/Contact.swift` | Debt model (update existing) |

## API Usage

### Fetch debts for a contact
```swift
let debts = try await apiClient.getDebts(for: contactId)
```

### Create a debt
```swift
let debt = try await apiClient.createDebt(
    for: contactId,
    inDebt: "yes",        // "yes" = they owe me, "no" = I owe them
    status: "inprogress", // or "completed"
    amount: 50.00,
    reason: "Lunch"
)
```

### Mark debt as settled
```swift
let updated = try await apiClient.updateDebt(
    id: debtId,
    status: "completed",
    amount: nil,
    reason: nil
)
```

### Delete a debt
```swift
try await apiClient.deleteDebt(id: debtId)
```

## Direction Values

The `in_debt` field is a string, NOT a boolean:

| API Value | Meaning | Display |
|-----------|---------|---------|
| `"yes"` | Contact owes user | "They owe me" |
| `"no"` | User owes contact | "I owe them" |

## Status Values

| API Value | Meaning | Display |
|-----------|---------|---------|
| `"inprogress"` | Outstanding debt | Shows in balance |
| `"completed"` | Settled | Visually distinct |

## Net Balance Calculation

```swift
func calculateNetBalance(debts: [Debt]) -> [NetBalance] {
    // Group by currency (extracted from amountWithCurrency)
    // For each currency:
    //   theyOweMe = sum of amounts where in_debt == "yes" && status == "inprogress"
    //   iOweThem = sum of amounts where in_debt == "no" && status == "inprogress"
    //   net = theyOweMe - iOweThem
}
```

## UI Components

### DebtRowView
- Shows direction indicator (green/red)
- Amount with currency
- Reason (if present)
- Status badge for settled debts
- Swipe actions: Mark Settled, Edit, Delete

### DebtSummaryView
- Net balance per currency
- Color coded (green = positive, red = negative)
- Tap to expand debt list

### DebtFormView
- Direction picker (They owe me / I owe them)
- Amount input with currency
- Reason text field
- Validation: amount > 0

## Testing

### Unit Tests
- `DebtViewModelTests`: Test state management, calculations
- `DebtAPIServiceTests`: Mock API responses

### Manual Testing
1. Create debt with positive amount → appears in list
2. Create debt with zero/negative → shows error
3. Mark as settled → moves to settled section
4. Edit amount → balance recalculates
5. Delete → removed from list

## Edge Cases Handled

| Case | Behavior |
|------|----------|
| Zero/negative amount | Validation error |
| Already settled | Hide "Mark as Paid" |
| Direction change | Confirmation dialog |
| Multi-currency | Separate balances per currency |
| Contact deletion | Handled by Monica API (cascade) |
