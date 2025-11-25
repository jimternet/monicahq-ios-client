import SwiftUI

/// Row view for displaying a single call log entry
struct CallLogRowView: View {
    let callLog: CallLogEntity
    let viewModel: CallLogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Date and sync status
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.blue)
                    .font(.caption)

                Text(viewModel.formatDate(callLog.calledAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Sync status indicator
                syncStatusBadge
            }

            // Duration and emotion (if available)
            if callLog.duration > 0 || callLog.emotion != nil {
                HStack(spacing: 12) {
                    if callLog.duration > 0 {
                        Label(viewModel.formatDuration(callLog.duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let emotion = callLog.emotion {
                        HStack(spacing: 4) {
                            Text(emotion.emoji)
                            Text(emotion.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(emotionColor(for: emotion).opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }

            // Notes preview (if available)
            if let notes = callLog.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sync Status Badge

    @ViewBuilder
    private var syncStatusBadge: some View {
        if callLog.needsSync {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
                .font(.caption2)
        } else if callLog.isSyncing {
            ProgressView()
                .scaleEffect(0.7)
        } else if callLog.isSynced {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption2)
        } else if callLog.syncStatus == "failed" {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption2)
        }
    }

    // MARK: - Helper Methods

    /// Get color for emotion badge
    private func emotionColor(for emotion: EmotionalState) -> Color {
        switch emotion {
        case .happy:
            return .green
        case .excited:
            return .orange
        case .neutral:
            return .gray
        case .sad:
            return .blue
        case .frustrated:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    let dataController = DataController(authManager: AuthenticationManager())
    let context = dataController.container.viewContext

    // Create sample call log
    let callLog = CallLogEntity(context: context)
    callLog.id = 1
    callLog.contactId = 1
    callLog.calledAt = Date()
    callLog.duration = 45
    callLog.setEmotion(.happy)
    callLog.notes = "Had a great conversation about the project. They're excited about the progress!"
    callLog.syncStatus = "synced"
    callLog.createdAt = Date()
    callLog.updatedAt = Date()

    let storage = CallLogStorage(dataController: dataController)
    let viewModel = CallLogViewModel(contactId: 1, storage: storage)

    return List {
        CallLogRowView(callLog: callLog, viewModel: viewModel)
    }
}
