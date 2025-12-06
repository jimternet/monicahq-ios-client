# Feature Specification: Financial Debt Tracking

**Feature Branch**: `007-debt-tracking`
**Created**: 2025-11-19
**Status**: Draft
**Input**: User description: "Track money lent to or borrowed from contacts - who owes you, who you owe, with amounts and reasons"
**API Verified**: ✅ Monica v4.x `/api/debts` endpoint confirmed in source code

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a New Debt (Priority: P1)

Users can log when they lend money to or borrow money from a contact, capturing the amount, currency, and reason, so they can keep track of financial obligations and maintain clear records of what's owed.

**Why this priority**: This is the core value proposition - capturing debt information. Without this, users cannot track financial obligations. It's the foundation that enables financial record-keeping with contacts.

**Independent Test**: Can be fully tested by creating a debt entry for a contact, then verifying it appears in their debt history. Delivers immediate value by creating a record of the financial transaction.

**Acceptance Scenarios**:

1. **Given** user is viewing a contact's details, **When** they tap "Add Debt", **Then** a debt creation form appears with fields for amount, currency, direction, and reason
2. **Given** user fills in debt details indicating the contact owes them, **When** they save, **Then** the debt appears in the contact's debt list marked as "They owe me"
3. **Given** user fills in debt details indicating they owe the contact, **When** they save, **Then** the debt appears marked as "I owe them"
4. **Given** user enters an amount and reason, **When** they select a currency, **Then** the amount is stored with that currency for accurate tracking

---

### User Story 2 - View Debt History Per Contact (Priority: P1)

Users can see all outstanding and settled debts with a specific contact, including net balance, helping them understand their complete financial relationship with that person.

**Why this priority**: Viewing recorded debts is essential to get value from logging them. Users need to see what's owed to make informed decisions about lending/borrowing.

**Independent Test**: Can be tested by viewing a contact's detail page and seeing their debt history displayed with net balance. Delivers value through comprehensive financial visibility.

**Acceptance Scenarios**:

1. **Given** a contact has outstanding debts, **When** user views contact details, **Then** a debts section shows all debt entries with amounts and reasons
2. **Given** multiple debts exist with a contact, **When** user views the debt summary, **Then** it shows net balance (total they owe you minus total you owe them)
3. **Given** a debt has been marked complete, **When** viewing debt history, **Then** completed debts are visually distinguished from outstanding ones
4. **Given** debts exist in multiple currencies, **When** viewing the summary, **Then** each currency is listed separately

---

### User Story 3 - Mark Debts as Settled (Priority: P2)

Users can mark debts as complete when they've been repaid, keeping their records up-to-date and accurately reflecting which obligations are still outstanding.

**Why this priority**: Essential for maintaining accurate records, but secondary to creating and viewing debts. Users need this to manage debt lifecycle.

**Independent Test**: Can be tested by marking an outstanding debt as complete and verifying it moves to settled status. Delivers value through accurate record maintenance.

**Acceptance Scenarios**:

1. **Given** an outstanding debt exists, **When** user marks it as complete, **Then** the debt status changes to "Settled" and it no longer counts toward outstanding balance
2. **Given** user is viewing a debt, **When** they tap "Mark as Paid", **Then** the debt is updated and the contact's net balance recalculates
3. **Given** a debt has been marked complete, **When** user views it later, **Then** it shows when it was settled
4. **Given** user marks a debt as complete, **When** viewing debt history, **Then** both outstanding and completed debts are accessible

---

### User Story 4 - Global Debt Overview (Priority: P2)

Users can see a summary of all debts across all contacts, showing total amounts owed to them and total amounts they owe, providing a complete picture of their financial obligations.

**Why this priority**: Adds valuable cross-contact insights but requires multiple debt entries to be useful. Important for financial awareness but not essential for basic tracking.

**Independent Test**: Can be tested by viewing a global debts list and seeing summarized totals across all contacts. Delivers value through holistic financial visibility.

**Acceptance Scenarios**:

1. **Given** user has debts with multiple contacts, **When** they view the global debts page, **Then** they see total amount owed to them and total amount they owe
2. **Given** debts exist in multiple currencies, **When** viewing global summary, **Then** each currency is listed separately with its total
3. **Given** user views global debts, **When** they filter by "They owe me", **Then** only debts where contacts owe the user are shown
4. **Given** user views global debts, **When** they tap on a debt, **Then** they navigate to that contact's detail page

---

### User Story 5 - Edit and Delete Debt Records (Priority: P3)

Users can modify or remove debt entries to correct mistakes or update information as circumstances change, maintaining control over their financial records.

**Why this priority**: Useful for data management but not part of the core debt tracking workflow. Users occasionally need this for corrections.

**Independent Test**: Can be tested by editing a debt's amount or reason and verifying the changes persist. Delivers value through data management flexibility.

**Acceptance Scenarios**:

1. **Given** a debt entry exists, **When** user edits the amount, **Then** the updated amount is saved and the net balance recalculates
2. **Given** user modifies a debt's reason, **When** they save, **Then** the new reason appears in the debt history
3. **Given** a debt was created by mistake, **When** user deletes it, **Then** it's removed from the contact's debt list and net balance updates
4. **Given** user edits a debt entry, **When** viewing it later, **Then** it shows when it was last modified

---

### Edge Cases

- **Zero/negative amounts**: Form validation prevents submission; displays inline error "Amount must be greater than zero"
- How does system handle debts with very large amounts (millions)?
- **Contact deletion with debts**: Block deletion until all debts are settled or deleted; display warning listing outstanding debts
- **Multi-currency balances**: Display separate net balance per currency with no conversion (e.g., "Net: +$50 USD, -€20 EUR")
- What happens when user creates multiple debts of the same type and amount on the same day?
- **Already-settled debts**: Hide "Mark as Paid" action for settled debts; no re-settling action available
- **Direction change on edit**: Allow with confirmation dialog warning "This will affect your net balance with this contact"

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to create debt records associated with specific contacts
- **FR-002**: System MUST capture debt direction (user owes contact OR contact owes user)
- **FR-003**: System MUST record debt amount with currency specification
- **FR-004**: System MUST allow optional reason/description for each debt
- **FR-005**: System MUST display all debts for a given contact
- **FR-006**: System MUST calculate and display net balance per contact
- **FR-007**: System MUST support marking debts as complete/settled
- **FR-008**: System MUST distinguish between outstanding and settled debts visually
- **FR-009**: System MUST persist debt records to the Monica backend
- **FR-010**: System MUST show global summary of all debts across all contacts
- **FR-011**: System MUST filter debts by direction (owed to you vs you owe)
- **FR-012**: System MUST support multiple currencies for debt amounts
- **FR-013**: System MUST allow editing existing debt records
- **FR-014**: System MUST allow deleting debt records
- **FR-015**: System MUST show when debts were created and when settled
- **FR-016**: System MUST validate that debt amounts are positive values
- **FR-017**: System MUST handle debts in different currencies without automatic conversion
- **FR-018**: System MUST update contact net balances when debts are added, edited, or settled

### Key Entities

- **Debt**: Represents a financial obligation between user and contact. Contains amount, currency, direction indicator (who owes whom), status (outstanding or complete), optional reason, and timestamps. Multiple debts can exist per contact.

- **Net Balance**: Calculated summary showing total amount owed to user minus total amount user owes for a specific contact. Separate balances maintained per currency.

- **Debt Direction**: Indicates whether the contact owes the user money or the user owes the contact money. Critical for proper accounting and visual presentation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can log a new debt in under 20 seconds
- **SC-002**: Debt records persist correctly and sync with the backend 100% of the time
- **SC-003**: Net balance calculations are accurate for all contacts with multiple debts
- **SC-004**: Users can distinguish between "they owe me" and "I owe them" debts at a glance through visual indicators
- **SC-005**: The system displays debt history within 2 seconds for contacts with 50+ debt records
- **SC-006**: 90% of users successfully create their first debt record without training
- **SC-007**: Currency formatting displays correctly for all supported currencies
- **SC-008**: Marking debts as complete updates balances immediately without requiring app restart
- **SC-009**: Global debt summary accurately reflects totals across all contacts
- **SC-010**: Users can find and settle specific debts in under 15 seconds

## Clarifications

### Session 2025-12-03

- Q: What happens when user tries to create a debt with zero or negative amount? → A: Prevent submission with inline validation error "Amount must be greater than zero"
- Q: What occurs when a contact is deleted who has outstanding debts? → A: Block contact deletion until all debts are settled or deleted
- Q: How are multi-currency net balances displayed? → A: Show separate net balance per currency (e.g., "Net: +$50 USD, -€20 EUR")
- Q: What happens when user tries to mark an already-settled debt as complete? → A: Hide "Mark as Paid" action for settled debts (no action available)
- Q: What occurs when editing a debt changes its direction? → A: Allow direction change with confirmation dialog warning of balance impact

## Assumptions

**Verified from Monica v4.x source code (`/tmp/monica-v4/`):**

- Monica backend provides debt API endpoints at `/api/debts` and `/api/contacts/{contact}/debts` (verified in `routes/api.php`)
- Debt API response includes: `id`, `uuid`, `in_debt` (direction), `status`, `amount`, `value`, `amount_with_currency`, `reason`, `contact`, `created_at`, `updated_at` (verified in `app/Http/Resources/Debt/Debt.php`)
- Debt direction field `in_debt` uses "yes"/"no" values - "yes" means contact owes user, "no" means user owes contact (verified in `app/Models/Contact/Debt.php` scopes)
- Debt status field uses "inprogress" for outstanding debts (verified in `scopeInProgress`)
- Full CRUD operations supported via API: GET (list/show), POST (create), PUT (update), DELETE

**General Assumptions:**

- Currency codes follow ISO 4217 standard (USD, EUR, GBP, etc.)
- Debts track full amounts, not partial payments (user marks complete when fully repaid)
- Backend-only architecture - no offline debt creation (consistent with existing features)
- Users primarily track informal personal debts, not complex financial instruments
- Debt records are private to the user and not shared with other Monica users
- Net balance calculation is simple addition/subtraction per currency without exchange rate conversion
- Device's locale settings can be used to determine default currency display format
