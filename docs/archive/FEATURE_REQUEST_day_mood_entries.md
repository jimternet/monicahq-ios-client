# Feature Request: Day/Mood Entries Support

## Issue
The mobile app's Journal view is missing "Day" entries (mood/rating entries with emoji) that appear in the web app's journal. The web app shows a unified feed of:
- Day entries with mood ratings (emoji faces)
- Activities (created automatically from contact interactions)
- Standard journal entries (title + content)

Currently, the mobile app only shows:
- Standard journal entries (title + content)
- Activities

## Technical Details

### What's Missing
The Monica web app's journal includes "Day" entries where users can:
- Rate their day with an emoji mood indicator
- Add a short text description
- These show as "You rated your day. Edit, Delete"

### Current Mobile Implementation
- [JournalView.swift](../MonicaClient/Views/JournalView.swift) - Fetches journal entries + activities
- Uses `/journal` endpoint for standard entries
- Uses `/activities` endpoint for activities
- Missing the Day/Mood entries API integration

### API Investigation Needed
The Day entries likely use a separate API endpoint such as:
- `/days` - List all day entries
- `/day` - CRUD operations on day entries

The web app's unified journal view combines all three types chronologically.

## Proposed Solution

1. **Discover the Day API endpoint**
   - Check Monica API documentation or server routes
   - Test endpoint like `/api/days` or `/api/day`

2. **Create Day model**
   ```swift
   struct DayEntry: Codable, Identifiable {
       let id: Int
       let date: Date
       let comment: String?
       let rate: Int  // 1-5 or similar
       let createdAt: Date
       let updatedAt: Date
   }
   ```

3. **Extend JournalItem enum**
   ```swift
   enum JournalItem: Identifiable {
       case manualEntry(JournalEntry)
       case activity(Activity)
       case dayEntry(DayEntry)  // Add this
   }
   ```

4. **Add mood emoji display**
   - Map rating numbers to emoji faces
   - Style similarly to web app

5. **Add Day entry creation**
   - Allow users to "Rate your day" from the Journal view
   - Quick mood selection with optional comment

## Priority
Medium - Enhances journal completeness but current functionality is solid with standard entries + activities.

## Related Files
- [MonicaClient/Views/JournalView.swift](../MonicaClient/Views/JournalView.swift)
- [MonicaClient/Services/MonicaAPIClient.swift](../MonicaClient/Services/MonicaAPIClient.swift)
- [MonicaClient/Models/Contact.swift](../MonicaClient/Models/Contact.swift) - Contains JournalEntry model

## Current State
The mobile app successfully shows:
- Journal entries with titles and content (blue label)
- Activities with contact associations (green label)
- Chronologically sorted unified feed
- Info button explaining entry types

What's missing:
- Day/Mood rating entries with emoji indicators
