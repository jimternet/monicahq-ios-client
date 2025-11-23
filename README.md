# Monica iOS Client MVP

A privacy-first iOS application for viewing and searching Monica CRM contacts with read-only functionality.

## Features

✅ **Authentication & API Configuration (P1)**
- Connect to Monica Cloud or self-hosted instances
- Secure API token storage in iOS Keychain
- Automatic authentication validation

✅ **Browse & Paginate Contacts (P1)**
- View paginated contact lists (50 contacts per page)
- Pull-to-refresh functionality
- Smooth 60fps scrolling performance
- Empty state handling

✅ **Search Contacts (P2)**
- Real-time contact search with 300ms debouncing
- Search result caching
- Clear search functionality

✅ **View Contact Details (P2)**
- Comprehensive contact information display
- Activities, notes, and tasks sections
- Email/phone tap handlers for system integration
- Navigation between contact details

✅ **Error Handling (P1)**
- Comprehensive error handling with retry logic
- Network connectivity monitoring
- User-friendly error messages
- Automatic logout on authentication failures

✅ **Settings Management (P2)**
- Account information display
- Cache management and clearing
- Instance switching
- Logout functionality
- App version information

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Monica API v1.0 compatible instance

## Setup Instructions

### 1. Clone and Build

```bash
git clone <repository-url>
cd monicaHqClient
open MonicaClient.xcodeproj
```

### 2. API Token Setup

#### For Monica Cloud (app.monicahq.com):
1. Go to https://app.monicahq.com/settings/api
2. Generate a new API token
3. Copy the token for use in the app

#### For Self-Hosted Monica:
1. Navigate to your Monica instance: `https://your-monica-instance.com/settings/api`
2. Generate a new API token
3. Note your instance URL and API token

### 3. First Launch Configuration

1. Launch the app
2. Select "Monica Cloud" or "Self-Hosted"
3. Enter your API URL:
   - Monica Cloud: `https://app.monicahq.com`
   - Self-Hosted: `https://your-monica-instance.com`
4. Enter your API token
5. Tap "Connect"

## Architecture

- **Language**: Swift 5.5+ with async/await support
- **UI Framework**: SwiftUI with MVVM architecture
- **Storage**: Keychain (API tokens), UserDefaults (settings), Core Data (contact cache)
- **Networking**: URLSession with no external dependencies
- **Platform**: iOS 15.0+ (iPhone optimized)

### Project Structure

```
MonicaClient/
├── App/                    # App entry point and lifecycle
├── Features/               # Feature-based organization
│   ├── Authentication/     # Login and onboarding
│   ├── ContactList/        # Contact browsing and search
│   ├── ContactDetail/      # Contact detail views
│   └── Settings/           # Settings management
├── Services/               # Shared business logic
│   ├── API/                # Monica API client
│   └── Storage/            # Keychain, UserDefaults, Cache
├── Models/                 # Data models
├── Utilities/              # Extensions, constants, helpers
└── Resources/              # Assets and configuration
```

## API Compatibility

This app is designed to work with Monica Personal CRM API v1.0:
- Contacts endpoint: `/api/contacts` (GET, PUT)
- Activities endpoint: `/api/activities` (GET)
- Notes endpoint: `/api/notes` (GET, POST, PUT, DELETE)
- Tasks endpoint: `/api/tasks` (GET)
- Relationships endpoint: `/api/relationships` (GET, POST, DELETE)
- Relationship Types endpoint: `/api/relationshiptypes` (GET)
- Genders endpoint: `/api/genders` (GET)
- Tags endpoint: `/api/tags` (GET)
- Work Information endpoint: `/api/contacts/{id}/work` (PUT)
- Authentication via Bearer token

## Security & Privacy

- ✅ **Secure Storage**: API tokens stored in iOS Keychain
- ✅ **HTTPS Only**: All API communication over HTTPS
- ✅ **No Analytics**: No user data tracking or analytics
- ✅ **Local Caching**: Contact data cached locally for performance
- ✅ **PII Protection**: No personally identifiable information in logs

## Performance Goals

- ✅ App launch: < 2 seconds
- ✅ Contact list load: < 2 seconds
- ✅ Search results: < 500ms
- ✅ 60fps scrolling
- ✅ Memory usage: < 100MB

## Development Status

### ✅ Completed - Full MVP Ready!
- ✅ User Story 1: Authentication & API Configuration (P1)
- ✅ User Story 2: Browse & Paginate Contacts (P1)
- ✅ User Story 3: Search Contacts (P2)
- ✅ User Story 4: View Contact Details (P2)
- ✅ User Story 5: Activity Timeline (P3)
- ✅ User Story 6: Contact Relationships (P3)
- ✅ User Story 7: Notes & Tasks (P3)
- ✅ User Story 8: Tags & Organization (P4)
- ✅ User Story 9: Error Handling (P1)
- ✅ User Story 10: Settings Management (P2)

### 🎉 New Features in this Release
- **Basic Contact Editing**: Edit name and nickname (gender selection available if /genders endpoint is accessible)
- **Relationship Management**: Add and delete relationships between contacts
- **Notes Management**: View, create, update, and favorite notes
- **Tags Display**: View contact tags with color-coded badges
- **Work Information**: Edit job title and company
- **Enhanced Sections**: How You Met, Food Preferences, Stay in Touch

### 🔄 Future Enhancements
- Tag filtering and management
- Additional contact field editing
- Advanced activity timeline features

## Troubleshooting

### Common Issues

**"Invalid API token"**
- Verify your API token is correct
- Check that the token has proper permissions
- Ensure your Monica instance is accessible

**"Cannot connect to server"**
- Check your internet connection
- Verify the API URL is correct
- Ensure Monica instance is running (self-hosted)

**"No contacts found"**
- Verify contacts exist in your Monica instance
- Check API token permissions
- Try pull-to-refresh to sync data

### Getting Help

For issues related to:
- **Monica API**: Check [Monica documentation](https://docs.monicahq.com)
- **iOS App**: Create an issue in this repository
- **Monica Instance**: Visit [Monica support](https://github.com/monicahq/monica/discussions)

## License

This project follows the same license as Monica Personal CRM.

---

**Monica iOS Client MVP** - Built with ❤️ for privacy-conscious personal relationship management.