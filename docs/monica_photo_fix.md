# Monica Photo Authentication Fix

## Problem Summary

The Monica iOS app cannot load contact photos because:

1. ✅ Monica API routes (`/api/*`) use Bearer token authentication - **working perfectly**
2. ❌ Monica storage routes (`/store/photos/*`) use session cookie authentication - **not compatible with Bearer tokens**
3. The iOS app successfully fetches data using Bearer tokens but cannot load photos from storage URLs

## Root Cause

Monica uses Laravel's different middleware for different route types:
- **API Middleware** (`/api/*`): Accepts Bearer token in `Authorization` header
- **Web Middleware** (`/store/photos/*`): Requires session cookies from web browser login

This is confirmed by:
- App logs showing successful API calls with HTTP 200 responses
- curl tests showing `/store/photos/` URLs return HTML redirects when using Bearer tokens
- nginx config correctly forwarding Authorization headers

## Recommended Solution

Make photos publicly accessible by configuring nginx to bypass authentication for photo storage.

### Implementation Steps

1. **SSH into your server**:
   ```bash
   ssh user@your-server -p PORT
   ```

2. **Edit the nginx configuration file** (location may vary depending on your setup)

3. **Add this location block** BEFORE the existing `/` location block:
   ```nginx
   # Allow public access to photo storage for mobile app
   location /storage/photos/ {
       proxy_pass http://localhost:8087;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }

   location /store/photos/ {
       proxy_pass http://localhost:8087;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```

4. **Test the configuration**:
   ```bash
   sudo nginx -t
   ```

5. **Reload nginx**:
   ```bash
   sudo nginx -s reload
   ```

6. **Test with curl**:
   ```bash
   curl -I "https://your-monica-server.com/store/photos/[photo-filename]"
   ```
   Should return HTTP 200 and image content type (not HTML redirect)

## Alternative Solutions

### Option 2: Configure Monica to Make Photos Public

Edit Monica's `.env` file to make photos publicly accessible:
```env
FILESYSTEM_PHOTOS_VISIBILITY=public
```

Then restart Monica:
```bash
cd /path/to/monica
docker-compose restart
```

### Option 3: Use Gravatar Fallbacks

Contacts without uploaded photos will automatically use Gravatar or adorable.io avatars, which are publicly accessible and work without authentication.

## Verification

After implementing the fix, test in the iOS app:
1. Pull to refresh contacts list
2. Check if photos load for contacts that have photos
3. App logs should show successful image loads with HTTP 200 responses

