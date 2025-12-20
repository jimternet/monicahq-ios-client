# Task: Contact Photo Gallery

## Spec Reference
- **Spec Location**: `specs/312-photo-gallery/`
- **Feature Branch**: `312-photo-gallery` (to be created)
- **Status**: pending

## Description
Upload and manage photos for contacts - beyond just avatars, maintain a photo gallery of memories with each contact.

This feature enables users to:
- Upload photos to contact galleries from camera or library
- View contact photo galleries in grid layout
- Interact with full-size photos (zoom, share)
- Manage gallery photos (delete, view metadata)
- Perform bulk photo operations

## Priority Stories
1. **P1**: Upload Photos to Contact Gallery - Camera and library upload
2. **P1**: View Contact Photo Gallery - Grid layout with thumbnails
3. **P2**: Interact with Full-Size Photos - Zoom and share
4. **P2**: Manage Gallery Photos - Delete and view metadata
5. **P3**: Bulk Photo Operations - Multi-select upload/delete

## Key Entities
- **Photo**: Image file associated with a contact
- **Photo Metadata**: Size, date, type information
- **Photo Gallery**: Collection displayed in grid layout

## Action Required
1. Create feature branch: `git checkout -b feature/312-photo-gallery`
2. Review spec at `specs/312-photo-gallery/spec.md`
3. Create implementation plan
4. Implement according to spec requirements

## Notes
- Requires Monica backend API endpoints at `/api/photos` and `/api/contacts/{contact}/photos`
- Photo upload via multipart/form-data
- Backend supports common image formats (JPEG, PNG, HEIC)
- Photo URLs require authentication headers
- Device camera and photo library permissions required
- Photo compression recommended for mobile upload
