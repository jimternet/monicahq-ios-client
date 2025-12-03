import SwiftUI

/// Form view for creating or editing a day rating
struct DayRatingFormView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: DayEntryViewModel

    let onSave: ((DayEntry) -> Void)?
    let existingEntry: DayEntry?

    init(apiClient: MonicaAPIClient, existingEntry: DayEntry? = nil, onSave: ((DayEntry) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: DayEntryViewModel(apiClient: apiClient))
        self.existingEntry = existingEntry
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                // Mood Selection Section
                Section {
                    VStack(spacing: 16) {
                        Text("How was your day?")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)

                        MoodPickerView(selectedMood: $viewModel.selectedMood)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 8)
                }

                // Date Section
                Section {
                    DatePicker(
                        "Date",
                        selection: $viewModel.selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                } header: {
                    Text("When")
                } footer: {
                    if viewModel.isDateInFuture {
                        Text("Cannot rate a future date")
                            .foregroundColor(.red)
                    }
                }

                // Comment Section
                Section {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 100)
                } header: {
                    Text("Comment (optional)")
                } footer: {
                    Text("Add a note about what made your day \(viewModel.selectedMood?.label.lowercased() ?? "this way")")
                }

                // Error Display
                if let error = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    await save()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Day Rating" : "Rate Your Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await save()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isValid)
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.isLoading)
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                if let entry = existingEntry {
                    viewModel.loadEntry(entry)
                }
            }
        }
    }

    private func save() async {
        if let savedEntry = await viewModel.saveDayEntry() {
            onSave?(savedEntry)
            dismiss()
        }
    }
}

#Preview("New Entry") {
    DayRatingFormView(
        apiClient: MonicaAPIClient(baseURL: "https://example.com", apiToken: "test"),
        onSave: { entry in
            print("Saved: \(entry)")
        }
    )
    .environmentObject(AuthenticationManager())
}

#Preview("Edit Mode") {
    DayRatingFormView(
        apiClient: MonicaAPIClient(baseURL: "https://example.com", apiToken: "test"),
        existingEntry: DayEntry(
            id: 1,
            rate: 3,
            comment: "Had a great productive day!",
            date: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ),
        onSave: { entry in
            print("Updated: \(entry)")
        }
    )
    .environmentObject(AuthenticationManager())
}
