# Feature Request: Avatar/Photo Image Support

## Issue
Contact avatar images are not loading in the iOS app. The app shows the fallback initials instead of actual photos.

## Root Cause
Monica's server uses **session-based authentication** for static files in `/store/` directory (photos, avatars). The Bearer token authentication works for API endpoints but **not for direct file access**.

When requesting an image URL:
```
GET /store/photos/xxx.jpeg
Authorization: Bearer <token>
```

The server returns **HTTP 302 redirect** to the home page instead of the image.

## Technical Details

### Current Implementation
- [AuthenticatedImageLoader.swift](../MonicaClient/Utilities/AuthenticatedImageLoader.swift) - Sends Bearer token with image requests
- [ContactAvatar.swift](../MonicaClient/Views/ContactAvatar.swift) - Uses AuthenticatedAsyncImage component
- Avatar URLs are correctly extracted from API responses

### Why Web App Works
Monica's Vue.js frontend uses simple `<img src="">` tags. The browser automatically sends session cookies which authenticate the request. No special auth headers needed.

### Server Configuration Issue
The Monica server (likely nginx/apache configuration) doesn't accept Bearer tokens for static file paths. It only accepts Laravel session cookies.

## Proposed Solutions

### Option 1: Server-Side Fix (Recommended)
Configure nginx to accept Bearer tokens for `/store/` paths:

```nginx
location /store/ {
    # Check for Authorization header and validate token
    # Pass through to storage if valid
}
```

### Option 2: Proxy Through API
Create an API endpoint that serves files with token auth:
```
GET /api/storage/photos/{filename}
Authorization: Bearer <token>
```

This would require modifying the Monica server code.

### Option 3: Public Storage (Less Secure)
Configure storage folder as publicly accessible:
```nginx
location /store/ {
    alias /path/to/storage/;
}
```

**Not recommended** as it exposes all user photos publicly.

### Option 4: Use Gravatar Only
Disable custom photo support and rely on Gravatar:
- Pros: Works out of the box
- Cons: Loses custom contact photos

## Current Workaround
The app falls back to colored initials avatars when images fail to load. This is functional but not ideal for users who have uploaded contact photos.

## Priority
Medium - Core functionality works, but contact photos are a nice-to-have feature for user experience.

## Related Files
- [MonicaClient/Utilities/AuthenticatedImageLoader.swift](../MonicaClient/Utilities/AuthenticatedImageLoader.swift)
- [MonicaClient/Views/ContactAvatar.swift](../MonicaClient/Views/ContactAvatar.swift)
- [MonicaClient/Services/AuthenticationManager.swift](../MonicaClient/Services/AuthenticationManager.swift)
- [MonicaClient/Models/Contact.swift](../MonicaClient/Models/Contact.swift) - AvatarInfo struct

## Testing
To verify the issue:
```bash
curl -I "https://your-monica-server/store/photos/filename.jpeg" \
  -H "Authorization: Bearer <your-token>"
```

If you get HTTP 302 redirect, the server doesn't accept Bearer tokens for storage files.
