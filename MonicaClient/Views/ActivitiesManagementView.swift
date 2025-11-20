import SwiftUI

struct ActivitiesManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var activities: [Activity] = []
    @State private var activityTypes: [ActivityType] = []
    @State private var isLoading = true
    @State private var showingAddActivity = false
    @State private var editingActivity: Activity?
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading activities...")
                } else if activities.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Activities")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first activity for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddActivity = true }) {
                            Label("Add Activity", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(activities) { activity in
                            ActivityRowView(activity: activity, onEdit: {
                                editingActivity = activity
                            }, onDelete: {
                                deleteActivity(activity)
                            })
                        }
                    }
                    .refreshable {
                        await loadActivities()
                    }
                }
            }
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !activities.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddActivity = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadActivityTypes()
            await loadActivities()
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView(contact: contact, activityTypes: activityTypes) { newActivity in
                activities.insert(newActivity, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingActivity) { activity in
            EditActivityView(activity: activity, activityTypes: activityTypes) { updatedActivity in
                if let index = activities.firstIndex(where: { $0.id == updatedActivity.id }) {
                    activities[index] = updatedActivity
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
    private func loadActivityTypes() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        do {
            let response = try await apiClient.getActivityTypes()
            activityTypes = response.data
            print("✅ Loaded \(activityTypes.count) activity types")
        } catch {
            print("❌ Failed to load activity types: \(error)")
        }
    }

    @MainActor
    private func loadActivities() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getActivities(for: contact.id, limit: 100)
            activities = response.data.sorted { ($0.happenedAt ?? $0.createdAt) > ($1.happenedAt ?? $1.createdAt) }
            print("✅ Loaded \(activities.count) activities")
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load activities: \(error)")
        }
        isLoading = false
    }

    private func deleteActivity(_ activity: Activity) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteActivity(id: activity.id)
                await MainActor.run {
                    activities.removeAll { $0.id == activity.id }
                }
                print("✅ Deleted activity")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete activity: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete activity: \(error)")
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: Activity
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let activityType = activity.activityType {
                    Text(activityType.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                if let date = activity.happenedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let summary = activity.summary, !summary.isEmpty {
                Text(summary)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            if let description = activity.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if !activity.safeContacts.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(activity.safeContacts.map { $0.completeName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
}

struct AddActivityView: View {
    let contact: Contact
    let activityTypes: [ActivityType]
    let onActivityAdded: (Activity) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedActivityType: ActivityType?
    @State private var summary = ""
    @State private var description = ""
    @State private var happenedAt = Date()
    @State private var includeDate = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    Picker("Type", selection: $selectedActivityType) {
                        Text("Select type").tag(nil as ActivityType?)
                        ForEach(activityTypes) { type in
                            Text(type.name).tag(type as ActivityType?)
                        }
                    }

                    TextField("Summary (optional)", text: $summary)

                    Toggle("Include Date", isOn: $includeDate)

                    if includeDate {
                        DatePicker("Date", selection: $happenedAt, displayedComponents: .date)
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitActivity()
                    }
                    .disabled(selectedActivityType == nil || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitActivity() {
        guard let typeId = selectedActivityType?.id else { return }
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createActivity(
                    activityTypeId: typeId,
                    summary: summary.isEmpty ? nil : summary,
                    description: description.isEmpty ? nil : description,
                    happenedAt: includeDate ? happenedAt : nil,
                    contactIds: [contact.id]
                )

                await MainActor.run {
                    onActivityAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create activity: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditActivityView: View {
    let activity: Activity
    let activityTypes: [ActivityType]
    let onActivityUpdated: (Activity) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedActivityType: ActivityType?
    @State private var summary: String
    @State private var description: String
    @State private var happenedAt: Date
    @State private var includeDate: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(activity: Activity, activityTypes: [ActivityType], onActivityUpdated: @escaping (Activity) -> Void) {
        self.activity = activity
        self.activityTypes = activityTypes
        self.onActivityUpdated = onActivityUpdated
        _selectedActivityType = State(initialValue: activity.activityType)
        _summary = State(initialValue: activity.summary ?? "")
        _description = State(initialValue: activity.description ?? "")
        _happenedAt = State(initialValue: activity.happenedAt ?? Date())
        _includeDate = State(initialValue: activity.happenedAt != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    Picker("Type", selection: $selectedActivityType) {
                        Text("Select type").tag(nil as ActivityType?)
                        ForEach(activityTypes) { type in
                            Text(type.name).tag(type as ActivityType?)
                        }
                    }

                    TextField("Summary (optional)", text: $summary)

                    Toggle("Include Date", isOn: $includeDate)

                    if includeDate {
                        DatePicker("Date", selection: $happenedAt, displayedComponents: .date)
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitActivity()
                    }
                    .disabled(selectedActivityType == nil || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitActivity() {
        guard let typeId = selectedActivityType?.id else { return }
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.updateActivity(
                    id: activity.id,
                    activityTypeId: typeId,
                    summary: summary.isEmpty ? nil : summary,
                    description: description.isEmpty ? nil : description,
                    happenedAt: includeDate ? happenedAt : nil
                )

                await MainActor.run {
                    onActivityUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update activity: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
