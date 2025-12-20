# Task: Contact Reminders and Notifications

## Spec Reference
- **Spec Location**: `specs/014-reminders/`
- **Feature Branch**: `001-014-reminders` (to be created)
- **Status**: pending

## Description
Add support for managing reminders for contacts - birthdays, anniversaries, custom date-based reminders with notifications.

This feature enables users to:
- Create reminders for important contact-related dates
- View upcoming reminders across all contacts
- Configure reminder recurrence (one-time, weekly, monthly, yearly)
- Receive local notifications for reminder alerts
- Manage and edit existing reminders

## Priority Stories
1. **P1**: Create Contact Reminders - Set reminders with dates, titles, descriptions
2. **P1**: View Upcoming Reminders - Chronological list of all upcoming reminders
3. **P2**: Configure Reminder Recurrence - Set repeating reminders
4. **P2**: Receive Reminder Notifications - Local notifications for alerts
5. **P3**: Manage and Edit Reminders - Modify or delete reminders

## Key Entities
- **Reminder**: Time-based alert associated with a contact
- **Recurrence Pattern**: Configuration for reminder repetition
- **Reminder Timeline**: Chronological view grouped by time period

## Action Required
1. Create feature branch: `git checkout -b feature/014-reminders`
2. Review spec at `specs/014-reminders/spec.md`
3. Create implementation plan
4. Implement according to spec requirements

## Notes
- Requires Monica backend API endpoints at `/api/reminders` and `/api/contacts/{contact}/reminders`
- Upcoming reminders endpoint at `/api/reminders/upcoming/{month}`
- Requires device notification permissions handling
- Reminder dates stored with day precision
