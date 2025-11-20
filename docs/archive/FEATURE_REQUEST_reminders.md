# Feature Request: Reminders Management

## Overview
Add support for managing reminders for contacts - birthdays, anniversaries, custom date-based reminders with notifications.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/reminders` - List all reminders
- `GET /api/reminders/upcoming/{month}` - Get upcoming reminders for a specific month
- `GET /api/reminders/{id}` - Get single reminder
- `POST /api/reminders` - Create reminder
- `PUT /api/reminders/{id}` - Update reminder
- `DELETE /api/reminders/{id}` - Delete reminder
- `GET /api/contacts/{contact}/reminders` - Get reminders for specific contact

## Proposed Models

```swift
struct Reminder: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let initialDate: Date
    let frequencyType: String // "one_time", "week", "month", "year"
    let frequencyNumber: Int?
    let title: String
    let description: String?
    let delible: Bool // Can be deleted
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case initialDate = "initial_date"
        case frequencyType = "frequency_type"
        case frequencyNumber = "frequency_number"
        case title
        case description
        case delible
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ReminderCreatePayload: Codable {
    let contactId: Int
    let initialDate: String // YYYY-MM-DD
    let frequencyType: String
    let frequencyNumber: Int?
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case initialDate = "initial_date"
        case frequencyType = "frequency_type"
        case frequencyNumber = "frequency_number"
        case title
        case description
    }
}
```

## UI Components Needed

### 1. RemindersListView
- List all upcoming reminders sorted by date
- Filter by: upcoming this week, this month, all
- Show contact name + reminder title
- Pull to refresh
- Badge for overdue reminders

### 2. ContactRemindersSection
- Show reminders on contact detail page
- Quick add birthday/anniversary
- Custom reminder creation
- Edit/delete existing reminders

### 3. ReminderDetailView
- Full reminder details
- Edit capability
- Frequency settings (one-time, weekly, monthly, yearly)
- Associated contact link

### 4. NewReminderView
- Date picker for initial date
- Frequency type selector
- Title and description fields
- Contact selector (if creating from global view)

### 5. UpcomingRemindersWidget (Optional)
- Dashboard widget showing next 5 reminders
- Quick navigation to reminder details

## Implementation Priority
**HIGH** - Reminders are core Monica functionality for maintaining relationships

## Key Features
1. Birthday reminders (auto-created from contact birthday)
2. Anniversary reminders
3. Custom date reminders (e.g., "Call Mom every Sunday")
4. Frequency options: one-time, weekly, monthly, yearly
5. Local notifications integration (iOS UserNotifications framework)

## iOS Integration
- Use `UNUserNotificationCenter` for local notifications
- Request notification permissions on first reminder creation
- Schedule notifications based on reminder frequency
- Badge app icon with overdue reminder count

## Related Files
- Contact.swift - May need to add `reminders: [Reminder]?` field
- MonicaAPIClient.swift - Add reminder CRUD methods
- ContentView.swift - Add Reminders tab or dashboard section

## Notes
- Birthdays are automatically converted to reminders in Monica
- Consider syncing with iOS Calendar app
- Handle timezone properly for date calculations
