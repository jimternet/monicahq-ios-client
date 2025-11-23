import SwiftUI

/// Timeline view for displaying contact activities chronologically
struct ActivityTimelineView: View {
    let activities: [Activity]
    let onLoadMore: (() -> Void)?
    let hasMoreActivities: Bool
    let isLoadingMore: Bool
    
    @State private var isExpanded = true
    
    init(
        activities: [Activity],
        onLoadMore: (() -> Void)? = nil,
        hasMoreActivities: Bool = false,
        isLoadingMore: Bool = false
    ) {
        self.activities = activities
        self.onLoadMore = onLoadMore
        self.hasMoreActivities = hasMoreActivities
        self.isLoadingMore = isLoadingMore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: Constants.UI.Animation.defaultDuration)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.monicaBlue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Activities")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text("(\(activities.count))")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.tertiaryText)
                        .font(.system(size: 12, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: Constants.UI.Animation.fastDuration), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: Constants.UI.Spacing.small) {
                    if activities.isEmpty {
                        emptyStateView
                    } else {
                        timelineContent
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.medium)
    }
    
    @ViewBuilder
    private var timelineContent: some View {
        LazyVStack(spacing: Constants.UI.Spacing.small) {
            ForEach(sortedActivities, id: \.id) { activity in
                ActivityTimelineRow(activity: activity)
                    .id(activity.id)
            }
            
            // Load More Button
            if hasMoreActivities {
                LoadMoreButton(isLoading: isLoadingMore, onLoadMore: onLoadMore)
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 24))
                .foregroundColor(.tertiaryText)
            
            Text("No Activities")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
            
            Text("Activities will appear here when they're added to this contact.")
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.UI.Spacing.large)
        .frame(maxWidth: .infinity)
    }
    
    private var sortedActivities: [Activity] {
        activities.sorted { activity1, activity2 in
            // Sort by date, most recent first
            if let date1 = activity1.happenedAt, let date2 = activity2.happenedAt {
                return date1 > date2
            }
            // If dates are equal or nil, sort by ID (assuming higher ID = more recent)
            return activity1.id > activity2.id
        }
    }
}

/// Individual activity row in the timeline
struct ActivityTimelineRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: Constants.UI.Spacing.medium) {
            // Timeline indicator
            VStack {
                activityIcon
                    .frame(width: 28, height: 28)
                    .background(activityColor.opacity(0.1))
                    .cornerRadius(14)
                
                // Timeline line (except for last item)
                Rectangle()
                    .fill(Color.tertiaryBackground)
                    .frame(width: 2)
                    .frame(minHeight: 20)
            }
            
            // Activity content
            VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                HStack {
                    Text(activity.summary ?? "Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if let date = activity.happenedAt {
                        Text(date.relativeString())
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                    }
                }
                
                if let description = activity.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Related contacts or additional info
                if !activity.contacts.isEmpty {
                    RelatedContactsRow(contacts: Array(activity.contacts.prefix(3)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Constants.UI.Spacing.small)
    }
    
    private var activityIcon: some View {
        Image(systemName: activityTypeIcon)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(activityColor)
    }
    
    private var activityTypeIcon: String {
        // Map activity types to appropriate icons
        guard let type = activity.activityType?.name?.lowercased() else {
            return "calendar"
        }
        
        switch type {
        case let t where t.contains("call"):
            return "phone.fill"
        case let t where t.contains("email"):
            return "envelope.fill"
        case let t where t.contains("meeting"):
            return "person.2.fill"
        case let t where t.contains("note"):
            return "note.text"
        case let t where t.contains("gift"):
            return "gift.fill"
        case let t where t.contains("conversation"):
            return "bubble.left.and.bubble.right.fill"
        default:
            return "calendar"
        }
    }
    
    private var activityColor: Color {
        guard let type = activity.activityType?.name?.lowercased() else {
            return .monicaBlue
        }
        
        switch type {
        case let t where t.contains("call"):
            return .monicaGreen
        case let t where t.contains("email"):
            return .monicaOrange
        case let t where t.contains("meeting"):
            return .monicaBlue
        case let t where t.contains("gift"):
            return .monicaRed
        default:
            return .monicaBlue
        }
    }
}

/// Row showing related contacts for an activity
struct RelatedContactsRow: View {
    let contacts: [ActivityContact]
    
    var body: some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            Image(systemName: "person.2")
                .font(.caption2)
                .foregroundColor(.tertiaryText)
            
            Text("with")
                .font(.caption2)
                .foregroundColor(.tertiaryText)
            
            HStack(spacing: 4) {
                ForEach(contacts.indices, id: \.self) { index in
                    Text(contacts[index].completeName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.monicaBlue)
                    
                    if index < contacts.count - 1 {
                        Text(",")
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                    }
                }
            }
            
            if contacts.count < 3 {
                // Show additional count if there are more contacts
                Text("+\(max(0, contacts.count - 3))")
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
            }
        }
    }
}

/// Load more button for pagination
struct LoadMoreButton: View {
    let isLoading: Bool
    let onLoadMore: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onLoadMore?()
        }) {
            HStack(spacing: Constants.UI.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .monicaBlue))
                        .scaleEffect(0.8)
                    
                    Text("Loading...")
                } else {
                    Image(systemName: "arrow.down.circle")
                    Text("Load More Activities")
                }
            }
            .font(.caption)
            .foregroundColor(.monicaBlue)
            .padding(.vertical, Constants.UI.Spacing.small)
            .frame(maxWidth: .infinity)
            .background(Color.monicaBlue.opacity(0.1))
            .cornerRadius(Constants.UI.CornerRadius.small)
        }
        .disabled(isLoading)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Constants.UI.Spacing.medium) {
            ActivityTimelineView(
                activities: Activity.mockActivities,
                hasMoreActivities: true,
                isLoadingMore: false
            )
        }
        .padding()
    }
    .background(Color.primaryBackground)
}

// MARK: - Extensions for Preview
extension Activity {
    static var mockActivities: [Activity] {
        [
            Activity(
                id: 1,
                summary: "Called to discuss vacation plans",
                description: "Had a great conversation about the upcoming summer vacation. Discussed potential destinations and dates.",
                happenedAt: Date().addingTimeInterval(-86400), // 1 day ago
                activityType: ActivityType(id: 1, name: "phone_call"),
                contacts: [
                    ActivityContact(id: 1, firstName: "John", lastName: "Doe")
                ]
            ),
            Activity(
                id: 2,
                summary: "Birthday dinner",
                description: "Celebrated birthday at their favorite restaurant downtown.",
                happenedAt: Date().addingTimeInterval(-172800), // 2 days ago
                activityType: ActivityType(id: 2, name: "activity"),
                contacts: []
            ),
            Activity(
                id: 3,
                summary: "Email about work project",
                description: nil,
                happenedAt: Date().addingTimeInterval(-259200), // 3 days ago
                activityType: ActivityType(id: 3, name: "email"),
                contacts: []
            )
        ]
    }
}