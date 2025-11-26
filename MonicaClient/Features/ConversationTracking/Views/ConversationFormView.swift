//
//  ConversationFormView.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// Form view for creating or editing a conversation
/// Based on Monica v4.x Conversations API (verified) - Backend-only
struct ConversationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ConversationViewModel

    let editingConversation: Conversation?
    let onSave: () -> Void

    init(viewModel: ConversationViewModel, editingConversation: Conversation? = nil, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self.editingConversation = editingConversation
        self.onSave = onSave

        // Load existing data if editing
        if let conversation = editingConversation {
            viewModel.loadForEditing(conversation)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Date/Time Section
                Section {
                    DatePicker(
                        "Date & Time",
                        selection: $viewModel.happenedAt,
                        in: ...Date(),  // Prevent future dates
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityLabel("Conversation date and time")
                    .accessibilityHint("Select when this conversation happened")
                } header: {
                    Text("When")
                } footer: {
                    Text("When did this conversation happen? (Cannot be in the future)")
                }

                // Notes Section
                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 150)
                        .accessibilityLabel("Conversation notes")
                        .accessibilityHint("Enter details about what was discussed")

                    // Character counter
                    let (count, color) = viewModel.notesCharacterCount()
                    HStack {
                        Spacer()
                        Text("\(count) / 10,000")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                } header: {
                    Text("Notes")
                } footer: {
                    Text("What did you talk about? Any important details to remember? (Optional, max 10,000 characters)")
                }

                // Conversation Type Section (optional)
                Section {
                    Picker("Type", selection: $viewModel.selectedConversationType) {
                        Text("None").tag(nil as Int?)
                        // TODO: Load conversation types from API when available
                        // For now, just show None option
                    }
                    .accessibilityLabel("Conversation type")
                    .accessibilityHint("Optional: categorize the type of conversation")
                } header: {
                    Text("Type (Optional)")
                } footer: {
                    Text("Categorize this conversation (e.g., in-person, phone, email)")
                }
            }
            .navigationTitle(editingConversation == nil ? "Log Conversation" : "Edit Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discard changes and close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(editingConversation == nil ? "Save" : "Update") {
                        Task {
                            if editingConversation != nil {
                                await viewModel.updateConversation()
                            } else {
                                await viewModel.saveConversation()
                            }
                            onSave()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoading)
                    .accessibilityLabel(editingConversation == nil ? "Save conversation" : "Update conversation")
                    .accessibilityHint("Save this conversation entry")
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
                        .accessibilityLabel("Loading")
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
    let apiService = ConversationAPIService(apiClient: apiClient)
    let viewModel = ConversationViewModel(contactId: 1, apiService: apiService)

    ConversationFormView(viewModel: viewModel) {
        print("Saved")
    }
}
