# Monica iOS Client - Architecture Documentation

**Version**: 1.0.0
**Last Updated**: 2025-11-20
**Status**: Production Ready (MVP Complete)

## Table of Contents

1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Layer Breakdown](#layer-breakdown)
4. [Data Flow](#data-flow)
5. [Key Design Decisions](#key-design-decisions)
6. [Security Architecture](#security-architecture)
7. [Performance Strategy](#performance-strategy)
8. [Testing Strategy](#testing-strategy)
9. [Future Enhancements](#future-enhancements)

---

## Overview

The Monica iOS Client is a native iOS application built with SwiftUI that provides a read-only interface to Monica CRM instances (cloud or self-hosted). The architecture prioritizes **simplicity**, **privacy**, and **native iOS experience** while maintaining extensibility for future write operations.

### Core Principles

- **Zero External Dependencies**: Uses only Apple's native frameworks
- **Read-Only MVP**: All operations are GET requests (v1.0)
- **Privacy-First**: Keychain storage, HTTPS-only, no analytics on PII
- **MVVM Pattern**: Clear separation of concerns for testability
- **iOS 15+ Target**: Leverages modern Swift concurrency (async/await)

---

## Architecture Pattern

### MVVM (Model-View-ViewModel)

```text
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ContactList  │  │ContactDetail │  │   Settings   │     │
│  │     View     │  │     View     │  │     View     │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                   │                  │             │
│         └───────────────────┴──────────────────┘             │
│                             │                                 │
└─────────────────────────────┼─────────────────────────────────┘
                              │ @Published / @StateObject
┌─────────────────────────────┼─────────────────────────────────┐
│                     ViewModels (@MainActor)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ ContactList  │  │ContactDetail │  │   Settings   │      │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                   │                  │              │
│         └───────────────────┴──────────────────┘              │
│                             │                                  │
└─────────────────────────────┼──────────────────────────────────┘
                              │ async/await calls
┌─────────────────────────────┼──────────────────────────────────┐
│                          Services                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  API Client  │  │   Keychain   │  │Cache Service │       │
│  │   Service    │  │   Service    │  │              │       │
│  └──────┬───────┘  └──────────────┘  └──────────────┘       │
│         │                                                      │
└─────────┼──────────────────────────────────────────────────────┘
          │ HTTPS (URLSession)
┌─────────┼──────────────────────────────────────────────────────┐
│  Monica API v4.x (monicahq.com or self-hosted)                │
└─────────────────────────────────────────────────────────────────┘
```

**Key Benefits**:
- **Testability**: ViewModels can be unit tested without UI
- **Separation**: Views are declarative, logic lives in ViewModels
- **Reactivity**: @Published properties drive UI updates automatically
- **Concurrency**: @MainActor ensures UI updates on main thread

---

## Layer Breakdown

### 1. Models Layer

**Location**: `MonicaClient/Models/`

**Purpose**: Data structures representing API responses and domain entities

**Files**:
- `Contact.swift` - Core contact entity with computed properties (displayName, initials)
- `Activity.swift` - Interaction events with contacts
- `Note.swift` - Free-form text content
- `Task.swift` - Todo items with completion status
- `Gift.swift` - Gift ideas and given gifts
- `Tag.swift` - Contact categorization labels
- `Relationship.swift` - Contact-to-contact relationships
- `APIResponse.swift` - Generic wrapper for all API responses
- `PaginationMeta.swift` - Pagination metadata
- `PaginationLinks.swift` - Pagination navigation links

**Characteristics**:
- All models conform to `Codable` for JSON serialization
- Entity models conform to `Identifiable` for SwiftUI List compatibility
- Computed properties for display logic (e.g., `displayName`, `initials`)
- No business logic - pure data structures

**Example**:
```swift
struct Contact: Codable, Identifiable {
    let id: Int
    let first_name: String
    let last_name: String?
    let nickname: String?

    var displayName: String {
        if let lastName = last_name {
            return "\(first_name) \(lastName)"
        }
        return first_name
    }
}
```

---

### 2. Services Layer

**Location**: `MonicaClient/Services/`

**Purpose**: Business logic, API communication, and data persistence

#### API Service (`Services/API/`)

- **MonicaAPIClient.swift**: Implements `MonicaAPIClientProtocol`
  - `listContacts(page:limit:query:)` - Paginated contact fetching
  - `getContact(id:)` - Detailed contact retrieval
  - `listActivities(contactId:page:limit:)` - Activity timeline
  - `listNotes(contactId:...)` - Contact notes
  - `listTasks(contactId:...)` - Contact tasks
  - `listGifts(contactId:...)` - Gift ideas/given
  - `listTags()` - All available tags
  - `validateToken()` - Authentication verification

- **APIError.swift**: Error handling with `LocalizedError`
  - `invalidToken` - 401 Unauthorized
  - `networkUnavailable` - Network failures
  - `serverError(Int)` - 5xx errors
  - `rateLimitExceeded` - 429 Too Many Requests
  - User-friendly error messages for all cases

#### Storage Services (`Services/Storage/`)

- **KeychainService.swift**: Secure credential storage
  - `save(token:endpoint:)` - Store API credentials
  - `retrieve()` - Fetch stored credentials
  - `delete()` - Clear credentials on logout
  - Uses iOS Keychain for encryption

- **UserDefaultsService.swift**: Non-sensitive settings
  - App preferences (theme, sort order, etc.)
  - Last sync timestamp
  - User preferences

- **CacheService.swift**: In-memory contact caching
  - 5-minute TTL for contact list
  - LRU eviction for memory pressure
  - Pull-to-refresh invalidates cache

#### Network Monitoring

- **NetworkMonitor.swift**: Connectivity awareness
  - Uses `Network.framework` for reachability
  - Provides offline graceful degradation
  - Alerts before API calls when offline

---

### 3. ViewModels Layer

**Location**: `MonicaClient/Features/*/ViewModels/`

**Purpose**: Presentation logic, state management, and API coordination

**Characteristics**:
- All ViewModels are `@MainActor` for thread safety
- Conform to `ObservableObject`
- Use `@Published` for reactive state
- Dependency injection for testability

**Key ViewModels**:

#### AuthViewModel
- Manages authentication flow
- Validates API tokens
- Stores credentials in Keychain
- Handles cloud vs self-hosted selection

#### ContactListViewModel
- Fetches paginated contact list
- Implements search with 300ms debounce
- Manages pull-to-refresh state
- Handles infinite scroll/load more

#### ContactDetailViewModel
- Loads comprehensive contact data
- Lazy-loads activities, notes, tasks
- Manages collapsible sections
- Handles related contact navigation

#### SettingsViewModel
- Manages app configuration
- Implements logout with credential cleanup
- Cache management (display size, clear)
- Instance switching

**Example**:
```swift
@MainActor
class ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: MonicaAPIClientProtocol

    func loadContacts() async {
        isLoading = true
        do {
            let response = try await apiClient.listContacts()
            contacts = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

---

### 4. Views Layer

**Location**: `MonicaClient/Features/*/Views/`

**Purpose**: SwiftUI declarative UI components

**Characteristics**:
- Pure SwiftUI (no UIKit)
- Minimal business logic
- Observe ViewModels via `@StateObject` or `@ObservedObject`
- Reusable components in `Components/`

**View Structure**:

#### Authentication Flow
- `OnboardingView` - Cloud vs self-hosted selection
- `LoginView` - Endpoint and token input
- Auto-login on app launch if credentials exist

#### Contact List
- `ContactListView` - Main contact browsing interface
  - `List` with SwiftUI native components
  - `.searchable()` modifier for search
  - `.refreshable()` for pull-to-refresh
- `ContactRowView` - Individual contact row
  - Avatar placeholder (initials)
  - Display name and nickname
  - Visual indicators (partial contact, deceased)

#### Contact Detail
- `ContactDetailView` - Comprehensive contact information
  - Collapsible sections for activities, notes, tasks
  - Tappable email/phone for system integration
  - Related contact navigation
- `ActivitySection`, `NotesSection`, `TasksSection` - Feature-specific components

#### Settings
- `SettingsView` - App configuration interface
  - Current instance info
  - Logout and instance switching
  - Cache management

#### Reusable Components
- `LoadingView` - Consistent loading indicator
- `ErrorView` - Error display with retry
- `EmptyStateView` - "No data" messaging

---

## Data Flow

### 1. Authentication Flow

```text
User Interaction → LoginView
                    ↓
        AuthViewModel.login(endpoint, token)
                    ↓
        MonicaAPIClient.validateToken()
                    ↓
        Monica API (GET /contacts?limit=1)
                    ↓
        ← 200 OK (valid) or 401 (invalid)
                    ↓
        KeychainService.save(token, endpoint)
                    ↓
        Navigate to ContactListView
```

### 2. Contact Browsing Flow

```text
ContactListView.onAppear
        ↓
ContactListViewModel.loadContacts()
        ↓
MonicaAPIClient.listContacts(page: 1, limit: 50)
        ↓
Monica API (GET /contacts?page=1&limit=50)
        ↓
APIResponse<[Contact]> with pagination meta
        ↓
CacheService.store(contacts) [5-min TTL]
        ↓
ContactListViewModel.contacts = response.data
        ↓
SwiftUI updates List automatically
```

### 3. Search Flow

```text
User types in search bar
        ↓
SwiftUI .searchable(text: $searchText)
        ↓
300ms debounce (Task.sleep)
        ↓
ContactListViewModel.search(query)
        ↓
MonicaAPIClient.listContacts(query: "john")
        ↓
Monica API (GET /contacts?query=john)
        ↓
Filtered results displayed
```

### 4. Error Handling Flow

```text
API call fails
        ↓
Throw MonicaAPIError
        ↓
Catch in ViewModel
        ↓
Set errorMessage (Published property)
        ↓
SwiftUI .alert() displays user-friendly message
        ↓
User taps retry → Re-execute API call
```

### 5. Logout Flow

```text
User taps "Log Out" in Settings
        ↓
SettingsViewModel.logout()
        ↓
KeychainService.delete()
        ↓
CacheService.clear()
        ↓
UserDefaultsService.clearAll()
        ↓
Navigate back to OnboardingView
```

---

## Key Design Decisions

### 1. Zero External Dependencies

**Decision**: Use only Apple native frameworks (SwiftUI, URLSession, Keychain)

**Rationale**:
- Constitutional principle (simplicity)
- Reduces dependency management overhead
- Faster compilation and app size
- No version conflicts or security vulnerabilities from third parties
- URLSession is sufficient for REST API calls

**Alternatives Considered**:
- Alamofire for networking → Rejected (unnecessary complexity)
- Realm/CoreData for persistence → Rejected (in-memory sufficient for MVP)

---

### 2. MVVM Architecture

**Decision**: Adopt MVVM pattern with @MainActor ViewModels

**Rationale**:
- Natural fit for SwiftUI's declarative nature
- High testability (ViewModels can be unit tested)
- Clear separation of concerns
- @MainActor ensures thread-safe UI updates

**Alternatives Considered**:
- Redux/TCA → Rejected (over-engineering for read-only MVP)
- MVC → Rejected (massive view controllers, hard to test)

---

### 3. Read-Only Operations

**Decision**: MVP limited to GET requests only

**Rationale**:
- Reduces complexity and security surface
- Faster time to market
- Architecture designed for write operations in v2+
- Still delivers core value (viewing contacts)

**Migration Path**:
- API layer already has protocol-based design
- Adding POST/PUT/DELETE methods requires minimal changes
- ViewModels already use Result types for error handling

---

### 4. In-Memory Caching

**Decision**: Use in-memory cache with 5-minute TTL instead of CoreData/SQLite

**Rationale**:
- Simpler implementation
- No schema migrations
- Reduced data exposure risk (no local database)
- Sufficient for MVP use case

**Limitations**:
- No offline-first capability (deferred to v2+)
- Cache lost on app termination

**Mitigation**:
- Pull-to-refresh for manual updates
- Automatic reload on app foreground

---

### 5. Search Debouncing (300ms)

**Decision**: Implement 300ms debounce before search API calls

**Rationale**:
- Reduces API load (fewer requests while typing)
- Meets <500ms response requirement
- Better UX (doesn't feel laggy)

**Implementation**:
```swift
.task(id: searchText) {
    try? await Task.sleep(nanoseconds: 300_000_000)
    await viewModel.search(query: searchText)
}
```

---

### 6. Pagination Strategy

**Decision**: 50 contacts per page with "Load More" button

**Rationale**:
- Balances performance and UX
- "Load More" gives user control vs infinite scroll
- Supports 10,000+ contacts without memory issues

**API Integration**:
- Uses `page` and `limit` query parameters
- Respects pagination metadata from API
- Handles missing pagination gracefully

---

## Security Architecture

### 1. Credential Storage

**Keychain Implementation**:
```swift
class KeychainService {
    func save(token: String, endpoint: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "monicaAPIToken",
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}
```

**Security Features**:
- **Encrypted at rest**: iOS encrypts Keychain data
- **Isolated per app**: Other apps cannot access
- **kSecAttrAccessibleAfterFirstUnlock**: Available after first device unlock
- **No UserDefaults**: Tokens NEVER stored in plain text

---

### 2. HTTPS Enforcement

**Configuration**:
- All API calls use HTTPS exclusively
- URLSession enforces certificate validation
- Self-signed certificates rejected (security over convenience)

**Info.plist** (if needed for self-hosted):
```xml
<!-- Only for development/trusted self-hosted instances -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-monica.domain.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

### 3. API Token Validation

**Validation Strategy**:
- Token validated before storing in Keychain
- Auto-logout on 401 Unauthorized responses
- Tokens never logged or exposed in debug output

**Validation Endpoint**:
```swift
func validateToken() async throws -> Bool {
    let response = try await apiClient.listContacts(limit: 1)
    return response != nil
}
```

---

### 4. PII Protection

**Privacy Measures**:
- No analytics on contact data
- Logging redacts sensitive information
- Network requests use Bearer token header (not query param)
- Cache cleared on logout

---

## Performance Strategy

### 1. App Launch (<2 seconds target)

**Optimizations**:
- Lazy initialization of ViewModels
- Minimal work in `@main` app entry point
- Keychain check happens asynchronously
- No heavy computations on main thread

**Measurement**:
- Use Xcode Instruments → Time Profiler
- Target: Cold launch < 2s on iPhone 12

---

### 2. Contact List Scrolling (60fps target)

**Optimizations**:
- **Fixed row heights**: Eliminates dynamic height calculations
```swift
.frame(height: 70) // ContactRowView
```
- **LazyVStack**: Only renders visible rows
- **Minimal view hierarchy**: Flat structure
- **No async image loading**: Uses initials placeholder

**Validation**:
- Xcode Instruments → Core Animation
- Test with 500+ contacts
- Maintain 60fps during fast scrolling

---

### 3. Search Performance (<500ms target)

**Optimizations**:
- 300ms debounce reduces API calls
- Search caching avoids duplicate requests
- Results displayed immediately on cache hit

**Example**:
```swift
// Debounced search
.task(id: searchText) {
    try? await Task.sleep(nanoseconds: 300_000_000)
    await viewModel.search(query: searchText)
}
```

---

### 4. Memory Management

**Strategies**:
- In-memory cache with LRU eviction
- Pagination limits loaded contacts
- No image caching (initials-only MVP)
- Automatic cache clearing on memory pressure

**Monitoring**:
- Xcode Memory Graph Debugger
- Target: < 100MB for 1000 contacts

---

### 5. Network Optimization

**Strategies**:
- Request deduplication (5-second cache)
- Exponential backoff for retries
- 10-second timeout prevents hanging
- Connection reuse via URLSession

**Retry Logic**:
```swift
for attempt in 1...3 {
    let delay = pow(2.0, Double(attempt - 1))
    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    // Retry API call
}
```

---

## Testing Strategy

### 1. Unit Testing (70% coverage target)

**Focus Areas**:
- **ViewModels**: Business logic, state changes, error handling
- **Services**: API client, Keychain, Cache operations
- **Models**: Computed properties, validation

**Example Test**:
```swift
func testContactListLoadSuccess() async {
    let mockClient = MockMonicaAPIClient()
    mockClient.mockContacts = [Contact.fixture()]

    let viewModel = ContactListViewModel(apiClient: mockClient)
    await viewModel.loadContacts()

    XCTAssertEqual(viewModel.contacts.count, 1)
    XCTAssertFalse(viewModel.isLoading)
}
```

---

### 2. Integration Testing

**Focus Areas**:
- API contract validation
- Keychain integration
- End-to-end authentication flow

**Tools**:
- XCTest for all tests
- MockMonicaAPIClient for API simulation
- Test doubles for all external dependencies

---

### 3. Manual Testing

**Critical Paths**:
1. Authentication (cloud + self-hosted)
2. Contact browsing (pagination, refresh)
3. Search functionality
4. Contact detail navigation
5. Settings (logout, cache clear)
6. Error scenarios (network off, invalid token)

**Test Devices**:
- iPhone 12 (minimum target)
- iPhone 15 Pro (latest)
- iOS 15.0 (minimum OS)
- iOS 17+ (latest)

---

### 4. Performance Testing

**Scenarios**:
- 10,000+ contacts in list
- Rapid scrolling
- Search with large result sets
- Memory usage over extended session

**Tools**:
- Xcode Instruments (Time Profiler, Core Animation, Allocations)
- Network Link Conditioner (slow network testing)

---

## Future Enhancements

### v2.0 Roadmap

1. **Write Operations**
   - Create/edit/delete contacts
   - Add/update notes, tasks, activities
   - Relationship management

2. **Offline-First Architecture**
   - CoreData persistence
   - Sync conflict resolution
   - Background sync

3. **Advanced Features**
   - Contact photos/avatars
   - Rich text notes (markdown)
   - Advanced filtering and sorting
   - Share sheet integration

4. **Platform Expansion**
   - iPad optimization
   - macOS Catalyst support
   - watchOS companion app

5. **Real-Time Updates**
   - WebSocket integration
   - Push notifications
   - Live activity updates

---

## Appendix: File Structure

```text
MonicaClient/
├── MonicaClientApp.swift          # App entry point
├── ContentView.swift               # Root view coordinator
├── Models/
│   ├── Contact.swift
│   ├── Activity.swift
│   ├── Note.swift
│   ├── Task.swift
│   ├── Gift.swift
│   ├── Tag.swift
│   ├── Relationship.swift
│   └── APIResponse.swift
├── Services/
│   ├── API/
│   │   ├── MonicaAPIClient.swift
│   │   └── APIError.swift
│   ├── Storage/
│   │   ├── KeychainService.swift
│   │   ├── UserDefaultsService.swift
│   │   └── CacheService.swift
│   └── NetworkMonitor.swift
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── OnboardingView.swift
│   │   │   └── LoginView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Models/
│   │       └── AuthCredentials.swift
│   ├── ContactList/
│   │   ├── Views/
│   │   │   ├── ContactListView.swift
│   │   │   └── ContactRowView.swift
│   │   └── ViewModels/
│   │       └── ContactListViewModel.swift
│   ├── ContactDetail/
│   │   ├── Views/
│   │   │   ├── ContactDetailView.swift
│   │   │   ├── ActivitySection.swift
│   │   │   ├── NotesSection.swift
│   │   │   └── TasksSection.swift
│   │   └── ViewModels/
│   │       └── ContactDetailViewModel.swift
│   └── Settings/
│       ├── Views/
│       │   └── SettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
├── Utilities/
│   ├── Constants.swift
│   ├── Extensions.swift
│   └── DateFormatting.swift
└── Components/
    ├── LoadingView.swift
    ├── ErrorView.swift
    └── EmptyStateView.swift

MonicaClientTests/
├── ViewModelTests/
│   ├── AuthViewModelTests.swift
│   ├── ContactListViewModelTests.swift
│   └── ContactDetailViewModelTests.swift
├── ServiceTests/
│   ├── APIServiceTests.swift
│   ├── AuthServiceTests.swift
│   └── KeychainServiceTests.swift
└── Mocks/
    ├── MockAPIService.swift
    └── MockKeychainService.swift
```

---

## Conclusion

The Monica iOS Client architecture demonstrates how **simplicity**, **security**, and **native iOS conventions** can deliver a high-quality user experience without unnecessary complexity. The MVVM pattern, combined with SwiftUI's declarative approach and Swift's modern concurrency features, provides a solid foundation for both the current MVP and future enhancements.

**Key Takeaways**:
- Zero external dependencies reduce complexity and security surface
- MVVM enables comprehensive testing without UI dependencies
- In-memory caching balances performance and simplicity
- Protocol-based design allows easy extension for write operations
- Constitutional alignment ensures architectural integrity

For questions or contributions, see [README.md](../README.md) and the project constitution at `.specify/memory/constitution.md`.
