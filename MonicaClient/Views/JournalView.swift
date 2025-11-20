import SwiftUI

/// Represents an item in the unified journal feed
enum JournalItem: Identifiable {
    case manualEntry(JournalEntry)
    case activity(Activity)

    var id: String {
        switch self {
        case .manualEntry(let entry):
            return "entry-\(entry.id)"
        case .activity(let activity):
            return "activity-\(activity.id)"
        }
    }

    var date: Date {
        switch self {
        case .manualEntry(let entry):
            return entry.createdAt
        case .activity(let activity):
            return activity.happenedAt ?? activity.createdAt
        }
    }

    var isManualEntry: Bool {
        if case .manualEntry = self {
            return true
        }
        return false
    }
}

struct JournalView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var journalItems: [JournalItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewEntry = false
    @State private var showingInfo = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && journalItems.isEmpty {
                    ProgressView("Loading journal...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading journal")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadJournalItems()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if journalItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No journal entries yet")
                            .font(.headline)
                        Text("Start documenting your thoughts and experiences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingNewEntry = true
                        } label: {
                            Label("New Entry", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Info banner
                        if showingInfo {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("The journal lists both manual journal entries and automatic entries like Activities done with your contacts. While you can delete journal entries manually, you'll have to delete the activity directly on the contact page.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    withAnimation {
                                        showingInfo = false
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                        }

                        List {
                            ForEach(journalItems) { item in
                                switch item {
                                case .manualEntry(let entry):
                                    NavigationLink(destination: JournalEntryDetailView(entry: entry, onUpdate: { updated in
                                        if let index = journalItems.firstIndex(where: { $0.id == item.id }) {
                                            journalItems[index] = .manualEntry(updated)
                                        }
                                    }, onDelete: {
                                        journalItems.removeAll { $0.id == item.id }
                                    })) {
                                        JournalEntryRow(entry: entry)
                                    }
                                case .activity(let activity):
                                    ActivityJournalRow(activity: activity)
                                }
                            }
                        }
                        .refreshable {
                            await loadJournalItems()
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            showingInfo.toggle()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewJournalEntryView(onSave: { newEntry in
                    // Insert at the correct position based on date
                    let newItem = JournalItem.manualEntry(newEntry)
                    if let insertIndex = journalItems.firstIndex(where: { $0.date < newEntry.createdAt }) {
                        journalItems.insert(newItem, at: insertIndex)
                    } else {
                        journalItems.append(newItem)
                    }
                    showingNewEntry = false
                })
                .environmentObject(authManager)
            }
            .task {
                await loadJournalItems()
            }
        }
    }

    private func loadJournalItems() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        // Convert to unified JournalItem array
        var items: [JournalItem] = []

        // Fetch journal entries - this is required
        do {
            let entriesResponse = try await apiClient.fetchJournalEntries(page: 1, limit: 100)
            for entry in entriesResponse.data {
                items.append(.manualEntry(entry))
            }
            print("✅ Loaded \(entriesResponse.data.count) journal entries")
        } catch {
            errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
            print("❌ Failed to load journal entries: \(error)")
            isLoading = false
            return
        }

        // Fetch activities - this is optional, some servers may not support it
        do {
            let activitiesResponse = try await apiClient.fetchActivities(page: 1, limit: 100)
            for activity in activitiesResponse.data {
                items.append(.activity(activity))
            }
            print("✅ Loaded \(activitiesResponse.data.count) activities")
        } catch {
            // Activities endpoint may not be supported on this server version
            print("⚠️ Could not load activities (endpoint may not be supported): \(error)")
        }

        // Sort by date (most recent first)
        items.sort { $0.date > $1.date }

        journalItems = items
        isLoading = false
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pencil.and.scribble")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Journal Entry")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }

            Text(entry.title)
                .font(.headline)

            Text(entry.post)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if entry.createdAt != entry.updatedAt {
                    Text("• Edited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityJournalRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Activity")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }

            if let summary = activity.summary, !summary.isEmpty {
                Text(summary)
                    .font(.headline)
            } else if let activityType = activity.activityType {
                Text(activityType.name)
                    .font(.headline)
            } else {
                Text("Activity")
                    .font(.headline)
            }

            if let description = activity.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let happenedAt = activity.happenedAt {
                    Text(happenedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(activity.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !activity.safeContacts.isEmpty {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(activity.safeContacts.map { $0.completeName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewJournalEntryView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var post = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onSave: (JournalEntry) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    TextEditor(text: $post)
                        .frame(minHeight: 200)
                } header: {
                    Text("Entry")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await saveEntry()
                            }
                        }
                        .disabled(title.isEmpty || post.isEmpty)
                    }
                }
            }
        }
    }

    private func saveEntry() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        guard !title.isEmpty, !post.isEmpty else {
            errorMessage = "Title and entry are required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let newEntry = try await apiClient.createJournalEntry(title: title, post: post)
            print("✅ Created journal entry: \(newEntry.title)")
            onSave(newEntry)
            dismiss()
        } catch {
            errorMessage = "Failed to create entry: \(error.localizedDescription)"
            print("❌ Failed to create journal entry: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    JournalView()
        .environmentObject(AuthenticationManager())
}
