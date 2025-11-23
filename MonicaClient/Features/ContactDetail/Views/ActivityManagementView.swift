import SwiftUI

struct ActivityManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var activities: [Activity] = []
    @State private var isLoading = true
    @State private var showingAddActivity = false
    @State private var editingActivity: Activity?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading activities...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(activities) { activity in
                            ActivityRow(
                                activity: activity,
                                onEdit: { editingActivity = activity },
                                onDelete: { deleteActivity(activity) }
                            )
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddActivity = true
                    }
                }
            }
        }
        .task {
            await loadActivities()
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView(contact: contact) { newActivity in
                activities.append(newActivity)
                activities.sort { $0.happenedAt ?? Date.distantPast > $1.happenedAt ?? Date.distantPast }
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingActivity) { activity in
            EditActivityView(activity: activity) { updatedActivity in
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
    private func loadActivities() async {
        guard let apiClient = authManager.currentAPIClient else { return }
        
        isLoading = true
        do {
            let response = try await apiClient.getActivities(for: contact.id, limit: 50)
            activities = response.data.sorted { $0.happenedAt ?? Date.distantPast > $1.happenedAt ?? Date.distantPast }
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
                print("✅ Deleted activity: \(activity.summary ?? "Activity")")
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

struct ActivityRow: View {
    let activity: Activity
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.summary ?? "Activity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let activityType = activity.activityType?.name {
                        Text(activityType.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                if let date = activity.happenedAt {
                    Text(date.relativeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = activity.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            
            if !activity.contacts.isEmpty {
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("with \(activity.contacts.map { $0.completeName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
}

struct AddActivityView: View {
    let contact: Contact
    let onActivityAdded: (Activity) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityTypeId = 1 // Default activity type
    @State private var summary = ""
    @State private var description = ""
    @State private var happenedAt = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    TextField("Summary", text: $summary)
                    
                    // Activity Type Picker - simplified for now
                    Picker("Type", selection: $activityTypeId) {
                        Text("Phone Call").tag(1)
                        Text("Email").tag(2)
                        Text("Meeting").tag(3)
                        Text("Note").tag(4)
                        Text("Other").tag(5)
                    }
                    
                    DatePicker("Date", selection: $happenedAt, displayedComponents: [.date, .hourAndMinute])
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
                    .disabled(summary.isEmpty || isSubmitting)
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
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            await MainActor.run { isSubmitting = true }
            
            do {
                let newActivity = try await apiClient.createActivity(
                    for: contact.id,
                    activityTypeId: activityTypeId,
                    summary: summary.isEmpty ? nil : summary,
                    description: description.isEmpty ? nil : description,
                    happenedAt: happenedAt
                )
                
                await MainActor.run {
                    onActivityAdded(newActivity)
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
    let onActivityUpdated: (Activity) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityTypeId: Int
    @State private var summary: String
    @State private var description: String
    @State private var happenedAt: Date
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    init(activity: Activity, onActivityUpdated: @escaping (Activity) -> Void) {
        self.activity = activity
        self.onActivityUpdated = onActivityUpdated
        _activityTypeId = State(initialValue: activity.activityTypeId)
        _summary = State(initialValue: activity.summary ?? "")
        _description = State(initialValue: activity.description ?? "")
        _happenedAt = State(initialValue: activity.happenedAt ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Details") {
                    TextField("Summary", text: $summary)
                    
                    // Activity Type Picker - simplified for now
                    Picker("Type", selection: $activityTypeId) {
                        Text("Phone Call").tag(1)
                        Text("Email").tag(2)
                        Text("Meeting").tag(3)
                        Text("Note").tag(4)
                        Text("Other").tag(5)
                    }
                    
                    DatePicker("Date", selection: $happenedAt, displayedComponents: [.date, .hourAndMinute])
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
                    .disabled(summary.isEmpty || isSubmitting)
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
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            await MainActor.run { isSubmitting = true }
            
            do {
                let updatedActivity = try await apiClient.updateActivity(
                    id: activity.id,
                    activityTypeId: activityTypeId,
                    summary: summary.isEmpty ? nil : summary,
                    description: description.isEmpty ? nil : description,
                    happenedAt: happenedAt
                )
                
                await MainActor.run {
                    onActivityUpdated(updatedActivity)
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

// MARK: - Extensions
extension Date {
    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
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
    
    ActivityManagementView(contact: contact)
        .environmentObject(AuthenticationManager())
}