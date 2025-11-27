import SwiftUI
import MessageUI

struct EnhancedContactDetailView: View {
    let contactId: Int
    @StateObject private var viewModel: ContactDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(contactId: Int, apiClient: MonicaAPIClientProtocol) {
        self.contactId = contactId
        self._viewModel = StateObject(wrappedValue: ContactDetailViewModel(
            contactId: contactId,
            apiClient: apiClient
        ))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading contact...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.loadContact()
                        }
                    }
                } else if let contact = viewModel.contact {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            contactHeaderSection(contact: contact)
                            
                            if let contactFields = contact.contactFields, !contactFields.isEmpty {
                                contactFieldsSection(contact: contact)
                            }
                            
                            ActivityTimelineView(
                                activities: viewModel.activities,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadMoreActivities()
                                    }
                                },
                                hasMoreActivities: viewModel.hasMoreActivities,
                                isLoadingMore: viewModel.isLoadingMoreActivities
                            )

                            // Call Logging Section
                            callLoggingSection(contactId: contact.id)

                            // Conversation Tracking Section
                            conversationTrackingSection(contactId: contact.id)

                            // Relationships section
                            if let relationships = contact.relationships, !relationships.isEmpty {
                                RelationshipsSection(
                                    relationships: relationships,
                                    onRelationshipTap: { relatedContact in
                                        // Navigate to related contact details
                                        // This would typically trigger navigation
                                        print("Navigate to contact: \(relatedContact.displayName)")
                                    }
                                )
                            }
                            
                            NotesSection(
                                notes: viewModel.notes,
                                onNoteTap: { note in
                                    // Navigate to note details
                                    print("Navigate to note: \(note.title ?? "Untitled")")
                                },
                                onToggleFavorite: { note in
                                    Task {
                                        await viewModel.toggleNoteFavorite(note)
                                    }
                                },
                                onAddNote: {
                                    // Navigate to add note
                                    print("Navigate to add note")
                                },
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadMoreNotes()
                                    }
                                },
                                hasMoreNotes: viewModel.hasMoreNotes,
                                isLoadingMore: viewModel.isLoadingMoreNotes
                            )
                            
                            TasksSection(tasks: viewModel.tasks)
                        }
                        .padding()
                    }
                } else {
                    Text("Contact not found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(viewModel.contact?.firstName ?? "Contact")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadContact()
        }
    }
    
    @ViewBuilder
    private func contactHeaderSection(contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AsyncImage(url: URL(string: contact.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.completeName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let nickname = contact.nickname, !nickname.isEmpty {
                        Text(""\(nickname)"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let birthday = contact.birthday {
                        HStack {
                            Image(systemName: "gift")
                                .foregroundColor(.blue)
                            Text(formatBirthday(birthday))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            if let description = contact.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func contactFieldsSection(contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(contact.contactFields ?? [], id: \.id) { field in
                    ContactFieldRow(field: field) { fieldType, value in
                        handleContactFieldTap(type: fieldType, value: value)
                    }
                    
                    if field.id != (contact.contactFields ?? []).last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func formatBirthday(_ birthday: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthday)
    }
    
    private func handleContactFieldTap(type: ContactField.ContactFieldType, value: String) {
        switch type {
        case .email:
            openEmailApp(email: value)
        case .phone:
            openPhoneApp(phone: value)
        default:
            break
        }
    }
    
    private func openEmailApp(email: String) {
        if let emailURL = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    private func openPhoneApp(phone: String) {
        let cleanedPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let phoneURL = URL(string: "tel:\(cleanedPhone)") {
            UIApplication.shared.open(phoneURL)
        }
    }

    @ViewBuilder
    private func callLoggingSection(contactId: Int) -> some View {
        NavigationLink {
            if let apiClient = viewModel.apiClient as? MonicaAPIClient {
                let callLogAPIService = CallLogAPIService(apiClient: apiClient)
                let callLogViewModel = CallLogViewModel(contactId: contactId, apiService: callLogAPIService)
                CallLogListView(viewModel: callLogViewModel)
            } else {
                Text("Unable to load call logs")
                    .foregroundColor(.secondary)
            }
        } label: {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Call History")
                        .font(.headline)
                    Text("View and log phone calls")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func conversationTrackingSection(contactId: Int) -> some View {
        NavigationLink {
            if let apiClient = viewModel.apiClient as? MonicaAPIClient {
                let conversationAPIService = ConversationAPIService(apiClient: apiClient)
                let conversationViewModel = ConversationViewModel(contactId: contactId, apiService: conversationAPIService)
                ConversationListView(viewModel: conversationViewModel)
            } else {
                Text("Unable to load conversations")
                    .foregroundColor(.secondary)
            }
        } label: {
            HStack {
                Image(systemName: "message.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Conversations")
                        .font(.headline)
                    Text("Track in-person and written conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct ContactFieldRow: View {
    let field: ContactField
    let onTap: (ContactField.ContactFieldType, String) -> Void
    
    var body: some View {
        Button {
            onTap(field.contactFieldType, field.data)
        } label: {
            HStack {
                Image(systemName: iconForFieldType(field.contactFieldType))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.contactFieldType.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(field.data)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if field.contactFieldType == .email || field.contactFieldType == .phone {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForFieldType(_ type: ContactField.ContactFieldType) -> String {
        switch type {
        case .email:
            return "envelope"
        case .phone:
            return "phone"
        case .address:
            return "location"
        case .website:
            return "globe"
        default:
            return "info.circle"
        }
    }
}

struct ErrorView: View {
    let error: MonicaAPIError
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Loading Contact")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    EnhancedContactDetailView(
        contactId: 1,
        apiClient: MockMonicaAPIClient()
    )
}