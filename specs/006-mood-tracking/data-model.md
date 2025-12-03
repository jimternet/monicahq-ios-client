# Data Model: Day and Mood Tracking

**Feature**: 006-mood-tracking
**Architecture**: Backend-only (no local persistence)
**Date**: 2025-01-27

## Overview

The mood tracking feature uses a backend-only architecture where all data operations communicate directly with the Monica API. No local persistence layer is used - all day/mood data lives on the user's Monica instance.

## API Models

### DayEntry

**Purpose**: Represents a day rating with optional comment

**Swift Definition**:
```swift
struct DayEntry: Codable, Identifiable, Hashable {
    let id: Int
    let rate: Int
    let comment: String?
    let date: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case rate
        case comment
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Field Details**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | Int | Yes | Server-assigned unique identifier |
| rate | Int | Yes | Mood rating: 1=bad, 2=okay, 3=great |
| comment | String? | No | Optional text description of the day |
| date | Date | Yes | The date being rated (not created_at) |
| createdAt | Date | Yes | Server timestamp when record was created |
| updatedAt | Date | Yes | Server timestamp when record was last modified |

**Validation Rules**:
- `rate` MUST be 1, 2, or 3 (enforced client-side and API)
- `date` MUST NOT be in the future (enforced client-side)
- `comment` SHOULD be limited to 10,000 characters
- Only one day entry per date per user (enforced by API)

**Extensions**:
```swift
extension DayEntry {
    /// Emoji representation of mood rating
    var moodEmoji: String {
        switch rate {
        case 1: return "😞"  // Bad
        case 2: return "😐"  // Okay
        case 3: return "😊"  // Great
        default: return "😐" // Fallback
        }
    }

    /// Human-readable mood description
    var moodDescription: String {
        switch rate {
        case 1: return "Bad day"
        case 2: return "Okay day"
        case 3: return "Great day"
        default: return "Day"
        }
    }

    /// Color for mood indicator
    var moodColor: Color {
        switch rate {
        case 1: return .red
        case 2: return .yellow
        case 3: return .green
        default: return .gray
        }
    }

    /// Whether entry has a comment
    var hasComment: Bool {
        comment != nil && !(comment?.isEmpty ?? true)
    }

    /// Formatted date for display
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Check if this is today's entry
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
```

---

### DayEntryCreateRequest

**Purpose**: Request payload for creating new day entries

**Swift Definition**:
```swift
struct DayEntryCreateRequest: Encodable {
    let date: String  // Format: "yyyy-MM-dd"
    let rate: Int
    let comment: String?
}
```

**Usage**:
- Created from DayEntryViewModel form state
- Sent to POST `/api/days` (or equivalent)
- Date formatted as ISO 8601 date string (not datetime)

---

### DayEntryUpdateRequest

**Purpose**: Request payload for updating existing day entries

**Swift Definition**:
```swift
struct DayEntryUpdateRequest: Encodable {
    let rate: Int
    let comment: String?
}
```

**Usage**:
- Created from DayEntryViewModel when editing
- Sent to PUT `/api/days/{id}`
- Date cannot be changed after creation

---

### MoodRating

**Purpose**: Enum for type-safe mood handling

**Swift Definition**:
```swift
enum MoodRating: Int, CaseIterable {
    case bad = 1
    case okay = 2
    case great = 3

    var emoji: String {
        switch self {
        case .bad: return "😞"
        case .okay: return "😐"
        case .great: return "😊"
        }
    }

    var label: String {
        switch self {
        case .bad: return "Bad"
        case .okay: return "Okay"
        case .great: return "Great"
        }
    }

    var color: Color {
        switch self {
        case .bad: return .red
        case .okay: return .yellow
        case .great: return .green
        }
    }

    init?(rate: Int) {
        self.init(rawValue: rate)
    }
}
```

---

## ViewModel State

### DayEntryViewModel

**Purpose**: Manages day entry list, form state, and API operations

**State Properties**:
```swift
@Published var dayEntries: [DayEntry] = []
@Published var isLoading: Bool = false
@Published var errorMessage: String?

// Form state
@Published var selectedDate: Date = Date()
@Published var selectedMood: MoodRating = .okay
@Published var comment: String = ""
@Published var isShowingForm: Bool = false
@Published var editingEntry: DayEntry?
```

**Computed Properties**:
```swift
var sortedEntries: [DayEntry] {
    // Sort by date descending (most recent first)
    dayEntries.sorted { $0.date > $1.date }
}

var isFormValid: Bool {
    // Validate form state
    // - Date not in future
    // - Mood selected (always valid with default)
    !Calendar.current.isDateInFuture(selectedDate)
}

var hasTodayEntry: Bool {
    dayEntries.contains { $0.isToday }
}

var todayEntry: DayEntry? {
    dayEntries.first { $0.isToday }
}
```

---

## API Service Interface

### DayEntryAPIService

**Purpose**: Handles all HTTP communication with Monica Day API

**Methods**:
```swift
protocol DayEntryAPIService {
    func fetchDayEntries(page: Int, limit: Int) async throws -> [DayEntry]
    func createDayEntry(_ request: DayEntryCreateRequest) async throws -> DayEntry
    func updateDayEntry(id: Int, _ request: DayEntryUpdateRequest) async throws -> DayEntry
    func deleteDayEntry(id: Int) async throws
}
```

**Error Handling**:
- Network errors → user-friendly message
- 401 Unauthorized → prompt re-authentication
- 404 Not Found → "Day entry not found"
- 422 Validation → display specific errors (e.g., "Already rated this day")

---

## Data Flow

### Create Day Entry

1. User taps "Rate Your Day" in JournalView
2. DayRatingFormView displays with today's date and mood picker
3. User selects mood and optional comment
4. User taps "Save"
5. DayEntryViewModel validates (date not future, no duplicate)
6. ViewModel creates DayEntryCreateRequest
7. ViewModel calls DayEntryAPIService.createDayEntry()
8. API returns new DayEntry
9. ViewModel adds to entries array
10. JournalView updates to show new entry

### Update Day Entry

1. User taps existing day entry in journal
2. DayEntryViewModel populates form state
3. User modifies mood and/or comment
4. User taps "Save"
5. ViewModel creates DayEntryUpdateRequest
6. ViewModel calls DayEntryAPIService.updateDayEntry()
7. API returns updated DayEntry
8. ViewModel replaces in entries array
9. View updates automatically

### Delete Day Entry

1. User swipes to delete on DayEntryRowView
2. Confirmation alert appears
3. User confirms deletion
4. ViewModel calls DayEntryAPIService.deleteDayEntry()
5. API confirms deletion
6. ViewModel removes from entries array
7. View updates automatically

---

## Integration with JournalView

### JournalItem Enum Update

```swift
enum JournalItem: Identifiable {
    case manualEntry(JournalEntry)
    case activity(Activity)
    case dayEntry(DayEntry)  // NEW

    var id: String {
        switch self {
        case .manualEntry(let entry): return "entry-\(entry.id)"
        case .activity(let activity): return "activity-\(activity.id)"
        case .dayEntry(let day): return "day-\(day.id)"  // NEW
        }
    }

    var date: Date {
        switch self {
        case .manualEntry(let entry): return entry.createdAt
        case .activity(let activity): return activity.happenedAt ?? activity.createdAt
        case .dayEntry(let day): return day.date  // NEW
        }
    }

    var isDayEntry: Bool {
        if case .dayEntry = self { return true }
        return false
    }
}
```

### Loading Day Entries

Day entries should be loaded alongside journal entries:

```swift
// In JournalView.loadJournalItems()
// Option A: If /api/days exists
let daysResponse = try await apiClient.fetchDayEntries(page: 1, limit: 100)
for day in daysResponse {
    items.append(.dayEntry(day))
}

// Option B: If mixed with /api/journal
// Parse response and filter by type field
```

---

## UI State Management

### Loading States

- `isLoading = true`: Show ProgressView overlay
- `isLoading = false, entries.isEmpty`: Show empty state with "Rate Your Day" CTA
- `isLoading = false, !entries.isEmpty`: Show list

### Form States

- Create mode: `editingEntry = nil`, form shows today's date
- Edit mode: `editingEntry != nil`, form populated with existing values
- Quick rate: Skip comment, save immediately after mood selection

---

## Relationships to Other Models

### JournalEntry

**Relationship**: Separate model, same feed
- Both appear in unified journal timeline
- Visually distinct (day entries show emoji, journal entries show title)

### Activity

**Relationship**: Separate model, same feed
- Activities may have associated contacts
- Day entries are contact-independent

---

## Future Enhancements (Out of Scope for MVP)

- Mood statistics and trends visualization
- Weekly/monthly mood summaries
- Correlation with activities/contacts
- Offline support with sync queue
- Custom mood scales (5-point, 10-point)
- Mood reminders/notifications
