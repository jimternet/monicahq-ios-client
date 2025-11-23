import SwiftUI

struct TasksManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var tasks: [MonicaTask] = []
    @State private var isLoading = true
    @State private var showingAddTask = false
    @State private var editingTask: MonicaTask?
    @State private var errorMessage: String?
    @State private var showingError = false

    var pendingTasks: [MonicaTask] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [MonicaTask] {
        tasks.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading tasks...")
                } else if tasks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Tasks")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first task for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddTask = true }) {
                            Label("Add Task", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        if !pendingTasks.isEmpty {
                            Section("Pending") {
                                ForEach(pendingTasks) { task in
                                    TaskRowView(task: task, onToggle: {
                                        toggleTaskCompletion(task)
                                    }, onEdit: {
                                        editingTask = task
                                    }, onDelete: {
                                        deleteTask(task)
                                    })
                                }
                            }
                        }

                        if !completedTasks.isEmpty {
                            Section("Completed") {
                                ForEach(completedTasks) { task in
                                    TaskRowView(task: task, onToggle: {
                                        toggleTaskCompletion(task)
                                    }, onEdit: {
                                        editingTask = task
                                    }, onDelete: {
                                        deleteTask(task)
                                    })
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadTasks()
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !tasks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadTasks()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(contact: contact) { newTask in
                tasks.insert(newTask, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task) { updatedTask in
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    tasks[index] = updatedTask
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
    private func loadTasks() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getTasks(for: contact.id, limit: 100)
            tasks = response.data.sorted { $0.createdAt > $1.createdAt }
            print("✅ Loaded \(tasks.count) tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load tasks: \(error)")
        }
        isLoading = false
    }

    private func toggleTaskCompletion(_ task: MonicaTask) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                // Monica API requires title and description when updating
                let response = try await apiClient.updateTask(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    isCompleted: !task.isCompleted
                )

                await MainActor.run {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index] = response.data
                    }
                }
                print("✅ Toggled task completion")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update task: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to toggle task: \(error)")
            }
        }
    }

    private func deleteTask(_ task: MonicaTask) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteTask(id: task.id)
                await MainActor.run {
                    tasks.removeAll { $0.id == task.id }
                }
                print("✅ Deleted task")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete task: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete task: \(error)")
            }
        }
    }
}

struct TaskRowView: View {
    let task: MonicaTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
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

struct AddTaskView: View {
    let contact: Contact
    let onTaskAdded: (MonicaTask) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitTask()
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

    private func submitTask() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createTask(
                    contactId: contact.id,
                    title: title,
                    description: description.isEmpty ? nil : description
                )

                await MainActor.run {
                    onTaskAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create task: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditTaskView: View {
    let task: MonicaTask
    let onTaskUpdated: (MonicaTask) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var description: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(task: MonicaTask, onTaskUpdated: @escaping (MonicaTask) -> Void) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitTask()
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

    private func submitTask() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.updateTask(
                    id: task.id,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    isCompleted: task.isCompleted
                )

                await MainActor.run {
                    onTaskUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update task: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
