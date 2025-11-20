# Feature Request: Documents & Files Management

## Overview
Attach documents and files to contacts - PDFs, receipts, contracts, important papers associated with each person.

## API Endpoints Available
From Monica v4.x `/routes/api.php`:
- `GET /api/documents` - List all documents
- `GET /api/documents/{id}` - Get single document
- `POST /api/documents` - Upload document
- `DELETE /api/documents/{id}` - Delete document
- `GET /api/contacts/{contact}/documents` - Get documents for specific contact

## Proposed Models

```swift
struct Document: Codable, Identifiable {
    let id: Int
    let contactId: Int
    let originalFilename: String
    let newFilename: String
    let filesize: Int
    let type: String // MIME type
    let numberOfDownloads: Int
    let link: String // URL to download
    let contact: Contact?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case originalFilename = "original_filename"
        case newFilename = "new_filename"
        case filesize
        case type
        case numberOfDownloads = "number_of_downloads"
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

    var fileExtension: String {
        return (originalFilename as NSString).pathExtension.uppercased()
    }

    var icon: String {
        switch fileExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "jpg", "jpeg", "png", "gif": return "photo"
        case "txt": return "doc.plaintext"
        default: return "doc"
        }
    }
}
```

## UI Components Needed

### 1. ContactDocumentsSection
- List of documents for contact
- File type icons
- File name and size
- Upload date
- Quick preview/open action
- Add document button

### 2. DocumentListItem
- File type icon (PDF, Word, etc.)
- Original filename
- File size
- Upload date
- Tap to preview/download

### 3. AddDocumentView
- Document picker (Files app integration)
- Camera scan for physical documents
- Name/description field (optional)
- Select contact (if from global view)

### 4. DocumentPreviewView
- Quick Look preview for supported types
- Download progress indicator
- Share/export options
- Open in external app
- Delete option

### 5. GlobalDocumentsView (Optional)
- All documents across contacts
- Search by filename
- Filter by type
- Sort by date/size

## Implementation Priority
**LOW-MEDIUM** - Useful for organization but less frequently used than other features

## Key Features
1. File upload from Files app
2. Document scanning from camera
3. Preview supported file types
4. Download to device
5. Share/export documents
6. File type categorization
7. Search by filename

## iOS Integration
- UIDocumentPickerViewController for file selection
- VNDocumentCameraViewController for scanning
- QLPreviewController for document preview
- FileManager for local storage
- Background downloads
- Share sheet integration

## Technical Implementation

### Document Picker
```swift
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, .image])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURL = urls.first
        }
    }
}
```

### Upload Function
```swift
func uploadDocument(contactId: Int, fileURL: URL) async throws -> Document {
    let data = try Data(contentsOf: fileURL)
    let filename = fileURL.lastPathComponent
    let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"

    // Multipart form upload similar to photos
    // ...
}
```

## Visual Design
- File type icons (PDF red, Word blue, etc.)
- List view with metadata
- Clear action buttons
- Download progress indicator
- Offline availability badge
- File size warnings for large files

## Use Cases
- Store contracts and agreements
- Keep receipts and invoices
- Medical records
- Legal documents
- Reference materials
- Contact's resume/CV
- Shared project files

## Advanced Features (Future)
- OCR text extraction
- Full-text search in PDFs
- Document expiration reminders
- Version history
- Annotation support
- Cloud storage integration (iCloud, Dropbox)
- Encrypted storage option

## Related Files
- MonicaAPIClient.swift - Add document upload/download methods
- ContactDetailView.swift - Add documents section
- New models for Document
- DocumentCache for local storage

## Notes
- File size limits on Monica server
- Supported file types may vary
- Secure transmission required
- Consider offline access requirements
- Handle large files gracefully
- Privacy: documents may contain sensitive info
