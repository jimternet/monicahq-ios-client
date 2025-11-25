import SwiftUI

/// Form view for creating or editing a call log
struct CallLogFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CallLogViewModel

    let editingEntity: CallLogEntity?
    let onSave: () -> Void

    init(viewModel: CallLogViewModel, editingEntity: CallLogEntity? = nil, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self.editingEntity = editingEntity
        self.onSave = onSave

        // Load existing data if editing
        if let entity = editingEntity {
            viewModel.loadForEditing(entity)
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

                // Duration Section
                Section {
                    HStack {
                        Text("Duration (minutes)")
                        Spacer()
                        TextField("Optional", text: $viewModel.duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Call Length")
                } footer: {
                    Text("How long did the call last? Leave blank if you don't remember.")
                }

                // Emotional State Section
                Section {
                    Picker("How did they seem?", selection: $viewModel.selectedEmotion) {
                        Text("Not recorded").tag(nil as EmotionalState?)

                        ForEach(EmotionalState.allCases) { state in
                            HStack {
                                Text(state.emoji)
                                Text(state.displayName)
                            }
                            .tag(state as EmotionalState?)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Mood")
                } footer: {
                    Text("Optional: How did the person seem during the call?")
                }

                // Notes Section
                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Optional: What did you talk about? Any important details to remember?")
                }
            }
            .navigationTitle(editingEntity == nil ? "Log Call" : "Edit Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(editingEntity == nil ? "Save" : "Update") {
                        Task {
                            if let entity = editingEntity {
                                await viewModel.updateCallLog(entity)
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
    let dataController = DataController(authManager: AuthenticationManager())
    let storage = CallLogStorage(dataController: dataController)
    let viewModel = CallLogViewModel(contactId: 1, storage: storage)

    return CallLogFormView(viewModel: viewModel) {
        print("Saved")
    }
}
