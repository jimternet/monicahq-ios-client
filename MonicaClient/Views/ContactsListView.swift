import SwiftUI
import CoreData

struct ContactsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var authManager: AuthenticationManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContactEntity.firstName, ascending: true)],
        animation: .default)
    private var contacts: FetchedResults<ContactEntity>
    
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var showingAddContact = false
    
    var filteredContacts: [ContactEntity] {
        if searchText.isEmpty {
            return Array(contacts)
        } else {
            return contacts.filter { contact in
                let fullName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredContacts) { contact in
                    NavigationLink(destination: destinationView(for: contact)) {
                        ContactRowView(contact: contact)
                    }
                }
                .onDelete(perform: deleteContacts)
            }
            .searchable(text: $searchText)
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // TODO: Re-enable contact creation
                        // Button(action: { showingAddContact = true }) {
                        //     Image(systemName: "plus")
                        // }

                        Button(action: refreshContacts) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isRefreshing)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        authManager.logout()
                    }
                }
            }
            // TODO: Re-enable contact creation sheet
            // .sheet(isPresented: $showingAddContact) {
            //     AddContactView()
            //         .environmentObject(authManager)
            //         .environmentObject(dataController)
            // }
            .refreshable {
                await syncContacts()
            }
        }
        .task {
            await syncContacts()
        }
    }
    
    @ViewBuilder
    private func destinationView(for contact: ContactEntity) -> some View {
        ContactDetailView(contact: contact)
    }
    
    private func refreshContacts() {
        Task {
            isRefreshing = true
            await syncContacts()
            isRefreshing = false
        }
    }
    
    private func syncContacts() async {
        print("🔄 Starting sync from ContactsListView...")
        do {
            try await dataController.syncManager.syncContacts()
            print("✅ Sync completed successfully")

            // Show cache statistics
            let stats = dataController.getCacheStatistics()
            print("📊 Cache stats: \(stats.total) total, \(stats.needingSync) need detail sync")
        } catch {
            print("❌ Failed to sync contacts: \(error)")
        }
    }

    private func deleteContacts(at offsets: IndexSet) {
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            for index in offsets {
                let contact = filteredContacts[index]

                do {
                    // Delete from API
                    try await apiClient.deleteContact(id: Int(contact.id))
                    print("✅ Deleted contact from API: \(contact.fullName)")

                    // Delete from Core Data
                    await MainActor.run {
                        viewContext.delete(contact)
                        dataController.save()
                        print("✅ Deleted contact from Core Data: \(contact.fullName)")
                    }
                } catch {
                    print("❌ Failed to delete contact \(contact.fullName): \(error)")
                }
            }
        }
    }
}

struct ContactRowView: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        HStack {
            ContactAvatar(contact: contact, size: 50)
            
            VStack(alignment: .leading) {
                Text(contact.fullName)
                    .font(.headline)
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Star/Favorite button
            Button(action: {
                toggleStar()
            }) {
                Image(systemName: contact.isStarred ? "star.fill" : "star")
                    .foregroundColor(contact.isStarred ? .yellow : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Show cache status indicator
            if contact.needsDetailSync {
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else if contact.detailsSyncedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleStar() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            do {
                let newStarredState = !contact.isStarred
                let updatedContact = try await apiClient.toggleContactStar(contactId: Int(contact.id), isStarred: newStarredState)
                
                await MainActor.run {
                    // Update the Core Data entity
                    contact.objectWillChange.send()
                    contact.isStarred = updatedContact.isStarred
                    dataController.save()
                }
                
                print("✅ \(newStarredState ? "Starred" : "Unstarred") contact: \(contact.fullName)")
            } catch {
                print("❌ Failed to toggle star for \(contact.fullName): \(error)")
            }
        }
    }
}

extension ContactEntity {
    var fullName: String {
        "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let firstInitial = firstName?.first.map(String.init) ?? ""
        let lastInitial = lastName?.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

#Preview {
    let authManager = AuthenticationManager()
    let dataController = DataController(authManager: authManager)

    return ContactsListView()
        .environment(\.managedObjectContext, dataController.container.viewContext)
        .environmentObject(dataController)
        .environmentObject(authManager)
}