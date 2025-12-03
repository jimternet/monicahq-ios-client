import SwiftUI

/// A component for selecting mood ratings with emoji buttons
/// Displays bad (😞), okay (😐), and great (😊) options
struct MoodPickerView: View {
    @Binding var selectedMood: MoodRating?

    var body: some View {
        HStack(spacing: 24) {
            ForEach(MoodRating.allCases, id: \.self) { mood in
                MoodButton(
                    mood: mood,
                    isSelected: selectedMood == mood,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = mood
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
}

/// Individual mood button with emoji and label
struct MoodButton: View {
    let mood: MoodRating
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 48))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(mood.label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? moodColor : .secondary)
            }
            .frame(width: 80, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? moodColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? moodColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mood.label) mood")
        .accessibilityHint("Tap to select \(mood.label.lowercased()) mood rating")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var moodColor: Color {
        switch mood {
        case .bad:
            return .red
        case .okay:
            return .orange
        case .great:
            return .green
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedMood: MoodRating? = nil

        var body: some View {
            VStack(spacing: 20) {
                Text("How was your day?")
                    .font(.headline)

                MoodPickerView(selectedMood: $selectedMood)

                if let mood = selectedMood {
                    Text("Selected: \(mood.label)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
