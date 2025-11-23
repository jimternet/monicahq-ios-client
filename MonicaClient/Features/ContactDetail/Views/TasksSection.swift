import SwiftUI

struct TasksSection: View {
    let tasks: [Task]
    @State private var isExpanded = true
    
    private var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.blue)
                    
                    Text("Tasks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("(\(pendingTasks.count) pending)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 0) {
                    // Pending tasks
                    if !pendingTasks.isEmpty {
                        ForEach(pendingTasks.prefix(3), id: \.id) { task in
                            TaskRow(task: task)
                            
                            if task.id != pendingTasks.prefix(3).last?.id || !completedTasks.isEmpty {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    
                    // Completed tasks (limited to 2)
                    if !completedTasks.isEmpty {
                        ForEach(completedTasks.prefix(2), id: \.id) { task in
                            TaskRow(task: task)
                            
                            if task.id != completedTasks.prefix(2).last?.id {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    
                    if tasks.count > 5 {
                        Button {
                            // TODO: Navigate to full tasks list
                        } label: {
                            HStack {
                                Spacer()
                                Text("View All \(tasks.count) Tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if tasks.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                // TODO: Handle task completion toggle
            } label: {
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
                    .lineLimit(2)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(dueDateColor(dueDate))
                            
                            Text(formatDueDate(dueDate))
                                .font(.caption)
                                .foregroundColor(dueDateColor(dueDate))
                        }
                    }
                    
                    if task.priority != .medium {
                        HStack(spacing: 4) {
                            Image(systemName: priorityIcon(task.priority))
                                .font(.caption)
                                .foregroundColor(priorityColor(task.priority))
                            
                            Text(task.priority.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(priorityColor(task.priority))
                        }
                    }
                    
                    Spacer()
                    
                    if task.isCompleted, let completedAt = task.completedAt {
                        Text("Completed \(formatCompletionDate(completedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding()
    }
    
    private func dueDateColor(_ dueDate: Date) -> Color {
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        
        if daysDifference < 0 {
            return .red // Overdue
        } else if daysDifference == 0 {
            return .orange // Due today
        } else if daysDifference <= 3 {
            return .yellow // Due soon
        } else {
            return .secondary // Future
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysDifference < 0 {
            return "Overdue"
        } else if daysDifference == 0 {
            return "Due today"
        } else if daysDifference == 1 {
            return "Due tomorrow"
        } else if daysDifference <= 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Due \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Due \(formatter.string(from: date))"
        }
    }
    
    private func formatCompletionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func priorityIcon(_ priority: TaskPriority) -> String {
        return priority.iconName
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        return priority.color
    }
}

#Preview {
    let sampleTasks = [
        Task(
            id: 1,
            contactId: 1,
            title: "Follow up on project proposal",
            description: "Send the updated proposal with revised timeline and budget estimates.",
            isCompleted: false,
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            completedAt: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        Task(
            id: 2,
            contactId: 1,
            title: "Schedule coffee meeting",
            description: "Arrange a casual catch-up meeting for next week.",
            isCompleted: false,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            completedAt: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        Task(
            id: 3,
            contactId: 1,
            title: "Send birthday card",
            description: "Remember to send a birthday card before the 15th.",
            isCompleted: true,
            priority: .low,
            dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
    ]
    
    TasksSection(tasks: sampleTasks)
        .padding()
}