import SwiftUI

struct NotesManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var notes: [Note] = []
    @State private var isLoading = true
    @State private var showingAddNote = false
    @State private var editingNote: Note?
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading notes...")
                } else if notes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Notes")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first note for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddNote = true }) {
                            Label("Add Note", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(notes) { note in
                            NoteRowView(note: note, onEdit: {
                                editingNote = note
                            }, onDelete: {
                                deleteNote(note)
                            })
                        }
                    }
                    .refreshable {
                        await loadNotes()
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !notes.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddNote = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadNotes()
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(contact: contact) { newNote in
                notes.insert(newNote, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingNote) { note in
            EditNoteView(note: note) { updatedNote in
                if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                    notes[index] = updatedNote
                }
            }
            .environmentObject(authManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @MainActor
    private func loadNotes() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getNotes(for: contact.id, limit: 100)
            notes = response.data.sorted { $0.createdAt > $1.createdAt }
            print("✅ Loaded \(notes.count) notes")
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load notes: \(error)")
        }
        isLoading = false
    }

    private func deleteNote(_ note: Note) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteNote(id: note.id)
                await MainActor.run {
                    notes.removeAll { $0.id == note.id }
                }
                print("✅ Deleted note")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete note: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete note: \(error)")
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let title = note.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Untitled Note")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .italic()
                }

                Spacer()

                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }

                Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(note.body)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct AddNoteView: View {
    let contact: Contact
    let onNoteAdded: (Note) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var body = ""
    @State private var isFavorite = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    TextField("Title (optional)", text: $title)

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Content") {
                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitNote()
                    }
                    .disabled(body.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitNote() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                // Create Note object with placeholder data
                let noteToCreate = Note(
                    id: 0, // Will be assigned by server
                    contactId: contact.id,
                    title: title.isEmpty ? nil : title,
                    body: body,
                    isFavorite: isFavorite,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                let response = try await apiClient.createNote(for: contact.id, note: noteToCreate)

                await MainActor.run {
                    onNoteAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create note: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditNoteView: View {
    let note: Note
    let onNoteUpdated: (Note) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var body: String
    @State private var isFavorite: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(note: Note, onNoteUpdated: @escaping (Note) -> Void) {
        self.note = note
        self.onNoteUpdated = onNoteUpdated
        _title = State(initialValue: note.title ?? "")
        _body = State(initialValue: note.body)
        _isFavorite = State(initialValue: note.isFavorite)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    TextField("Title (optional)", text: $title)

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Content") {
                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitNote()
                    }
                    .disabled(body.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitNote() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                // Create updated Note object
                let updatedNote = Note(
                    id: note.id,
                    contactId: note.contactId,
                    title: title.isEmpty ? nil : title,
                    body: body,
                    isFavorite: isFavorite,
                    createdAt: note.createdAt,
                    updatedAt: Date()
                )

                let response = try await apiClient.updateNote(updatedNote)

                await MainActor.run {
                    onNoteUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update note: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    let contact = Contact(
        id: 1,
        uuid: "test",
        object: "contact",
        hashId: "test",
        firstName: "John",
        lastName: "Doe",
        nickname: nil,
        completeName: "John Doe",
        initials: "JD",
        description: nil,
        gender: nil,
        genderType: nil,
        isStarred: false,
        isPartial: false,
        isActive: true,
        isDead: false,
        isMe: false,
        lastCalled: nil,
        lastActivityTogether: nil,
        stayInTouchFrequency: nil,
        stayInTouchTriggerDate: nil,
        email: "john@example.com",
        phone: "+1234567890",
        birthdate: nil,
        address: "123 Main St",
        company: "ACME Corp",
        jobTitle: "Developer",
        notes: "Test notes",
        relationships: nil,
        information: nil,
        addresses: nil,
        tags: nil,
        statistics: nil,
        url: "test",
        account: Account(id: 1),
        createdAt: Date(),
        updatedAt: Date()
    )

    NotesManagementView(contact: contact)
        .environmentObject(AuthenticationManager())
}
