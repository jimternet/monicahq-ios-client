# Feature Request: Contact Photos Gallery

## Overview
Upload and manage photos for contacts - beyond just avatars, maintain a photo gallery of memories with each contact.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/photos` - List all photos
- `GET /api/photos/{id}` - Get single photo
- `POST /api/photos` - Upload photo
- `DELETE /api/photos/{id}` - Delete photo
- `GET /api/contacts/{contact}/photos` - Get photos for specific contact

## Proposed Models

```swift
struct Photo: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let originalFilename: String
    let newFilename: String
    let filesize: Int
    let mimeType: String
    let link: String // URL to photo
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case originalFilename = "original_filename"
        case newFilename = "new_filename"
        case filesize
        case mimeType = "mime_type"
        case link
        case contact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(filesize))
    }
}
```

## UI Components Needed

### 1. ContactPhotosGallery
- Grid layout of photos
- Tap to view full size
- Photo metadata (date, size)
- Add photo button
- Select multiple for deletion

### 2. PhotoDetailView
- Full screen photo view
- Pinch to zoom
- Share/export options
- Delete option
- Caption/date information

### 3. AddPhotoView
- Camera capture
- Photo library picker
- Multiple selection support
- Compression options
- Caption input (if supported)

### 4. PhotosSection (Contact Detail)
- Preview of recent photos (grid)
- "View all" button to gallery
- Quick add photo button
- Photo count indicator

### 5. GlobalPhotosView (Optional)
- All photos across contacts
- Sort by date/contact
- Search by contact
- Memory lane feature

## Implementation Priority
**MEDIUM** - Visual memories are valuable but not core CRM functionality

## Key Features
1. Photo upload from camera/library
2. Multiple photos per contact
3. Grid gallery view
4. Full-screen viewing with zoom
5. Photo metadata display
6. Bulk upload support
7. Cache downloaded photos locally

## iOS Integration
- UIImagePickerController for camera/library
- PHPickerViewController for iOS 14+ multi-select
- Core Image for compression
- Async image loading and caching
- Background upload support
- Photo library permission handling

## Technical Considerations

### Upload
```swift
func uploadPhoto(contactId: Int, imageData: Data) async throws -> Photo {
    let boundary = UUID().uuidString
    var request = URLRequest(url: baseURL.appendingPathComponent("photos"))
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    // Add contact_id field
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"contact_id\"\r\n\r\n".data(using: .utf8)!)
    body.append("\(contactId)\r\n".data(using: .utf8)!)

    // Add photo data
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body
    // ... execute request
}
```

### Image Caching
```swift
class PhotoCache {
    static let shared = PhotoCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    func cacheImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
        // Also save to disk for persistence
    }

    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
}
```

## Visual Design
- Grid layout (3-4 columns)
- Square thumbnails with crop
- Smooth animations
- Loading placeholders
- Pull to refresh
- Infinite scroll pagination

## Advanced Features (Future)
- Face detection and tagging
- Photo timeline/slideshow
- Before/after comparisons
- Shared albums with contacts
- Photo notes/captions
- Date taken extraction from EXIF
- Location data from photos
- Memory suggestions

## Related Files
- MonicaAPIClient.swift - Add photo upload/fetch methods
- ContactDetailView.swift - Add photos gallery section
- New models for Photo
- ImageCache utility class

## Notes
- Compression is critical for mobile uploads
- Consider storage limits on Monica server
- Background uploads for large photos
- Handle authentication for photo URLs
- EXIF data preservation vs stripping
- iCloud photos integration possibility
