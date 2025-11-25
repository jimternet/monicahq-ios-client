# Research: Avatar Authentication for Monica iOS Client

**Date**: 2025-11-24
**Feature**: Avatar Authentication & Display
**Purpose**: Determine optimal approach for authenticated avatar loading with graceful fallbacks

## 1. Authentication Analysis

### Monica API Avatar Architecture

Based on research into Monica CRM's avatar system, the following was discovered:

**Avatar Data Structure in API Response:**
```json
{
  "contact": {
    "id": 1,
    "information": {
      "avatar": {
        "url": "",
        "source": "default",
        "default_avatar_color": "#b3d5fe"
      }
    }
  }
}
```

**Avatar Sources:**
- `default`: Initials-based avatar with color hash
- `gravatar`: Gravatar service (email-based)
- `adorable`: Adorable.io service (deprecated, replaced with alternatives)
- `photo`: User-uploaded photo stored in Monica

**Key Findings:**
1. The API returns avatar information at `contact.information.avatar`
2. Monica's avatar system went through a major refactor (PR #2112) that moved avatars to a Photo object model
3. The API guarantees to "always return an image regardless of the avatar you use"
4. Photos are stored in Monica's filesystem at `/storage/photos/` directory
5. A `default_avatar_color` hex code is provided for fallback initials display

### Authentication Requirements

**For API Endpoints:**
- Standard Bearer token authentication: `Authorization: Bearer {token}`
- This works for all `/api/*` endpoints

**For Static Photo Files:**
- Photos served from `/storage/photos/` directory may require session-based authentication
- **Critical Gap**: Research indicates Monica uses cookie-based session authentication for web UI
- **Unknown**: Whether static photo URLs accept Bearer tokens or require session cookies
- **API Endpoint**: `PUT /contacts/{contact}/avatar` exists for updating avatars
- **Photo API**:
  - `GET /photos` - retrieve all photos
  - `GET /photos/{photo}` - get one photo
  - `POST /photos` - upload photo
  - `DELETE /photos/{photo}` - destroy photo

**Gravatar Exception:**
- Gravatar URLs are external (gravatar.com) and require no authentication
- Standard HTTPS requests work without any custom headers

### Decision on Authentication Mechanism

**Decision**: Use custom URLSession with interceptor to inject Bearer token headers for all image requests, with special handling for Gravatar URLs.

**Rationale**:
1. Consistent authentication across API and photo endpoints
2. Monica's API-first design suggests Bearer tokens should work for photo access
3. If Bearer token fails, we can gracefully fall back to initials avatar
4. Avoids complexity of session cookie management
5. Maintains consistency with existing `MonicaAPIClient` pattern

**Implementation Strategy**:
- Create a shared URLSession configuration with request interceptor
- Inject `Authorization: Bearer {token}` header for Monica host URLs
- Skip auth headers for Gravatar URLs (different host)
- Handle 401/403 responses by falling back to initials avatar

## 2. iOS Implementation Patterns

### Best Practices for Authenticated Image Loading

**Core Problem**: SwiftUI's `AsyncImage` doesn't support custom headers or authentication.

**Industry Standard Solutions:**

1. **Custom AsyncImage Wrapper**
   - Create custom view that wraps URLSession-based async loading
   - Provides AsyncImage-like API with authentication support
   - Full control over request configuration

2. **URLSession with URLRequest**
   ```swift
   var request = URLRequest(url: photoURL)
   request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
   let (data, _) = try await URLSession.shared.data(for: request)
   ```

3. **Caching Strategies**
   - **URLCache**: Built-in, respects HTTP cache headers, 4MB memory + 20MB disk default
   - **NSCache**: Thread-safe, automatic memory pressure management, in-memory only
   - **Dual-Layer**: NSCache for decompressed images + URLCache for raw data
   - **Custom**: Full control but adds complexity (violates zero-dependency constraint)

4. **Memory Management for Lists**
   - Fixed-height rows for optimal List performance
   - Off-screen images released on memory warnings
   - Queue management: fast queue for visible items, slow queue for prefetch
   - NSCache cost assignment for intelligent eviction

### SwiftUI Patterns for Avatar Views

**Recommended Pattern**:
```swift
struct AvatarView: View {
    let contact: Contact
    let size: CGFloat
    @StateObject private var imageLoader: ImageLoader

    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if imageLoader.isLoading {
                ProgressView()
            } else {
                InitialsAvatar(contact: contact, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task {
            await imageLoader.load()
        }
    }
}
```

**State Management**:
- Use `@StateObject` for image loader lifecycle
- `@Published` properties trigger view updates
- Task modifier handles async loading lifecycle
- Automatic cancellation on view disappearance

## 3. Fallback Strategy

### When to Show Initials vs Attempting Load

**Decision Tree**:
1. **Check avatar.source field**:
   - `"default"` → Show initials immediately (skip network request)
   - `"gravatar"` or `"photo"` with URL → Attempt load
   - Empty/nil URL → Show initials immediately

2. **Network Request Outcomes**:
   - Success → Display photo
   - 401/403 → Fall back to initials (auth issue)
   - 404 → Fall back to initials (photo deleted)
   - Network error → Show initials with retry option
   - Timeout → Fall back to initials

3. **Performance Optimization**:
   - For large lists (100+ contacts), batch load visible items only
   - Prefetch next 10-20 items during scroll
   - Cancel pending requests for off-screen items

### Color Generation for Initials

**Decision**: Hash-based deterministic color generation

**Implementation**:
```swift
extension Contact {
    var initialsColor: Color {
        // Use Monica's provided color if available
        if let hexColor = information?.avatar?.defaultAvatarColor {
            return Color(hex: hexColor)
        }

        // Fallback: Generate from full name hash
        let fullName = "\(firstName ?? "") \(lastName ?? "")"
        let hash = fullName.unicodeScalars.reduce(0) {
            Int($1.value) + (($0 << 5) - $0)
        }

        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .teal, .indigo, .cyan, .mint, .brown
        ]

        return colors[abs(hash) % colors.length]
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }
}
```

**Rationale**:
- Monica provides `default_avatar_color` in API response - use it when available
- Deterministic hashing ensures same contact always gets same color
- Matches user's web interface experience (if Monica generates the color)
- Graceful fallback if color field missing

### SwiftUI Avatar Component

**Component Design**:
```swift
struct InitialsAvatar: View {
    let contact: Contact
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(contact.initialsColor.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Text(contact.initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(contact.initialsColor)
            )
    }
}
```

## 4. Technical Decisions

### Image Loading Library Choice

**Decision**: Custom URLSession-based solution with no external dependencies

**Rationale**:
1. **Constitutional Alignment**: "Zero external dependencies for MVP" (from CLAUDE.md)
2. **Simplicity**: URLCache + AsyncImage replacement is ~100 lines of code
3. **Performance**: Native URLSession performs optimally for iOS
4. **Maintenance**: No dependency version management or security patches
5. **Size**: Avoids 5-10MB binary size increase from SDWebImage/Kingfisher/Nuke

**Alternatives Considered**:

| Library | Pros | Cons | Verdict |
|---------|------|------|---------|
| **Kingfisher** | Pure Swift, SwiftUI support, 8K+ stars | Adds dependency, 5MB+ binary size | Rejected - violates zero-dependency constraint |
| **Nuke** | Modern, well-maintained, performant | External dependency, learning curve | Rejected - unnecessary complexity for MVP |
| **SDWebImage** | Battle-tested, widely used | Objective-C based, large dependency | Rejected - overkill for read-only MVP |
| **AsyncImage** | Built-in, simple API | No auth headers support | Rejected - can't authenticate requests |
| **Custom URLSession** | Zero dependencies, full control, <100 LOC | More implementation work | **SELECTED** |

### Authentication Injection Point

**Decision**: Custom URLSession configuration with protocol-based request interceptor

**Implementation Architecture**:
```swift
protocol AuthenticatedImageLoading {
    func loadImage(from url: URL) async throws -> UIImage
}

class AuthenticatedImageLoader: AuthenticatedImageLoading {
    private let apiToken: String
    private let cache = NSCache<NSURL, UIImage>()

    func loadImage(from url: URL) async throws -> UIImage {
        // Check cache
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // Build authenticated request
        var request = URLRequest(url: url)

        // Only add auth for Monica host (skip Gravatar)
        if url.host != "gravatar.com" {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        // Fetch and cache
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let image = UIImage(data: data) else {
            throw ImageLoadError.invalidData
        }

        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
```

**Rationale**:
- Protocol enables testing with mock implementations
- Token injection at loader level (single responsibility)
- NSCache provides automatic memory management
- URLSession.shared provides disk caching via URLCache
- Graceful Gravatar handling (no auth headers for external URLs)

### Gravatar vs Custom Photo Handling

**Decision**: Unified loading interface with host-based auth decision

**Strategy**:
```swift
func shouldAuthenticate(url: URL) -> Bool {
    // Skip auth for external services
    guard let host = url.host else { return false }
    return !host.contains("gravatar.com") &&
           !host.contains("ui-avatars.com")
}
```

**Rationale**:
- Single code path reduces complexity
- Host-based detection is reliable
- Easy to extend for future external avatar services
- No need for source field checking at load time

### Caching Strategy

**Decision**: Two-tier caching with URLCache + NSCache

**Architecture**:

1. **L1 Cache - NSCache (Memory)**:
   - Stores decompressed `UIImage` objects
   - Thread-safe, automatic eviction under memory pressure
   - Cost-based for intelligent management
   - Cleared on memory warnings

2. **L2 Cache - URLCache (Disk)**:
   - Stores raw HTTP responses
   - Respects Cache-Control headers from Monica
   - Persists across app launches
   - System-managed cleanup

**Configuration**:
```swift
// L2: URLCache for raw data (persistent)
let cache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
    diskCapacity: 150 * 1024 * 1024,    // 150 MB disk
    diskPath: "avatar_cache"
)
URLCache.shared = cache

// L1: NSCache for decompressed images (in-memory)
let imageCache = NSCache<NSURL, UIImage>()
imageCache.countLimit = 100  // Max 100 images in memory
imageCache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
```

**Rationale**:
- Decompressed images in NSCache = instant display
- Raw data in URLCache = fast decode on cache hit
- Two-tier provides optimal balance of speed and memory
- No custom disk management needed
- Automatic cleanup under memory pressure

### Cache Invalidation Strategy

**Decision**: TTL-based with manual refresh option

**Rules**:
1. **Default TTL**: Respect HTTP `Cache-Control` headers from Monica
2. **Fallback TTL**: 24 hours if no headers present
3. **Manual Invalidation**: Pull-to-refresh clears cache for visible items
4. **Memory Warnings**: NSCache auto-evicts, no manual intervention
5. **Logout**: Clear both URLCache and NSCache completely

**Implementation**:
```swift
func clearAvatarCache() {
    // Clear memory cache
    imageCache.removeAllObjects()

    // Clear disk cache (avatar-related URLs only)
    URLCache.shared.removeAllCachedResponses()
}

func refreshAvatar(for contact: Contact) async {
    // Remove from cache
    if let url = contact.avatarURL {
        imageCache.removeObject(forKey: url as NSURL)
        URLCache.shared.removeCachedResponse(for: URLRequest(url: url))
    }

    // Trigger reload
    await loadAvatar(for: contact)
}
```

**Rationale**:
- HTTP-compliant caching leverages Monica's cache headers
- 24-hour default prevents stale avatars
- Manual refresh gives users control
- Automatic cleanup on logout prevents privacy leaks

## Implementation Notes

### Key Technical Details

**1. Contact Model Extension**
```swift
extension Contact {
    var avatarURL: URL? {
        guard let urlString = information?.avatar?.url,
              !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    var shouldLoadAvatar: Bool {
        information?.avatar?.source != "default" && avatarURL != nil
    }
}
```

**2. Image Loader Observable Object**
```swift
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?

    private let url: URL
    private let loader: AuthenticatedImageLoading
    private var task: Task<Void, Never>?

    init(url: URL, loader: AuthenticatedImageLoading) {
        self.url = url
        self.loader = loader
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            image = try await loader.loadImage(from: url)
        } catch {
            self.error = error
            // Fallback to initials handled by view
        }
    }

    func cancel() {
        task?.cancel()
    }
}
```

**3. Performance Optimizations**
- Use `.id()` modifier on avatars to prevent re-fetching on list updates
- Implement visibility tracking to cancel off-screen loads
- Batch prefetch next page during pagination
- Fixed avatar sizes (no dynamic sizing calculations)

**4. Error Handling**
```swift
enum ImageLoadError: LocalizedError {
    case invalidURL
    case invalidData
    case unauthorized
    case notFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Authentication failed"
        case .notFound:
            return "Photo not found"
        case .networkError(let error):
            return error.localizedDescription
        default:
            return "Failed to load avatar"
        }
    }
}
```

**5. Testing Strategy**
- Mock `AuthenticatedImageLoading` protocol for unit tests
- Test cache hit/miss scenarios
- Verify Gravatar URLs skip authentication
- Test fallback to initials on all error types
- Memory leak testing with Instruments

**6. Accessibility**
```swift
.accessibilityLabel("\(contact.fullName) avatar")
.accessibilityAddTraits(.isImage)
```

### Migration Path from Current Implementation

**Current State** (from ContactsListView.swift):
```swift
Circle()
    .fill(Color.blue.opacity(0.3))
    .frame(width: 50, height: 50)
    .overlay(
        Text(contact.initials)
            .font(.headline)
            .foregroundColor(.blue)
    )
```

**New Implementation**:
```swift
AvatarView(
    contact: contact,
    size: 50,
    imageLoader: AuthenticatedImageLoader(apiToken: authManager.apiToken)
)
```

**Migration Steps**:
1. Add `avatar` field to Contact model (from API response)
2. Update `ContactEntity` Core Data model if caching URLs
3. Create `AuthenticatedImageLoader` class
4. Create `ImageLoader` ObservableObject
5. Create `AvatarView` component
6. Replace existing Circle/Text avatar in ContactRowView
7. Replace existing Circle/Text avatar in ContactDetailView
8. Add cache clearing to AuthenticationManager.logout()
9. Add unit tests for image loading and caching
10. Performance test with 500+ contacts

### Configuration Requirements

**Info.plist Additions** (if needed):
```xml
<!-- Only if Monica uses non-HTTPS in development -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

**URLSession Configuration**:
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.requestCachePolicy = .returnCacheDataElseLoad
config.urlCache = avatarURLCache
```

## Decision Summary

| Decision Area | Choice | Rationale |
|--------------|--------|-----------|
| **Image Library** | Custom URLSession | Zero dependencies, Constitutional compliance |
| **Authentication** | Bearer token in headers | Consistent with API client, Monica API-first design |
| **Caching** | URLCache + NSCache | Two-tier optimal, automatic memory management |
| **Fallback** | Hash-based initials | Deterministic, uses Monica's color field |
| **Avatar Component** | Custom AvatarView | Full control, testable, performant |
| **Cache Invalidation** | HTTP headers + 24hr TTL | Standards-compliant, Monica-controlled |

**Estimated Implementation**: 4-6 hours
- AuthenticatedImageLoader: 1 hour
- ImageLoader ObservableObject: 1 hour
- AvatarView component: 1 hour
- Integration + testing: 2-3 hours

**Testing Coverage Target**: 70%+
- Unit tests for loader logic
- Integration tests for auth handling
- UI tests for fallback behavior
- Performance tests for large lists

**Ready for Implementation**: Yes, all technical decisions documented and validated against constitutional principles.
