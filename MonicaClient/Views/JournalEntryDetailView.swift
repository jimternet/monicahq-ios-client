import SwiftUI

struct JournalEntryDetailView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var entry: JournalEntry
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editPost = ""
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false

    let onUpdate: (JournalEntry) -> Void
    let onDelete: () -> Void

    init(entry: JournalEntry, onUpdate: @escaping (JournalEntry) -> Void, onDelete: @escaping () -> Void) {
        self._entry = State(initialValue: entry)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    // Edit mode
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Title", text: $editTitle)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.words)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entry")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $editPost)
                                .frame(minHeight: 300)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                } else {
                    // View mode
                    VStack(alignment: .leading, spacing: 16) {
                        Text(entry.title)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            Label(entry.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if entry.createdAt != entry.updatedAt {
                                Label("Edited \(entry.updatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        Text(entry.post)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .disabled(isSaving)

                        if isSaving {
                            ProgressView()
                        } else {
                            Button("Save") {
                                Task {
                                    await saveChanges()
                                }
                            }
                            .disabled(editTitle.isEmpty || editPost.isEmpty)
                        }
                    }
                } else {
                    Menu {
                        Button {
                            startEditing()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteEntry()
                }
            }
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
    }

    private func startEditing() {
        editTitle = entry.title
        editPost = entry.post
        errorMessage = nil
        isEditing = true
    }

    private func cancelEditing() {
        editTitle = ""
        editPost = ""
        errorMessage = nil
        isEditing = false
    }

    private func saveChanges() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        guard !editTitle.isEmpty, !editPost.isEmpty else {
            errorMessage = "Title and entry are required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let updatedEntry = try await apiClient.updateJournalEntry(
                id: entry.id,
                title: editTitle,
                post: editPost
            )
            print("✅ Updated journal entry: \(updatedEntry.title)")
            entry = updatedEntry
            onUpdate(updatedEntry)
            isEditing = false
        } catch {
            errorMessage = "Failed to update entry: \(error.localizedDescription)"
            print("❌ Failed to update journal entry: \(error)")
        }

        isSaving = false
    }

    private func deleteEntry() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        isDeleting = true

        do {
            try await apiClient.deleteJournalEntry(id: entry.id)
            print("✅ Deleted journal entry: \(entry.title)")
            onDelete()
            dismiss()
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
            print("❌ Failed to delete journal entry: \(error)")
        }

        isDeleting = false
    }
}

#Preview {
    NavigationView {
        JournalEntryDetailView(
            entry: JournalEntry(
                id: 1,
                object: "journalentry",
                title: "Sample Entry",
                post: "This is a sample journal entry for preview purposes.",
                account: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            onUpdate: { _ in },
            onDelete: { }
        )
        .environmentObject(AuthenticationManager())
    }
}
