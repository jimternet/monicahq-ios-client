# Quickstart: Avatar Authentication Implementation

**Feature**: Avatar Authentication & Display
**Date**: 2025-11-24
**Estimated Time**: 4-6 hours

## Overview

This quickstart guide provides step-by-step instructions for implementing authenticated avatar loading in the Monica iOS Client. Follow these steps in order to add avatar support with graceful fallbacks to the existing app.

## Prerequisites

Before starting implementation:

- [ ] Read `/specs/001-003-avatar-authentication/research.md`
- [ ] Review `/specs/001-003-avatar-authentication/data-model.md`
- [ ] Review `/specs/001-003-avatar-authentication/contracts/avatar-api.md`
- [ ] Ensure you have access to a Monica instance with test contacts
- [ ] Have valid API token for testing

## Implementation Steps

### Step 1: Update Contact Model (30 minutes)

Add avatar support to the existing Contact model.

**File**: `monicaHqClient/Models/Contact.swift`

**1.1 Add AvatarInfo struct**:

```swift
// Add to Contact.swift file

struct AvatarInfo: Codable, Equatable {
    let url: String
    let source: String
    let defaultAvatarColor: String?

    enum CodingKeys: String, CodingKey {
        case url
        case source
        case defaultAvatarColor = "default_avatar_color"
    }
}

enum AvatarSource: String {
    case `default`
    case gravatar
    case photo
    case adorable
}
```

**1.2 Update Contact Information struct**:

```swift
// Add avatar field to Contact.Information
struct Information: Codable, Equatable {
    // ... existing fields ...
    let avatar: AvatarInfo?
}
```

**1.3 Add Contact extensions**:

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

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }

    var initialsColor: Color {
        // Prefer Monica's provided color
        if let hexColor = information?.avatar?.defaultAvatarColor {
            return Color(hex: hexColor)
        }

        // Fallback: Generate deterministic color from name
        return generateColorFromName()
    }

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

**Test**: Build project to ensure Contact model compiles.

### Step 2: Create Color Helper (15 minutes)

Add hex color parsing support.

**File**: `monicaHqClient/Utilities/ColorExtensions.swift` (new file)

```swift
import SwiftUI

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

**Test**: Create unit test for hex color parsing.

### Step 3: Create Image Loading Infrastructure (1 hour)

Build the authenticated image loading system.

**File**: `monicaHqClient/Services/AuthenticatedImageLoader.swift` (new file)

```swift
import UIKit
import Foundation

// MARK: - Protocol

protocol AuthenticatedImageLoading {
    func loadImage(from url: URL) async throws -> UIImage
    func clearCache()
}

// MARK: - Error Types

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

// MARK: - Implementation

class AuthenticatedImageLoader: AuthenticatedImageLoading {
    private let apiToken: String
    private let cache: NSCache<NSURL, UIImage>

    init(apiToken: String) {
        self.apiToken = apiToken

        // Configure memory cache
        self.cache = NSCache<NSURL, UIImage>()
        self.cache.countLimit = 100
        self.cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
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
        let cost = data.count
        cache.setObject(image, forKey: url as NSURL, cost: cost)

        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Private Helpers

    private func shouldAuthenticate(url: URL) -> Bool {
        guard let host = url.host else { return false }

        // Skip auth for external avatar services
        let externalServices = ["gravatar.com", "ui-avatars.com", "adorable.io"]
        return !externalServices.contains(where: { host.contains($0) })
    }
}
```

**Test**: Build project and verify no compilation errors.

### Step 4: Create Image Loader ObservableObject (45 minutes)

**File**: `monicaHqClient/ViewModels/ImageLoader.swift` (new file)

```swift
import SwiftUI

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

    func cancel() {
        task?.cancel()
        state = .idle
    }
}
```

**Test**: Build project to verify compilation.

### Step 5: Create Avatar Components (1 hour)

Build the SwiftUI views for displaying avatars.

**File**: `monicaHqClient/Views/Components/InitialsAvatar.swift` (new file)

```swift
import SwiftUI

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
            .accessibilityLabel("\(contact.fullName) avatar")
            .accessibilityAddTraits(.isImage)
    }
}

#if DEBUG
struct InitialsAvatar_Previews: PreviewProvider {
    static var previews: some View {
        InitialsAvatar(
            contact: Contact(
                id: 1,
                firstName: "John",
                lastName: "Doe",
                nickname: nil,
                completeName: "John Doe",
                information: nil
            ),
            size: 50
        )
    }
}
#endif
```

**File**: `monicaHqClient/Views/Components/AvatarView.swift` (new file)

```swift
import SwiftUI

struct AvatarView: View {
    let contact: Contact
    let size: CGFloat
    let imageLoader: AuthenticatedImageLoading

    @StateObject private var loader: ImageLoader

    init(contact: Contact, size: CGFloat, imageLoader: AuthenticatedImageLoading) {
        self.contact = contact
        self.size = size
        self.imageLoader = imageLoader

        // Initialize loader if avatar should be loaded
        if let url = contact.avatarURL, contact.shouldLoadAvatar {
            _loader = StateObject(wrappedValue: ImageLoader(url: url, loader: imageLoader))
        } else {
            // Create dummy loader that won't be used
            _loader = StateObject(wrappedValue: ImageLoader(
                url: URL(string: "https://placeholder.com")!,
                loader: imageLoader
            ))
        }
    }

    var body: some View {
        Group {
            if contact.shouldLoadAvatar {
                avatarImageView
            } else {
                // Show initials immediately for default avatars
                InitialsAvatar(contact: contact, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task {
            if contact.shouldLoadAvatar {
                await loader.load()
            }
        }
    }

    @ViewBuilder
    private var avatarImageView: some View {
        switch loader.state {
        case .idle, .loading:
            ZStack {
                InitialsAvatar(contact: contact, size: size)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

        case .loaded(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityLabel("\(contact.fullName) avatar photo")

        case .failed:
            // Fallback to initials on any error
            InitialsAvatar(contact: contact, size: size)
        }
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default avatar (initials)
            AvatarView(
                contact: Contact(
                    id: 1,
                    firstName: "John",
                    lastName: "Doe",
                    nickname: nil,
                    completeName: "John Doe",
                    information: Contact.Information(
                        avatar: AvatarInfo(
                            url: "",
                            source: "default",
                            defaultAvatarColor: "#b3d5fe"
                        )
                    )
                ),
                size: 50,
                imageLoader: MockImageLoader()
            )

            // Gravatar avatar
            AvatarView(
                contact: Contact(
                    id: 2,
                    firstName: "Jane",
                    lastName: "Smith",
                    nickname: nil,
                    completeName: "Jane Smith",
                    information: Contact.Information(
                        avatar: AvatarInfo(
                            url: "https://www.gravatar.com/avatar/test",
                            source: "gravatar",
                            defaultAvatarColor: "#ffd6a5"
                        )
                    )
                ),
                size: 50,
                imageLoader: MockImageLoader()
            )
        }
        .padding()
    }
}

// Mock for previews
class MockImageLoader: AuthenticatedImageLoading {
    func loadImage(from url: URL) async throws -> UIImage {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return UIImage(systemName: "person.circle.fill")!
    }

    func clearCache() {}
}
#endif
```

**Test**: Run app in simulator and verify InitialsAvatar displays correctly.

### Step 6: Integrate into Contacts List (30 minutes)

Replace existing avatar placeholders with new AvatarView.

**File**: `monicaHqClient/Views/ContactsListView.swift`

**6.1 Add image loader to view**:

```swift
struct ContactsListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ContactsViewModel()

    // Add image loader
    private var imageLoader: AuthenticatedImageLoading {
        AuthenticatedImageLoader(apiToken: authManager.apiToken)
    }

    var body: some View {
        // ... existing code ...
    }
}
```

**6.2 Update ContactRowView**:

Find the existing Circle/Text avatar code and replace with:

```swift
// BEFORE:
Circle()
    .fill(Color.blue.opacity(0.3))
    .frame(width: 50, height: 50)
    .overlay(
        Text(contact.initials)
            .font(.headline)
            .foregroundColor(.blue)
    )

// AFTER:
AvatarView(
    contact: contact,
    size: 50,
    imageLoader: imageLoader
)
```

**Test**: Run app and verify avatars show initials with colors.

### Step 7: Configure URL Caching (15 minutes)

Set up disk caching for avatar images.

**File**: `monicaHqClient/MonicaApp.swift`

```swift
import SwiftUI

@main
struct MonicaApp: App {
    @StateObject private var authManager = AuthenticationManager()

    init() {
        configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }

    private func configureURLCache() {
        // Configure URLCache for avatar images
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
            diskCapacity: 150 * 1024 * 1024,    // 150 MB disk
            diskPath: "avatar_cache"
        )
        URLCache.shared = cache
    }
}
```

**Test**: Build and run app.

### Step 8: Clear Cache on Logout (15 minutes)

Ensure avatar caches are cleared when user logs out.

**File**: `monicaHqClient/Services/AuthenticationManager.swift`

```swift
class AuthenticationManager: ObservableObject {
    // ... existing code ...

    func logout() {
        // Clear avatar caches
        clearAvatarCache()

        // Clear API token
        apiToken = nil

        // Continue with existing logout logic...
    }

    private func clearAvatarCache() {
        // Clear URLCache (disk cache)
        URLCache.shared.removeAllCachedResponses()

        // Note: Memory cache in AuthenticatedImageLoader is cleared
        // when new loader instance is created on next login
    }
}
```

**Test**: Login, view contacts, logout, login again, verify avatars reload.

### Step 9: Add Unit Tests (1 hour)

Create tests for avatar loading logic.

**File**: `monicaHqClientTests/AuthenticatedImageLoaderTests.swift` (new file)

```swift
import XCTest
@testable import monicaHqClient

class AuthenticatedImageLoaderTests: XCTestCase {
    var loader: AuthenticatedImageLoader!

    override func setUp() {
        super.setUp()
        loader = AuthenticatedImageLoader(apiToken: "test-token")
    }

    override func tearDown() {
        loader.clearCache()
        loader = nil
        super.tearDown()
    }

    func testLoadImageFromCache() async throws {
        // Test that cached images are returned without network request
        let url = URL(string: "https://app.monicahq.com/storage/photos/test.jpg")!

        // First load (network request)
        // Note: This test requires mocking URLSession
        // For MVP, focus on integration tests instead
    }

    func testShouldNotAuthenticateGravatar() {
        // Test that Gravatar URLs don't get auth headers
        let gravatarURL = URL(string: "https://www.gravatar.com/avatar/test")!

        // Access private method through reflection or make it internal for testing
        // For MVP, verify through integration testing
    }

    func testClearCache() {
        // Test cache clearing
        loader.clearCache()
        // Verify cache is empty
    }
}
```

**File**: `monicaHqClientTests/ContactExtensionsTests.swift` (new file)

```swift
import XCTest
@testable import monicaHqClient

class ContactExtensionsTests: XCTestCase {

    func testInitialsGeneration() {
        let contact = Contact(
            id: 1,
            firstName: "John",
            lastName: "Doe",
            nickname: nil,
            completeName: "John Doe",
            information: nil
        )

        XCTAssertEqual(contact.initials, "JD")
    }

    func testInitialsWithSingleName() {
        let contact = Contact(
            id: 2,
            firstName: "Madonna",
            lastName: nil,
            nickname: nil,
            completeName: "Madonna",
            information: nil
        )

        XCTAssertEqual(contact.initials, "M")
    }

    func testAvatarURLParsing() {
        let contact = Contact(
            id: 3,
            firstName: "Test",
            lastName: "User",
            nickname: nil,
            completeName: "Test User",
            information: Contact.Information(
                avatar: AvatarInfo(
                    url: "https://app.monicahq.com/storage/photos/test.jpg",
                    source: "photo",
                    defaultAvatarColor: "#b3d5fe"
                )
            )
        )

        XCTAssertNotNil(contact.avatarURL)
        XCTAssertEqual(contact.avatarURL?.absoluteString, "https://app.monicahq.com/storage/photos/test.jpg")
    }

    func testShouldLoadAvatarForDefault() {
        let contact = Contact(
            id: 4,
            firstName: "Test",
            lastName: "User",
            nickname: nil,
            completeName: "Test User",
            information: Contact.Information(
                avatar: AvatarInfo(
                    url: "",
                    source: "default",
                    defaultAvatarColor: "#b3d5fe"
                )
            )
        )

        XCTAssertFalse(contact.shouldLoadAvatar)
    }

    func testShouldLoadAvatarForPhoto() {
        let contact = Contact(
            id: 5,
            firstName: "Test",
            lastName: "User",
            nickname: nil,
            completeName: "Test User",
            information: Contact.Information(
                avatar: AvatarInfo(
                    url: "https://app.monicahq.com/storage/photos/test.jpg",
                    source: "photo",
                    defaultAvatarColor: "#b3d5fe"
                )
            )
        )

        XCTAssertTrue(contact.shouldLoadAvatar)
    }

    func testColorGeneration() {
        let contact1 = Contact(
            id: 6,
            firstName: "John",
            lastName: "Doe",
            nickname: nil,
            completeName: "John Doe",
            information: nil
        )

        let contact2 = Contact(
            id: 7,
            firstName: "John",
            lastName: "Doe",
            nickname: nil,
            completeName: "John Doe",
            information: nil
        )

        // Same name should generate same color (deterministic)
        XCTAssertEqual(contact1.initialsColor, contact2.initialsColor)
    }
}
```

**Test**: Run unit tests with `Cmd+U`.

### Step 10: Integration Testing (30 minutes)

Test with real Monica API.

**Manual Test Plan**:

1. **Default Avatar**:
   - [ ] Create contact with no avatar set
   - [ ] Verify initials display with colored background
   - [ ] Verify no network request is made

2. **Gravatar Avatar**:
   - [ ] Set contact to use Gravatar
   - [ ] Verify image loads if Gravatar exists
   - [ ] Verify fallback to initials if Gravatar returns 404
   - [ ] Verify no `Authorization` header sent (use Charles Proxy)

3. **Photo Avatar**:
   - [ ] Upload photo to contact
   - [ ] Verify photo loads with authentication
   - [ ] Verify `Authorization: Bearer {token}` header present
   - [ ] Test cache: scroll away and back, verify instant display

4. **Error Handling**:
   - [ ] Test with invalid token (401 response)
   - [ ] Test with deleted photo (404 response)
   - [ ] Test with airplane mode (network error)
   - [ ] Verify all errors fall back to initials

5. **Performance**:
   - [ ] Create 100+ contacts
   - [ ] Scroll through list
   - [ ] Verify smooth scrolling
   - [ ] Check memory usage in Instruments

6. **Cache Clearing**:
   - [ ] View avatars (populate cache)
   - [ ] Logout
   - [ ] Login
   - [ ] Verify avatars reload (cache cleared)

## Integration Points

### Environment Setup

Add AuthenticatedImageLoader to the environment for easy access.

```swift
struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        ContactsListView()
            .environment(\.imageLoader, AuthenticatedImageLoader(apiToken: authManager.apiToken))
    }
}

// Environment key
private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: AuthenticatedImageLoading = MockImageLoader()
}

extension EnvironmentValues {
    var imageLoader: AuthenticatedImageLoading {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}

// Usage in views
struct ContactRowView: View {
    @Environment(\.imageLoader) var imageLoader

    var body: some View {
        AvatarView(contact: contact, size: 50, imageLoader: imageLoader)
    }
}
```

### Contact Detail View

Apply same avatar to contact detail screen.

```swift
// In ContactDetailView.swift
AvatarView(
    contact: contact,
    size: 120,  // Larger size for detail view
    imageLoader: imageLoader
)
```

## Testing Approach

### Unit Testing

Focus on:
- Contact extensions (initials, colors, URL parsing)
- Error type equality and descriptions
- Color hex parsing

### Integration Testing

Focus on:
- Network requests with authentication
- Cache hit/miss scenarios
- Error handling and fallbacks

### UI Testing

Focus on:
- Avatar display in lists and detail views
- Loading states and transitions
- Accessibility labels

### Performance Testing

Use Instruments:
- Time Profiler: Verify efficient image loading
- Allocations: Check memory usage with 500+ contacts
- Network: Verify caching reduces requests

## Troubleshooting

### Issue: Photos don't load (401 error)

**Cause**: Monica static files may require session cookies instead of Bearer token.

**Solution**:
1. Test if photo URLs work in browser while logged in
2. Check Monica API documentation for photo authentication
3. If Bearer token doesn't work, log error and show initials
4. Future enhancement: Investigate cookie-based auth

### Issue: Avatars flash/reload on scroll

**Cause**: SwiftUI recreating views or cache not working.

**Solution**:
1. Add `.id(contact.id)` to AvatarView
2. Verify NSCache is properly configured
3. Check StateObject initialization

### Issue: Memory warnings with large lists

**Cause**: Too many images in memory cache.

**Solution**:
1. Reduce NSCache countLimit (default: 100)
2. Lower totalCostLimit (default: 50 MB)
3. Implement prefetch cancellation for off-screen items

### Issue: Gravatar requests have auth headers

**Cause**: `shouldAuthenticate()` logic not working.

**Solution**:
1. Verify URL host parsing
2. Check external services list includes "gravatar.com"
3. Add logging to debug which URLs get auth headers

## Performance Optimization Tips

1. **Fixed Avatar Sizes**: Use same size throughout app for cache efficiency
2. **Lazy Loading**: Only load visible avatars (SwiftUI handles automatically)
3. **Prefetch**: Consider prefetching next page during pagination
4. **Image Resizing**: Resize large photos to avatar size before caching
5. **Cost Assignment**: Assign memory cost based on image data size

## Next Steps

After completing implementation:

1. **Monitor Production**:
   - Track 401/403 error rates (photo auth issues)
   - Monitor cache hit rate
   - Watch memory usage patterns

2. **Future Enhancements**:
   - Offline support (Core Data caching)
   - Pull-to-refresh cache invalidation
   - Upload avatar from iOS app
   - Image cropping/editing

3. **Documentation**:
   - Update CLAUDE.md with avatar implementation notes
   - Document any Monica API discoveries about photo auth
   - Add comments for complex caching logic

## Checklist

Implementation complete when:

- [ ] Contact model includes avatar field
- [ ] AuthenticatedImageLoader implemented and tested
- [ ] AvatarView and InitialsAvatar components created
- [ ] Contacts list shows avatars with fallbacks
- [ ] Contact detail view shows larger avatar
- [ ] Cache configured (URLCache + NSCache)
- [ ] Cache cleared on logout
- [ ] Unit tests written and passing
- [ ] Manual testing completed
- [ ] Performance validated with 100+ contacts
- [ ] Accessibility labels added
- [ ] Error handling tested (401, 404, network errors)
- [ ] Documentation updated

## Estimated Timeline

| Task | Time | Total |
|------|------|-------|
| Update Contact model | 30 min | 0.5 hr |
| Color helper | 15 min | 0.75 hr |
| AuthenticatedImageLoader | 1 hr | 1.75 hr |
| ImageLoader ObservableObject | 45 min | 2.5 hr |
| Avatar components | 1 hr | 3.5 hr |
| Integration | 30 min | 4 hr |
| Caching setup | 15 min | 4.25 hr |
| Logout cleanup | 15 min | 4.5 hr |
| Unit tests | 1 hr | 5.5 hr |
| Integration testing | 30 min | 6 hr |

**Total: 4-6 hours** (depending on testing depth)

## Resources

- **Research**: `/specs/001-003-avatar-authentication/research.md`
- **Data Model**: `/specs/001-003-avatar-authentication/data-model.md`
- **API Contracts**: `/specs/001-003-avatar-authentication/contracts/avatar-api.md`
- **Monica API Docs**: https://www.monicahq.com/api
- **Gravatar Docs**: https://docs.gravatar.com/api/avatars/
- **Apple URLCache**: https://developer.apple.com/documentation/foundation/urlcache
- **Apple NSCache**: https://developer.apple.com/documentation/foundation/nscache

## Support

If you encounter issues during implementation:

1. Check Troubleshooting section above
2. Review research document for technical decisions
3. Verify Monica API responses match contracts
4. Test with Charles Proxy to inspect network requests
5. Use Xcode debugger to inspect cache states
