import SwiftUI

/// Form view for creating or editing a call log
/// Based on Monica v4.x Call API (verified) - Backend-only
struct CallLogFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CallLogViewModel

    let editingCallLog: CallLog?
    let onSave: () -> Void

    init(viewModel: CallLogViewModel, editingCallLog: CallLog? = nil, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self.editingCallLog = editingCallLog
        self.onSave = onSave

        // Load existing data if editing
        if let callLog = editingCallLog {
            viewModel.loadForEditing(callLog)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Date/Time Section
                Section {
                    DatePicker(
                        "Date & Time",
                        selection: $viewModel.selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("When")
                }

                // Call Direction Section
                Section {
                    Picker("Who called who?", selection: $viewModel.whoInitiated) {
                        ForEach(CallDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Direction")
                }

                // Emotion Section (Monica v4.x supports multiple emotions)
                Section {
                    if viewModel.availableEmotions.isEmpty {
                        Text("No emotions available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.availableEmotions) { emotion in
                            Toggle(isOn: Binding(
                                get: { viewModel.selectedEmotionIds.contains(emotion.id) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedEmotionIds.insert(emotion.id)
                                    } else {
                                        viewModel.selectedEmotionIds.remove(emotion.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Text(emotion.emoji)
                                    Text(emotion.displayName)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Emotions")
                } footer: {
                    Text("Optional: How did you feel during this call? You can select multiple.")
                }

                // Notes Section
                Section {
                    TextEditor(text: $viewModel.callDescription)
                        .frame(minHeight: 100)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Optional: What did you talk about? Any important details to remember?")
                }
            }
            .navigationTitle(editingCallLog == nil ? "Log Call" : "Edit Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(editingCallLog == nil ? "Save" : "Update") {
                        Task {
                            if let callLog = editingCallLog {
                                await viewModel.updateCallLog(callLog)
                            } else {
                                await viewModel.saveCallLog()
                            }
                            onSave()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoading)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = CallLogAPIService(apiClient: apiClient)
    let viewModel = CallLogViewModel(contactId: 1, apiService: apiService)

    CallLogFormView(viewModel: viewModel) {
        print("Saved")
    }
}
