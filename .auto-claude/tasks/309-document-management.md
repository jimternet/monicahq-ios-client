# Task: Document and File Management

## Spec Reference
- **Spec Location**: `specs/309-document-management/`
- **Feature Branch**: `309-document-management` (to be created)
- **Status**: pending

## Description
Attach documents and files to contacts - PDFs, receipts, contracts, important papers associated with each person.

This feature enables users to:
- Attach documents (PDFs, images, docs) to specific contacts
- View and organize contact documents with metadata
- Preview and download documents
- Scan physical documents via camera
- Share and delete documents

## Priority Stories
1. **P1**: Attach Documents to Contacts - Upload files to contacts
2. **P1**: View and Organize Contact Documents - List with metadata
3. **P2**: Preview and Download Documents - View and save locally
4. **P2**: Scan Physical Documents - Camera-based document capture
5. **P3**: Share and Delete Documents - Distribution and cleanup

## Key Entities
- **Document**: File attached to a contact with metadata
- **File Metadata**: Type, size, dates for display
- **Document Type**: Category based on extension/MIME type

## Action Required
1. Create feature branch: `git checkout -b feature/309-document-management`
2. Review spec at `specs/309-document-management/spec.md`
3. Create implementation plan
4. Implement according to spec requirements

## Notes
- Requires Monica backend API endpoints at `/api/documents` and `/api/contacts/{contact}/documents`
- Backend supports multipart/form-data file uploads
- Server enforces file size limits (10-50MB per file)
- Download URLs require authentication
- Device camera required for scanning feature
