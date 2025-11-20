# Monica iOS Client - Feature Roadmap

## Overview
This document summarizes all identified missing features from the Monica v4.x web application that could be implemented in the iOS client. Features are prioritized based on value to relationship management and implementation complexity.

## Current Implementation (MVP)
- Contacts list with search
- Contact details (name, birthday, notes, tags, gifts, tasks)
- Contact field management (phone, email, social)
- Journal entries (view, create, edit, delete)
- Activities (view in journal feed)
- Notes (view, create, edit, delete)
- Tasks (view, create, update status)
- Gifts (view, create, update status)
- Tags (view, create, assign)
- Offline support with Core Data
- API authentication

## Feature Priority Matrix

### HIGH Priority (Core CRM Value)
1. **[Reminders](FEATURE_REQUEST_reminders.md)** - Birthday/anniversary alerts, custom reminders
2. **[Relationships](FEATURE_REQUEST_relationships.md)** - Family trees, contact networks
3. **[Day/Mood Entries](FEATURE_REQUEST_day_mood_entries.md)** - Daily mood tracking in journal

### MEDIUM-HIGH Priority
4. **[Life Events](FEATURE_REQUEST_life_events.md)** - Track major life milestones
5. **[Addresses](FEATURE_REQUEST_addresses.md)** - Location management with maps

### MEDIUM Priority
6. **[Debts](FEATURE_REQUEST_debts.md)** - Money tracking between contacts
7. **[Call Logging](FEATURE_REQUEST_calls.md)** - Phone call history and notes
8. **[Photos](FEATURE_REQUEST_photos.md)** - Contact photo galleries
9. **[Work/Occupation](FEATURE_REQUEST_work_occupation.md)** - Career and employment tracking
10. **[Avatars](FEATURE_REQUEST_avatar_images.md)** - Profile picture support

### LOW-MEDIUM Priority
11. **[Conversations](FEATURE_REQUEST_conversations.md)** - Text/email thread archiving
12. **[Documents](FEATURE_REQUEST_documents.md)** - File attachments for contacts
13. **[Pets](FEATURE_REQUEST_pets.md)** - Track contact's pets

## API Coverage Summary

| Feature | API Available | Priority | Complexity |
|---------|--------------|----------|------------|
| Reminders | `/api/reminders` | HIGH | Medium |
| Relationships | `/api/relationships` | HIGH | High |
| Day Entries | Needs investigation | HIGH | Low |
| Life Events | `/api/lifeevents` | MEDIUM-HIGH | Medium |
| Addresses | `/api/addresses` | MEDIUM-HIGH | Medium |
| Debts | `/api/debts` | MEDIUM | Low |
| Calls | `/api/calls` | MEDIUM | Low |
| Photos | `/api/photos` | MEDIUM | Medium |
| Work/Occupation | `/api/occupations` | MEDIUM | Medium |
| Conversations | `/api/conversations` | LOW-MEDIUM | High |
| Documents | `/api/documents` | LOW-MEDIUM | Medium |
| Pets | `/api/pets` | LOW-MEDIUM | Low |

## Known Bugs to Fix

### Server-Side
1. **Journal Entry API Bug** - [MONICA_API_BUG_FIX.md](MONICA_API_BUG_FIX.md)
   - POST /api/journal doesn't create polymorphic link
   - Entries created via API don't appear in web journal
   - Requires server-side patch

### Client-Side
1. Avatar image loading - Currently using initials fallback
2. Date formatting inconsistencies

## Recommended Implementation Order

### Phase 1: Complete Journal (1-2 weeks)
- Fix server-side journal entry bug
- Add Day/Mood entries support
- Enhance journal feed with all entry types

### Phase 2: Core Relationship Features (2-3 weeks)
- Reminders with iOS notifications
- Relationships and family trees
- Addresses with MapKit integration

### Phase 3: Enhanced Contact Information (2-3 weeks)
- Life events timeline
- Work/occupation history
- Pet tracking
- Debts management

### Phase 4: Communication Tracking (2-3 weeks)
- Call logging
- Conversation archiving
- Communication frequency analytics

### Phase 5: Media & Documents (3-4 weeks)
- Photo galleries with upload
- Document management
- Avatar/profile picture support
- File caching and offline access

## Technical Considerations

### iOS Frameworks Needed
- **UserNotifications** - Local notifications for reminders
- **MapKit** - Address display and directions
- **PhotosUI** - Photo picker and gallery
- **VNDocumentCameraScan** - Document scanning
- **CallKit** - Call detection (optional)
- **Core Data** - Offline caching for all new models

### API Client Extensions
Each feature requires:
1. New model structs with Codable conformance
2. API endpoint methods in MonicaAPIClient
3. Response type definitions
4. Error handling

### Data Synchronization
- Incremental sync for large datasets
- Conflict resolution strategies
- Offline queue for mutations
- Background sync support

## Storage Considerations

### Local Caching Priorities
1. **Must Cache**: Contacts, relationship types, pet categories, countries
2. **Should Cache**: Recent reminders, photos thumbnails
3. **Optional Cache**: Full documents, all photos

### Estimated Storage Requirements
- Base app: ~50MB
- Per contact with full data: ~1-5MB
- Photo cache: 100MB-1GB (configurable)
- Document cache: 50MB-500MB (configurable)

## User Experience Principles

1. **Progressive Disclosure** - Start simple, reveal complexity as needed
2. **Offline First** - Core features work without network
3. **Quick Actions** - Most common tasks in 2-3 taps
4. **Privacy Conscious** - Clear about what's synced
5. **Battery Efficient** - Background sync is configurable

## Success Metrics

- Feature adoption rate
- Data completeness per contact
- Sync reliability
- App performance (launch time, memory)
- User retention

## Contributing

Each feature request includes:
- API endpoints documentation
- Swift model definitions
- UI component specifications
- Implementation considerations
- Related file references

See individual feature request documents for detailed specifications.

## Next Steps

1. Review and prioritize features with stakeholders
2. Create detailed technical specs for Phase 1
3. Set up development environment for server-side patches
4. Begin reminders implementation
5. Plan notification permission flow

---

*Last Updated: November 2024*
*Monica Server Version: 4.1.2*
*iOS Target: iOS 16+*
