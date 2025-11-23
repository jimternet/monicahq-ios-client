import SwiftUI

struct ActivitySection: View {
    let activities: [Activity]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    Text("Recent Activities")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("(\(activities.count))")
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
                    ForEach(activities.prefix(5), id: \.id) { activity in
                        ActivityRow(activity: activity)
                        
                        if activity.id != activities.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                    
                    if activities.count > 5 {
                        Button {
                            // TODO: Navigate to full activities list
                        } label: {
                            HStack {
                                Spacer()
                                Text("View All \(activities.count) Activities")
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
                }
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForActivityType(activity.activityType))
                .foregroundColor(colorForActivityType(activity.activityType))
                .frame(width: 20, height: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.summary)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(formatActivityDate(activity.happenedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = activity.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                if !activity.participants.isEmpty {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatParticipants(activity.participants))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding()
    }
    
    private func iconForActivityType(_ type: Activity.ActivityType) -> String {
        switch type {
        case .call:
            return "phone"
        case .meeting:
            return "person.2"
        case .email:
            return "envelope"
        case .message:
            return "message"
        case .visit:
            return "house"
        case .date:
            return "heart"
        case .gift:
            return "gift"
        case .meal:
            return "fork.knife"
        case .travel:
            return "airplane"
        case .exercise:
            return "figure.walk"
        case .other:
            return "circle"
        }
    }
    
    private func colorForActivityType(_ type: Activity.ActivityType) -> Color {
        switch type {
        case .call:
            return .blue
        case .meeting:
            return .purple
        case .email:
            return .orange
        case .message:
            return .green
        case .visit:
            return .brown
        case .date:
            return .pink
        case .gift:
            return .red
        case .meal:
            return .yellow
        case .travel:
            return .cyan
        case .exercise:
            return .mint
        case .other:
            return .gray
        }
    }
    
    private func formatActivityDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatParticipants(_ participants: [Activity.Participant]) -> String {
        if participants.count == 1 {
            return "with \(participants[0].name)"
        } else if participants.count == 2 {
            return "with \(participants[0].name) and \(participants[1].name)"
        } else {
            return "with \(participants[0].name) and \(participants.count - 1) others"
        }
    }
}

#Preview {
    let sampleActivities = [
        Activity(
            id: 1,
            summary: "Phone call about project",
            description: "Discussed upcoming deadlines and milestones for the new feature release.",
            happenedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            activityType: .call,
            participants: [
                Activity.Participant(id: 1, name: "John Doe"),
                Activity.Participant(id: 2, name: "Jane Smith")
            ],
            emotions: []
        ),
        Activity(
            id: 2,
            summary: "Coffee meeting",
            description: "Casual catch-up over coffee downtown.",
            happenedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            activityType: .meeting,
            participants: [
                Activity.Participant(id: 1, name: "Alice Johnson")
            ],
            emotions: []
        ),
        Activity(
            id: 3,
            summary: "Birthday celebration",
            description: "Celebrated at the local restaurant with family.",
            happenedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            activityType: .meal,
            participants: [],
            emotions: []
        )
    ]
    
    ActivitySection(activities: sampleActivities)
        .padding()
}