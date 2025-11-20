import SwiftUI

struct DocumentsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var documents: [Document] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading documents...")
                } else if documents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Documents")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("No documents have been uploaded for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(documents) { document in
                            DocumentRowView(document: document, onDelete: {
                                deleteDocument(document)
                            })
                        }
                    }
                    .refreshable {
                        await loadDocuments()
                    }
                }
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadDocuments()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @MainActor
    private func loadDocuments() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getDocuments(for: contact.id)
            documents = response.data.sorted { $0.createdAt > $1.createdAt }
            print("✅ Loaded \(documents.count) documents")
        } catch {
            errorMessage = "Failed to load documents: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load documents: \(error)")
        }
        isLoading = false
    }

    private func deleteDocument(_ document: Document) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteDocument(id: document.id)
                await MainActor.run {
                    documents.removeAll { $0.id == document.id }
                }
                print("✅ Deleted document")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete document: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete document: \(error)")
            }
        }
    }
}

struct DocumentRowView: View {
    let document: Document
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: fileIcon)
                    .foregroundColor(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.originalFilename)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(formatFileSize(document.filesize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack {
                Text("Uploaded \(document.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let mimeType = document.mimeType {
                    Text(mimeType.components(separatedBy: "/").last ?? mimeType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var fileIcon: String {
        let ext = document.originalFilename.lowercased().components(separatedBy: ".").last ?? ""

        switch ext {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo"
        case "doc", "docx":
            return "doc.richtext"
        case "xls", "xlsx":
            return "tablecells"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        case "zip", "rar", "7z":
            return "doc.zipper"
        case "mp4", "mov", "avi":
            return "video"
        case "mp3", "wav", "m4a":
            return "music.note"
        default:
            return "doc"
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
