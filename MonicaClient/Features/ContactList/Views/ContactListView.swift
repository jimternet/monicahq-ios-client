import SwiftUI
import CoreData

/// Main contact list view with search, pagination, and pull-to-refresh
struct EnhancedContactListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var authManager: AuthenticationManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ContactEntity.firstName, ascending: true)],
        animation: .default)
    private var contacts: FetchedResults<ContactEntity>
    
    @StateObject private var viewModel = ContactListViewModel()
    @State private var searchText = ""
    @State private var isLoadingMore = false
    @State private var selectedContact: ContactEntity?
    
    private let itemsPerPage = 50
    
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
        NavigationStack {
            Group {
                if contacts.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    contactsList
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .refreshable {
                await refreshContacts()
            }
            .task {
                if contacts.isEmpty {
                    await loadInitialContacts()
                }
            }
            .sheet(item: $selectedContact) { contact in
                if let apiClient = authManager.currentAPIClient {
                    EnhancedContactDetailView(
                        contactId: Int(contact.id),
                        apiClient: apiClient
                    )
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            if let error = viewModel.lastError as? MonicaAPIError,
               error.isRetryable {
                Button("Retry") {
                    Task {
                        await viewModel.retry()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } else {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .networkAlert()
    }
    
    @ViewBuilder
    private var contactsList: some View {
        List {
            ForEach(filteredContacts) { contact in
                NavigationLink(destination: destinationView(for: contact)) {
                    ContactRowView(contact: contact)
                }
                .listRowInsets(EdgeInsets(
                    top: Constants.UI.Spacing.small,
                    leading: Constants.UI.Spacing.medium,
                    bottom: Constants.UI.Spacing.small,
                    trailing: Constants.UI.Spacing.medium
                ))
                .onAppear {
                    // Load more when reaching the end
                    if contact == filteredContacts.last && !isLoadingMore {
                        Task {
                            await loadMoreContactsIfNeeded()
                        }
                    }
                }
            }
            
            if viewModel.hasMorePages {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading more...")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Spacer()
                }
                .padding()
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(PlainListStyle())
        .overlay(alignment: .top) {
            if viewModel.isLoading {
                LinearProgressView()
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.large) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            Text("No Contacts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Pull down to refresh or check your Monica instance")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await refreshContacts()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .padding(.horizontal, Constants.UI.Spacing.large)
                    .padding(.vertical, Constants.UI.Spacing.medium)
                    .background(Color.monicaBlue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.CornerRadius.medium)
            }
        }
        .padding(Constants.UI.Spacing.large)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: {
                    Task { await refreshContacts() }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                
                Divider()
                
                Button(action: {
                    // Navigate to settings
                }) {
                    Label("Settings", systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    @ViewBuilder
    private func destinationView(for contact: ContactEntity) -> some View {
        if let apiClient = authManager.currentAPIClient {
            EnhancedContactDetailView(
                contactId: Int(contact.id),
                apiClient: apiClient
            )
        } else {
            Text("API client not available")
                .foregroundColor(.errorRed)
        }
    }
    
    private func loadInitialContacts() async {
        viewModel.isLoading = true
        do {
            try await dataController.syncManager.syncContacts()
            viewModel.currentPage = 1
            viewModel.hasMorePages = contacts.count >= itemsPerPage
        } catch {
            print("Failed to load initial contacts: \(error)")
            viewModel.handleError(error) {
                await self.loadInitialContacts()
            }
        }
        viewModel.isLoading = false
    }
    
    private func refreshContacts() async {
        viewModel.isLoading = true
        viewModel.currentPage = 1
        
        do {
            try await dataController.syncManager.syncContacts()
            viewModel.hasMorePages = contacts.count >= itemsPerPage
        } catch {
            print("Failed to refresh contacts: \(error)")
            viewModel.handleError(error) {
                await self.refreshContacts()
            }
        }
        
        viewModel.isLoading = false
    }
    
    private func loadMoreContactsIfNeeded() async {
        guard viewModel.hasMorePages && !isLoadingMore else { return }
        
        isLoadingMore = true
        viewModel.currentPage += 1
        
        // In a real implementation, this would load the next page
        // For now, we're using the sync manager which loads all contacts
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate loading
        
        isLoadingMore = false
        
        // Check if we have more pages based on the current count
        viewModel.hasMorePages = false // Set to false as we load all at once currently
    }
}

/// Linear progress indicator
struct LinearProgressView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.monicaBlue)
                .frame(width: geometry.size.width * 0.3, height: 2)
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .frame(height: 2)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    let authManager = AuthenticationManager()
    let dataController = DataController(authManager: authManager)
    
    return EnhancedContactListView()
        .environment(\.managedObjectContext, dataController.container.viewContext)
        .environmentObject(dataController)
        .environmentObject(authManager)
}