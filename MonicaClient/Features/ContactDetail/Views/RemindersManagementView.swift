import SwiftUI

struct RemindersManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var reminders: [Reminder] = []
    @State private var isLoading = true
    @State private var showingAddReminder = false
    @State private var editingReminder: Reminder?
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading reminders...")
                } else if reminders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Reminders")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first reminder for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddReminder = true }) {
                            Label("Add Reminder", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(reminders) { reminder in
                            ReminderRowView(reminder: reminder, onEdit: {
                                editingReminder = reminder
                            }, onDelete: {
                                deleteReminder(reminder)
                            })
                        }
                    }
                    .refreshable {
                        await loadReminders()
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !reminders.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddReminder = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadReminders()
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(contact: contact) { newReminder in
                reminders.insert(newReminder, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingReminder) { reminder in
            EditReminderView(reminder: reminder) { updatedReminder in
                if let index = reminders.firstIndex(where: { $0.id == updatedReminder.id }) {
                    reminders[index] = updatedReminder
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
    private func loadReminders() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getReminders(for: contact.id, limit: 100)
            reminders = response.data.sorted { $0.nextExpectedDate > $1.nextExpectedDate }
            print("✅ Loaded \(reminders.count) reminders")
        } catch {
            errorMessage = "Failed to load reminders: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load reminders: \(error)")
        }
        isLoading = false
    }

    private func deleteReminder(_ reminder: Reminder) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteReminder(id: reminder.id)
                await MainActor.run {
                    reminders.removeAll { $0.id == reminder.id }
                }
                print("✅ Deleted reminder")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete reminder: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete reminder: \(error)")
            }
        }
    }
}

struct ReminderRowView: View {
    let reminder: Reminder
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(reminder.nextExpectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .secondary)
            }

            if let description = reminder.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("Frequency: \(reminder.frequencyType)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isOverdue {
                    Spacer()
                    Text("Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
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

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private var isOverdue: Bool {
        reminder.nextExpectedDate < Date()
    }
}

struct AddReminderView: View {
    let contact: Contact
    let onReminderAdded: (Reminder) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var nextExpectedDate = Date()
    @State private var frequency = "one_time"
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    let frequencies = [
        ("one_time", "One Time"),
        ("week", "Weekly"),
        ("month", "Monthly"),
        ("year", "Yearly")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)

                    DatePicker("Date", selection: $nextExpectedDate, displayedComponents: .date)

                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.0) { freq in
                            Text(freq.1).tag(freq.0)
                        }
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitReminder()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitReminder() {
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createReminder(
                    contactId: contact.id,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    initialDate: nextExpectedDate,
                    frequencyType: frequency
                )

                await MainActor.run {
                    onReminderAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create reminder: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditReminderView: View {
    let reminder: Reminder
    let onReminderUpdated: (Reminder) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var description: String
    @State private var nextExpectedDate: Date
    @State private var frequency: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    let frequencies = [
        ("one_time", "One Time"),
        ("week", "Weekly"),
        ("month", "Monthly"),
        ("year", "Yearly")
    ]

    init(reminder: Reminder, onReminderUpdated: @escaping (Reminder) -> Void) {
        self.reminder = reminder
        self.onReminderUpdated = onReminderUpdated
        _title = State(initialValue: reminder.title)
        _description = State(initialValue: reminder.description ?? "")
        _nextExpectedDate = State(initialValue: reminder.nextExpectedDate)
        _frequency = State(initialValue: reminder.frequencyType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)

                    DatePicker("Date", selection: $nextExpectedDate, displayedComponents: .date)

                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.0) { freq in
                            Text(freq.1).tag(freq.0)
                        }
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitReminder()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitReminder() {
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.updateReminder(
                    id: reminder.id,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    nextExpectedDate: nextExpectedDate,
                    frequencyType: frequency
                )

                await MainActor.run {
                    onReminderUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update reminder: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
