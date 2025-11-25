# Data Model: Avatar Authentication

**Feature**: Avatar Authentication & Display
**Date**: 2025-11-24
**Status**: Design

## Overview

This document defines the data structures for authenticated avatar loading, caching, and display in the Monica iOS Client. The models support both network-loaded avatars (Gravatar, custom photos) and locally-generated initials avatars with graceful fallbacks.

## Core Data Structures

### 1. Avatar Information Model

Represents avatar metadata from Monica API responses.

```swift
/// Avatar information from Monica API
struct AvatarInfo: Codable, Equatable {
    /// URL to avatar image (may be empty for default avatars)
    let url: String

    /// Source of avatar: "default", "gravatar", "photo", "adorable"
    let source: String

    /// Hex color code for initials avatar background (e.g., "#b3d5fe")
    let defaultAvatarColor: String?

    enum CodingKeys: String, CodingKey {
        case url
        case source
        case defaultAvatarColor = "default_avatar_color"
    }
}

/// Avatar source types
enum AvatarSource: String {
    case `default`  // Initials-based avatar
    case gravatar   // Gravatar service
    case photo      // User-uploaded photo
    case adorable   // Adorable.io (deprecated)

    var requiresAuthentication: Bool {
        switch self {
        case .photo:
            return true
        case .gravatar, .default, .adorable:
            return false
        }
    }
}
```

### 2. Contact Model Extension

Extends the Contact model with avatar-related computed properties.

```swift
extension Contact {
    /// Parsed avatar URL (nil if empty or invalid)
    var avatarURL: URL? {
        guard let urlString = information?.avatar?.url,
              !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    /// Whether avatar should be loaded from network
    var shouldLoadAvatar: Bool {
        information?.avatar?.source != "default" && avatarURL != nil
    }

    /// Initials for fallback display (e.g., "JD" for John Doe)
    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }

    /// Color for initials avatar (from API or hash-based fallback)
    var initialsColor: Color {
        // Prefer Monica's provided color
        if let hexColor = information?.avatar?.defaultAvatarColor {
            return Color(hex: hexColor)
        }

        // Fallback: Generate deterministic color from name
        return generateColorFromName()
    }

    /// Generates deterministic color from contact name
    private func generateColorFromName() -> Color {
        let fullName = "\(firstName ?? "") \(lastName ?? "")"
        let hash = fullName.unicodeScalars.reduce(0) {
            Int($1.value) + (($0 << 5) - $0)
        }

        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .teal, .indigo, .cyan, .mint, .brown
        ]

        return colors[abs(hash) % colors.count]
    }
}
```

### 3. Image Loading State

Represents the current state of an avatar image load operation.

```swift
/// State of avatar image loading
enum ImageLoadState: Equatable {
    case idle
    case loading
    case loaded(UIImage)
    case failed(ImageLoadError)

    var image: UIImage? {
        if case .loaded(let image) = self {
            return image
        }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var error: ImageLoadError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

/// Errors that can occur during image loading
enum ImageLoadError: LocalizedError, Equatable {
    case invalidURL
    case invalidData
    case unauthorized
    case notFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid avatar URL"
        case .invalidData:
            return "Invalid image data"
        case .unauthorized:
            return "Authentication failed"
        case .notFound:
            return "Photo not found"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    static func == (lhs: ImageLoadError, rhs: ImageLoadError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidData, .invalidData),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound):
            return true
        case (.networkError(let l), .networkError(let r)):
            return l == r
        default:
            return false
        }
    }
}
```

### 4. Image Loader Observable Object

ObservableObject for managing asynchronous image loading in SwiftUI views.

```swift
/// Observable image loader for SwiftUI views
@MainActor
class ImageLoader: ObservableObject {
    @Published var state: ImageLoadState = .idle

    private let url: URL
    private let loader: AuthenticatedImageLoading
    private var task: Task<Void, Never>?

    init(url: URL, loader: AuthenticatedImageLoading) {
        self.url = url
        self.loader = loader
    }

    /// Load image asynchronously
    func load() async {
        guard state != .loading else { return }

        state = .loading

        do {
            let image = try await loader.loadImage(from: url)
            state = .loaded(image)
        } catch let error as ImageLoadError {
            state = .failed(error)
        } catch {
            state = .failed(.networkError(error.localizedDescription))
        }
    }

    /// Cancel ongoing load operation
    func cancel() {
        task?.cancel()
        state = .idle
    }
}
```

### 5. Cache Models

Data structures for managing image cache.

```swift
/// Configuration for avatar caching
struct AvatarCacheConfiguration {
    /// Maximum number of images in memory cache
    let memoryCacheLimit: Int

    /// Maximum memory cost in bytes (50 MB default)
    let memoryCapacityBytes: Int

    /// Maximum disk cache size in bytes (150 MB default)
    let diskCapacityBytes: Int

    /// Default cache configuration
    static let `default` = AvatarCacheConfiguration(
        memoryCacheLimit: 100,
        memoryCapacityBytes: 50 * 1024 * 1024,
        diskCapacityBytes: 150 * 1024 * 1024
    )
}

/// Cache key for avatar images
struct AvatarCacheKey: Hashable {
    let contactID: Int
    let url: URL

    init(contactID: Int, url: URL) {
        self.contactID = contactID
        self.url = url
    }
}
```

### 6. Authenticated Image Loader Protocol

Protocol defining authenticated image loading behavior (enables testing).

```swift
/// Protocol for authenticated image loading
protocol AuthenticatedImageLoading {
    /// Load image from URL with authentication if required
    /// - Parameter url: URL of the image to load
    /// - Returns: Loaded UIImage
    /// - Throws: ImageLoadError on failure
    func loadImage(from url: URL) async throws -> UIImage
}

/// Production implementation of authenticated image loader
class AuthenticatedImageLoader: AuthenticatedImageLoading {
    private let apiToken: String
    private let cache: NSCache<NSURL, UIImage>
    private let configuration: AvatarCacheConfiguration

    init(apiToken: String, configuration: AvatarCacheConfiguration = .default) {
        self.apiToken = apiToken
        self.configuration = configuration

        // Configure memory cache
        self.cache = NSCache<NSURL, UIImage>()
        self.cache.countLimit = configuration.memoryCacheLimit
        self.cache.totalCostLimit = configuration.memoryCapacityBytes
    }

    func loadImage(from url: URL) async throws -> UIImage {
        // Check memory cache first
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        // Build authenticated request
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .returnCacheDataElseLoad

        // Add authentication for Monica-hosted images
        if shouldAuthenticate(url: url) {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        // Fetch from network or disk cache
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageLoadError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw ImageLoadError.unauthorized
        case 404:
            throw ImageLoadError.notFound
        default:
            throw ImageLoadError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Decode image
        guard let image = UIImage(data: data) else {
            throw ImageLoadError.invalidData
        }

        // Cache decompressed image in memory
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)

        return image
    }

    /// Determine if URL requires authentication
    private func shouldAuthenticate(url: URL) -> Bool {
        guard let host = url.host else { return false }

        // Skip auth for external avatar services
        let externalServices = ["gravatar.com", "ui-avatars.com", "adorable.io"]
        return !externalServices.contains(where: { host.contains($0) })
    }

    /// Clear all cached images
    func clearCache() {
        cache.removeAllObjects()
    }
}
```

## Color Extension

Helper extension for parsing hex color codes from API.

```swift
extension Color {
    /// Initialize Color from hex string (e.g., "#b3d5fe")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (128, 128, 128, 255) // Default gray
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## Relationships

### Data Flow Diagram

```
Contact (API Response)
    ↓
    ├─→ AvatarInfo (avatar metadata)
    │       ↓
    │       ├─→ avatarURL (parsed URL)
    │       ├─→ source (avatar type)
    │       └─→ defaultAvatarColor (hex color)
    │
    ├─→ Contact Extensions
    │       ↓
    │       ├─→ shouldLoadAvatar (decision)
    │       ├─→ initials (fallback text)
    │       └─→ initialsColor (fallback color)
    │
    └─→ AvatarView (SwiftUI)
            ↓
            ├─→ ImageLoader (state management)
            │       ↓
            │       └─→ AuthenticatedImageLoader (networking)
            │               ↓
            │               ├─→ NSCache (L1 memory cache)
            │               └─→ URLCache (L2 disk cache)
            │
            └─→ InitialsAvatar (fallback view)
```

### Cache Hierarchy

```
URLSession Request
    ↓
    ├─→ NSCache (L1 - Memory)
    │   • Decompressed UIImage objects
    │   • 100 image limit
    │   • 50 MB capacity
    │   • Auto-eviction on memory pressure
    │
    └─→ URLCache (L2 - Disk)
        • Raw HTTP response data
        • 50 MB memory / 150 MB disk
        • Respects Cache-Control headers
        • Persists across app launches
```

### State Transitions

```
ImageLoadState State Machine:

    idle
     ↓ load()
    loading
     ↓
     ├─→ loaded(UIImage)     [success]
     └─→ failed(Error)       [failure]
              ↓
         [fallback to initials in view]
```

## Usage Examples

### Basic Avatar Display

```swift
struct ContactRowView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        HStack {
            AvatarView(
                contact: contact,
                size: 50,
                imageLoader: AuthenticatedImageLoader(
                    apiToken: authManager.apiToken
                )
            )

            Text(contact.fullName)
        }
    }
}
```

### Manual Cache Clearing

```swift
// On logout
func logout() {
    // Clear avatar caches
    imageLoader.clearCache()
    URLCache.shared.removeAllCachedResponses()

    // Continue with logout...
}
```

### Testing with Mock Loader

```swift
class MockImageLoader: AuthenticatedImageLoading {
    var mockImage: UIImage?
    var mockError: ImageLoadError?

    func loadImage(from url: URL) async throws -> UIImage {
        if let error = mockError {
            throw error
        }
        return mockImage ?? UIImage()
    }
}

// In tests
let mockLoader = MockImageLoader()
mockLoader.mockImage = testImage
let loader = ImageLoader(url: testURL, loader: mockLoader)
await loader.load()
XCTAssertEqual(loader.state, .loaded(testImage))
```

## Performance Considerations

### Memory Management

- **NSCache**: Automatically evicts images under memory pressure
- **Cost Assignment**: Each cached image tagged with approximate memory cost
- **List Optimization**: Off-screen images released automatically
- **Memory Warnings**: NSCache responds to system memory warnings

### Network Optimization

- **URLCache**: Reduces redundant network requests
- **Cache-Control**: Respects Monica's HTTP caching headers
- **Timeout**: 30-second request timeout prevents hanging
- **Parallel Loading**: Multiple avatars load concurrently

### SwiftUI Integration

- **@StateObject**: Proper lifecycle management for ImageLoader
- **.task{}**: Automatic load on view appearance
- **Cancellation**: Loads cancelled when view disappears
- **Equatable**: Prevents unnecessary view updates

## Testing Strategy

### Unit Tests
- Avatar URL parsing (valid, invalid, empty cases)
- Initials generation (various name formats)
- Color generation (deterministic hashing)
- Error handling (all ImageLoadError cases)

### Integration Tests
- Authenticated vs unauthenticated URLs
- Cache hit/miss scenarios
- Gravatar URL handling (no auth headers)
- Memory cache eviction

### UI Tests
- Avatar display with network image
- Fallback to initials on error
- Loading state indicator
- Cache persistence across app restarts

### Performance Tests
- Large list scrolling (500+ contacts)
- Memory usage under load
- Concurrent image loading
- Cache effectiveness

## Migration Notes

### From Current Implementation

**Before** (ContactsListView.swift):
```swift
Circle()
    .fill(Color.blue.opacity(0.3))
    .overlay(Text(contact.initials))
```

**After**:
```swift
AvatarView(contact: contact, size: 50, imageLoader: imageLoader)
```

### Required Changes
1. Add `avatar: AvatarInfo?` to Contact model
2. Update API response parsing to include avatar field
3. Create AuthenticatedImageLoader singleton or inject via environment
4. Replace all Circle/Text avatar instances with AvatarView
5. Add cache clearing to logout flow
6. Update Core Data model if persisting avatar URLs

## References

- Research: `/specs/001-003-avatar-authentication/research.md`
- Contact API: Monica API v1 `/api/contacts/{id}`
- Photo API: Monica API v1 `/api/photos`
- Gravatar: `https://gravatar.com/avatar/{hash}`
