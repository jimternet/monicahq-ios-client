import SwiftUI

struct ConversationsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var showingAddConversation = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading conversations...")
                } else if conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Conversations")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first conversation with \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddConversation = true }) {
                            Label("Add Conversation", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            ConversationRowView(conversation: conversation, onDelete: {
                                deleteConversation(conversation)
                            })
                        }
                    }
                    .refreshable {
                        await loadConversations()
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !conversations.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddConversation = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadConversations()
        }
        .sheet(isPresented: $showingAddConversation) {
            AddConversationView(contact: contact) { newConversation in
                conversations.insert(newConversation, at: 0)
            }
            .environmentObject(authManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @MainActor
    private func loadConversations() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getConversations(for: contact.id, limit: 100)
            conversations = response.data.sorted { $0.happenedAt > $1.happenedAt }
            print("✅ Loaded \(conversations.count) conversations")
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load conversations: \(error)")
        }
        isLoading = false
    }

    private func deleteConversation(_ conversation: Conversation) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteConversation(id: conversation.id)
                await MainActor.run {
                    conversations.removeAll { $0.id == conversation.id }
                }
                print("✅ Deleted conversation")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete conversation: \(error)")
            }
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conversation.happenedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let contactFieldTypeId = conversation.contactFieldTypeId {
                    Image(systemName: contactFieldType(for: contactFieldTypeId))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if let content = conversation.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            } else {
                Text("No details")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func contactFieldType(for id: Int) -> String {
        // Contact field types: 1 = email, 2 = phone
        switch id {
        case 1:
            return "envelope"
        case 2:
            return "phone"
        default:
            return "bubble.left.and.bubble.right"
        }
    }
}

struct AddConversationView: View {
    let contact: Contact
    let onConversationAdded: (Conversation) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var happenedAt = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Conversation Details") {
                    DatePicker("Date", selection: $happenedAt, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Add Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitConversation()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitConversation() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createConversation(
                    for: contact.id,
                    happenedAt: happenedAt,
                    content: content.isEmpty ? nil : content
                )

                await MainActor.run {
                    onConversationAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create conversation: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
