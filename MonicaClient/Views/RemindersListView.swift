import SwiftUI

struct RemindersListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var reminders: [Reminder] = []
    // TODO: Re-enable when NotificationManager is implemented
    // @StateObject private var notificationManager = NotificationManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewReminder = false
    @State private var selectedFilter: ReminderFilter = .upcoming
    @State private var showingNotificationSettings = false

    enum ReminderFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case all = "All"
        case overdue = "Overdue"
    }

    var filteredReminders: [Reminder] {
        switch selectedFilter {
        case .upcoming:
            return reminders.filter { $0.isDueSoon || ($0.daysUntilDue ?? 0) >= 0 }
                .sorted { ($0.nextExpectedDate ?? $0.initialDate) < ($1.nextExpectedDate ?? $1.initialDate) }
        case .overdue:
            return reminders.filter { $0.isOverdue }
                .sorted { ($0.nextExpectedDate ?? $0.initialDate) < ($1.nextExpectedDate ?? $1.initialDate) }
        case .all:
            return reminders.sorted { ($0.nextExpectedDate ?? $0.initialDate) < ($1.nextExpectedDate ?? $1.initialDate) }
        }
    }

    var overdueCount: Int {
        reminders.filter { $0.isOverdue }.count
    }

    var upcomingThisWeekCount: Int {
        reminders.filter { $0.isDueSoon && !$0.isOverdue }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && reminders.isEmpty {
                    ProgressView("Loading reminders...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Error loading reminders")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadReminders()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if reminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No reminders yet")
                            .font(.headline)
                        Text("Create reminders to stay on top of important dates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Summary cards
                        HStack(spacing: 12) {
                            SummaryCard(
                                title: "Overdue",
                                count: overdueCount,
                                color: .red,
                                icon: "exclamationmark.circle"
                            )
                            SummaryCard(
                                title: "This Week",
                                count: upcomingThisWeekCount,
                                color: .orange,
                                icon: "calendar.badge.clock"
                            )
                            SummaryCard(
                                title: "Total",
                                count: reminders.count,
                                color: .blue,
                                icon: "bell"
                            )
                        }
                        .padding()

                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(ReminderFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Reminders list
                        List {
                            ForEach(filteredReminders) { reminder in
                                ReminderRow(reminder: reminder, onDelete: {
                                    Task {
                                        await deleteReminder(reminder)
                                    }
                                })
                            }
                        }
                        .refreshable {
                            await loadReminders()
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewReminder) {
                AddReminderView(onSave: { newReminder in
                    reminders.append(newReminder)
                    showingNewReminder = false
                })
                .environmentObject(authManager)
            }
            .task {
                await loadReminders()
            }
        }
    }

    private func loadReminders() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.fetchReminders(page: 1, limit: 100)
            reminders = response.data
            print("✅ Loaded \(reminders.count) reminders")

            // Schedule notifications for upcoming reminders
            // TODO: Re-enable when NotificationManager is implemented
            // await notificationManager.scheduleUpcomingNotifications(for: reminders)
        } catch {
            errorMessage = "Failed to load reminders: \(error.localizedDescription)"
            print("❌ Failed to load reminders: \(error)")
        }

        isLoading = false
    }

    private func deleteReminder(_ reminder: Reminder) async {
        guard let apiClient = authManager.currentAPIClient else { return }

        do {
            try await apiClient.deleteReminder(id: reminder.id)
            // TODO: Re-enable when NotificationManager is implemented
            // await notificationManager.cancelNotification(for: reminder)
            reminders.removeAll { $0.id == reminder.id }
        } catch {
            print("❌ Failed to delete reminder: \(error)")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: reminder.icon)
                .font(.title2)
                .foregroundColor(reminder.isOverdue ? .red : (reminder.isDueSoon ? .orange : .blue))
                .frame(width: 40)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)

                if let contact = reminder.contact {
                    Text(contact.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(reminder.dueDateDescription)
                        .font(.caption)
                        .foregroundColor(reminder.isOverdue ? .red : (reminder.isDueSoon ? .orange : .secondary))
                        .fontWeight(reminder.isOverdue || reminder.isDueSoon ? .semibold : .regular)

                    if reminder.isRecurring {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(reminder.frequencyDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Due date badge
            if let nextDate = reminder.nextExpectedDate {
                VStack {
                    Text(nextDate, format: .dateTime.month(.abbreviated))
                        .font(.caption2)
                        .textCase(.uppercase)
                    Text(nextDate, format: .dateTime.day())
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(reminder.isOverdue ? .red : (reminder.isDueSoon ? .orange : .primary))
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if reminder.delible != false {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Reminder", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(reminder.title)'?")
        }
    }
}

// Placeholder for AddReminderView - will implement next
struct AddReminderView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var frequencyType: ReminderFrequency = .year
    @State private var description = ""
    @State private var selectedContact: Contact?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingContactPicker = false
    @State private var contacts: [Contact] = []
    @State private var isLoadingContacts = false

    let onSave: (Reminder) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("What to remember")
                }

                Section {
                    Button {
                        showingContactPicker = true
                    } label: {
                        HStack {
                            Text("Contact")
                                .foregroundColor(.primary)
                            Spacer()
                            if let contact = selectedContact {
                                Text(contact.completeName)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select...")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Associated Contact")
                }

                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)

                    Picker("Frequency", selection: $frequencyType) {
                        ForEach(ReminderFrequency.allCases, id: \.self) { freq in
                            Label(freq.displayName, systemImage: freq.icon)
                                .tag(freq)
                        }
                    }
                } header: {
                    Text("When")
                }

                Section {
                    TextField("Notes (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Additional Notes")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Reminder")
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
                                await saveReminder()
                            }
                        }
                        .disabled(title.isEmpty || selectedContact == nil)
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(contacts: contacts, isLoading: isLoadingContacts, selectedContact: $selectedContact)
            }
            .task {
                await loadContacts()
            }
        }
    }

    private func loadContacts() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoadingContacts = true
        do {
            contacts = try await apiClient.fetchAllContacts()
        } catch {
            print("❌ Failed to load contacts for picker: \(error)")
        }
        isLoadingContacts = false
    }

    private func saveReminder() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            return
        }

        guard !title.isEmpty else {
            errorMessage = "Title is required"
            return
        }

        guard let contact = selectedContact else {
            errorMessage = "Please select a contact"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let newReminder = try await apiClient.createReminder(
                contactId: contact.id,
                title: title,
                initialDate: selectedDate,
                frequencyType: frequencyType.rawValue,
                frequencyNumber: 1,
                description: description.isEmpty ? nil : description
            )

            // Schedule notification for the new reminder
            // TODO: Re-enable when NotificationManager is implemented
            // try? await NotificationManager.shared.scheduleNotification(for: newReminder)
            onSave(newReminder)
        } catch {
            errorMessage = "Failed to create reminder: \(error.localizedDescription)"
            print("❌ Failed to create reminder: \(error)")
        }

        isSaving = false
    }
}

struct ContactPickerView: View {
    let contacts: [Contact]
    let isLoading: Bool
    @Binding var selectedContact: Contact?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.completeName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading contacts...")
                } else {
                    List(filteredContacts) { contact in
                        Button {
                            selectedContact = contact
                            dismiss()
                        } label: {
                            HStack {
                                Text(contact.completeName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedContact?.id == contact.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search contacts")
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RemindersListView()
        .environmentObject(AuthenticationManager())
}
