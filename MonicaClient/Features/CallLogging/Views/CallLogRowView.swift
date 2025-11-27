import SwiftUI

/// Row view for displaying a single call log entry
/// Based on Monica v4.x Call API (verified) - Backend-only
struct CallLogRowView: View {
    let callLog: CallLog
    let viewModel: CallLogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Date and direction
            HStack {
                Image(systemName: CallDirection(contactCalled: callLog.contactCalled).icon)
                    .foregroundColor(.blue)
                    .font(.caption)

                Text(viewModel.formatDate(callLog.calledAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Emotions (if available)
            if let emotions = callLog.emotions, !emotions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(emotions.prefix(3)) { emotion in
                        Text(emotion.emoji)
                            .font(.caption)
                    }
                    if emotions.count > 3 {
                        Text("+\(emotions.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }

            // Notes preview (if available)
            if let content = callLog.content, !content.isEmpty {
                Text(content)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    // Create sample call log (Monica v4.x fields)
    let sampleCallLog = CallLog(
        id: 1,
        contactId: 1,
        calledAt: Date(),
        content: "Had a great conversation about the project. They're excited about the progress!",
        contactCalled: false,
        emotions: [
            Emotion(id: 1, accountId: 1, name: "Happy", nameTranslationKey: "emotion.happy", type: .positive, createdAt: Date(), updatedAt: Date()),
            Emotion(id: 2, accountId: 1, name: "Excited", nameTranslationKey: "emotion.excited", type: .positive, createdAt: Date(), updatedAt: Date())
        ],
        createdAt: Date(),
        updatedAt: Date()
    )

    let apiClient = MonicaAPIClient(baseURL: "https://monica.example.com", apiToken: "preview-token")
    let apiService = CallLogAPIService(apiClient: apiClient)
    let viewModel = CallLogViewModel(contactId: 1, apiService: apiService)

    return List {
        CallLogRowView(callLog: sampleCallLog, viewModel: viewModel)
    }
}
