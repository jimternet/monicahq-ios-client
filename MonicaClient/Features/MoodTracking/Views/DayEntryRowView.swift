import SwiftUI

/// Row view for displaying a day entry (mood rating) in the journal feed
struct DayEntryRowView: View {
    let dayEntry: DayEntry

    var body: some View {
        HStack(spacing: 12) {
            // Mood color indicator bar
            RoundedRectangle(cornerRadius: 4)
                .fill(dayEntry.moodColor)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 8) {
                // Type label header with large emoji
                HStack {
                    Text(dayEntry.moodEmoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundColor(dayEntry.moodColor)
                                .font(.caption)
                            Text("Day Rating")
                                .font(.caption)
                                .foregroundColor(dayEntry.moodColor)
                                .fontWeight(.semibold)
                        }
                        // Mood description below label
                        Text(dayEntry.moodDescription)
                            .font(.headline)
                    }
                }

                // Optional comment preview (first 100 chars)
                if let comment = dayEntry.comment, !comment.isEmpty {
                    Text(commentPreview(comment))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Date and edit indicator
                HStack {
                    Text(dayEntry.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if dayEntry.wasEdited {
                        Text("• Edited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dayEntry.moodColor.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Returns first 100 characters of comment with ellipsis if truncated
    private func commentPreview(_ comment: String) -> String {
        if comment.count <= 100 {
            return comment
        }
        return String(comment.prefix(100)) + "..."
    }

    /// Accessibility description for VoiceOver
    private var accessibilityDescription: String {
        var description = "\(dayEntry.moodDescription) on \(dayEntry.formattedDate)"
        if let comment = dayEntry.comment, !comment.isEmpty {
            description += ". Comment: \(comment)"
        }
        if dayEntry.wasEdited {
            description += ". This entry has been edited."
        }
        return description
    }
}

#Preview("Great Day") {
    List {
        DayEntryRowView(dayEntry: DayEntry(
            id: 1,
            rate: 3,
            comment: "Had an amazing productive day! Finished all my tasks and even had time for a nice walk in the park. Feeling grateful for the good weather.",
            date: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}

#Preview("Bad Day, No Comment") {
    List {
        DayEntryRowView(dayEntry: DayEntry(
            id: 2,
            rate: 1,
            comment: nil,
            date: Date().addingTimeInterval(-86400),
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86400)
        ))
    }
}

#Preview("Okay Day, Edited") {
    List {
        DayEntryRowView(dayEntry: DayEntry(
            id: 3,
            rate: 2,
            comment: "Just a regular day",
            date: Date().addingTimeInterval(-172800),
            createdAt: Date().addingTimeInterval(-172800),
            updatedAt: Date()
        ))
    }
}
