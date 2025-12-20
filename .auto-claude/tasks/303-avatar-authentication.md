# Task: Contact Avatar Display

## Spec Reference
- **Spec Location**: `specs/303-avatar-authentication/`
- **Feature Branch**: `303-avatar-authentication` (to be created)
- **Status**: pending

## Description
Contact avatar images are not loading in the iOS app due to authentication issues with the Monica server's static file serving.

This feature/fix enables users to:
- View contact photos in contact list and details
- See graceful fallback (colored initials) when photos unavailable
- Experience fast, cached photo loading
- Support for both custom uploaded photos and Gravatar photos

## Priority Stories
1. **P1**: View Contact Photos - Display photos in list and detail views
2. **P1**: Graceful Fallback for Missing Photos - Colored initial avatars
3. **P2**: Fast Photo Loading - Local caching for performance
4. **P2**: Support for Both Photo Types - Custom and Gravatar photos

## Key Entities
- **Avatar**: Visual representation (photo or initials) of a contact
- **Photo Cache**: Local storage of previously loaded photos

## Action Required
1. Create feature branch: `git checkout -b feature/303-avatar-authentication`
2. Review spec at `specs/303-avatar-authentication/spec.md`
3. Create implementation plan
4. Implement according to spec requirements

## Notes
- Monica backend serves photos from `/store/photos/` directory
- Photo authentication may require special handling beyond standard API token
- Server may use session-based auth for static files
- Alternative auth methods may be needed (server config, API proxy, client workarounds)
- Note: Branch `001-003-avatar-authentication` exists but uses different numbering scheme
