//
//  ConversationListView.swift
//  MonicaClient
//
//  Created for 005-conversation-tracking feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// List view displaying conversation history for a contact
struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @State private var showingAddSheet = false
    @State private var editingConversation: Conversation?
    @State private var conversationToDelete: Conversation?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                // Loading state
                ProgressView("Loading conversations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading conversations")
            } else if viewModel.conversations.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // List of conversations
                List {
                    ForEach(viewModel.sortedConversations) { conversation in
                        ConversationRowView(conversation: conversation, viewModel: viewModel, contactName: viewModel.contactName)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingConversation = conversation
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityLabel("Delete conversation")

                                Button {
                                    editingConversation = conversation
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                                .accessibilityLabel("Edit conversation")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Double tap to edit")
                    }

                    // Statistics footer
                    statisticsSection
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Conversation History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.resetForm()
                        showingAddSheet = true
                    } label: {
                        Label("Log Conversation", systemImage: "plus.circle")
                    }

                    Button {
                        Task {
                            await viewModel.quickLogConversation()
                        }
                    } label: {
                        Label("Quick Log", systemImage: "clock.badge.checkmark")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add conversation")
                .accessibilityHint("Log a new conversation or quick log")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ConversationFormView(viewModel: viewModel) {
                Task { await viewModel.loadConversations() }
            }
        }
        .sheet(item: $editingConversation) { conversation in
            ConversationFormView(viewModel: viewModel, editingConversation: conversation) {
                Task { await viewModel.loadConversations() }
            }
        }
        .confirmationDialog(
            "Delete Conversation",
            isPresented: $showingDeleteConfirmation,
            presenting: conversationToDelete
        ) { conversation in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteConversation(conversation)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("Are you sure you want to delete this conversation? This action cannot be undone.")
        }
        .task {
            await viewModel.loadConversations()
            await viewModel.loadContactFieldTypes()
        }
        .refreshable {
            await viewModel.loadConversations()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task { await viewModel.loadConversations() }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No Conversations")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Log your conversations to keep track of important discussions and stay connected.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    viewModel.resetForm()
                    showingAddSheet = true
                } label: {
                    Label("Log a Conversation", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Log a conversation")

                Button {
                    Task {
                        await viewModel.quickLogConversation()
                    }
                } label: {
                    Label("Quick Log", systemImage: "clock.badge.checkmark")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Quick log conversation")
                .accessibilityHint("Quickly log that a conversation happened")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        Section {
            let stats = viewModel.getStatistics()

            HStack {
                Label("Total Conversations", systemImage: "bubble.left.and.bubble.right")
                Spacer()
                Text("\(stats.total)")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)

            HStack {
                Label("With Notes", systemImage: "note.text")
                Spacer()
                Text("\(stats.withNotes)")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)

            HStack {
                Label("Quick Logs", systemImage: "clock.badge.checkmark")
                Spacer()
                Text("\(stats.total - stats.withNotes)")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
        } header: {
            Text("Statistics")
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

    NavigationView {
        ConversationListView(viewModel: viewModel)
    }
}
