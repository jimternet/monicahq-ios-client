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

                // Messages Section (all messages are editable)
                Section {
                    ForEach(Array(viewModel.formMessages.enumerated()), id: \.element.id) { index, _ in
                        MessageInputView(
                            message: $viewModel.formMessages[index],
                            contactName: viewModel.contactName,
                            canDelete: viewModel.formMessages.count > 1,
                            onDelete: {
                                viewModel.removeMessage(at: index)
                            }
                        )
                    }

                    // Add another message button
                    Button(action: { viewModel.addMessage() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add another message")
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Add another message")
                    .accessibilityHint("Add another message to this conversation")
                } header: {
                    Text("Messages")
                } footer: {
                    Text("Add messages exchanged during this conversation. Leave empty for a quick log.")
                }

                // Conversation Type Section
                Section {
                    if viewModel.isLoadingFieldTypes {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Loading types...")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if viewModel.contactFieldTypes.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("No conversation types available")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Type", selection: $viewModel.selectedConversationType) {
                            Text("Select a type").tag(nil as Int?)
                            ForEach(viewModel.contactFieldTypes) { fieldType in
                                HStack {
                                    Text(fieldType.name)
                                    if fieldType.id == viewModel.defaultConversationTypeId {
                                        Spacer()
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }.tag(fieldType.id as Int?)
                            }
                        }
                        .accessibilityLabel("Conversation type")
                        .accessibilityHint("Select the type of conversation")
                    }
                } header: {
                    Text("Type")
                } footer: {
                    if viewModel.selectedConversationType == viewModel.defaultConversationTypeId {
                        Text("Using your default type. Change in Settings.")
                    } else {
                        Text("How did this conversation happen? Change default in Settings.")
                    }
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
            .task {
                // Load existing data if editing, or initialize empty form
                if let conversation = editingConversation {
                    viewModel.loadForEditing(conversation)
                } else if viewModel.formMessages.isEmpty {
                    // Initialize with one empty message for new conversations
                    viewModel.formMessages = [ConversationViewModel.FormMessage()]
                }
                // Load contact field types when form appears
                await viewModel.loadContactFieldTypes()
            }
        }
    }
}

// MARK: - Message Input View

/// Individual message input with sender toggle (for new messages)
struct MessageInputView: View {
    @Binding var message: ConversationViewModel.FormMessage
    let contactName: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sender picker
            HStack {
                Text("From:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Sender", selection: $message.writtenByMe) {
                    Text("You").tag(true)
                    Text(contactName).tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Spacer()

                // Delete button
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete this message")
                }
            }

            // Message content
            TextField("What was said?", text: $message.content, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Message content")
                .accessibilityHint("Enter what was said in this message")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = ConversationAPIService(apiClient: apiClient)
    let viewModel = ConversationViewModel(contactId: 1, contactName: "Aaron", apiService: apiService)

    return ConversationFormView(viewModel: viewModel) {
        print("Saved")
    }
}
