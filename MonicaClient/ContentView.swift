import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    ContactsListView()
                        .tabItem {
                            Label("Contacts", systemImage: "person.3")
                        }

                    RemindersListView()
                        .tabItem {
                            Label("Reminders", systemImage: "bell")
                        }

                    DebtsTabView()
                        .tabItem {
                            Label("Debts", systemImage: "dollarsign.circle")
                        }

                    // TODO: Re-enable Journal view when implemented
                    // JournalView()
                    //     .tabItem {
                    //         Label("Journal", systemImage: "book")
                    //     }

                    SimpleSettingsView()
                        .environmentObject(dataController)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            } else {
                LoginView()
            }
        }
        .task {
            await authManager.checkAuthenticationStatus()
        }
    }
}

/// Simple inline settings view to avoid import issues
struct SimpleSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @State private var isRefreshingConfig = false
    @AppStorage("isDemoModeEnabled") private var isDemoModeEnabled = false

    // Conversation settings
    @State private var contactFieldTypes: [ContactFieldType] = []
    @State private var isLoadingFieldTypes = false
    @State private var selectedDefaultConversationType: Int?
    private let userDefaultsService = UserDefaultsService()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Data Management") {
                    Button {
                        Task {
                            isRefreshingConfig = true
                            await authManager.refreshConfigurationVariables()
                            isRefreshingConfig = false
                        }
                    } label: {
                        HStack {
                            Text("Refresh Configuration")
                            if isRefreshingConfig {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRefreshingConfig)

                    Text("Refresh genders, relationship types, and tags from the server")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Clear Cache & Re-sync") {
                        showingClearCacheAlert = true
                    }
                    .foregroundColor(.orange)
                }

                Section("Developer Options") {
                    Toggle("Demo Mode", isOn: $isDemoModeEnabled)
                        .onChange(of: isDemoModeEnabled) { newValue in
                            print("📱 Demo mode: \(newValue ? "ENABLED" : "DISABLED")")
                        }

                    if isDemoModeEnabled {
                        Text("Demo data will be shown when API endpoints are unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Conversations") {
                    if isLoadingFieldTypes {
                        HStack {
                            Text("Default Type")
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    } else if contactFieldTypes.isEmpty {
                        HStack {
                            Text("Default Type")
                            Spacer()
                            Text("Unable to load")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Default Type", selection: $selectedDefaultConversationType) {
                            Text("First available").tag(nil as Int?)
                            ForEach(contactFieldTypes) { fieldType in
                                Text(fieldType.name).tag(fieldType.id as Int?)
                            }
                        }
                        .onChange(of: selectedDefaultConversationType) { newValue in
                            userDefaultsService.defaultConversationType = newValue
                            if let typeId = newValue {
                                let typeName = contactFieldTypes.first(where: { $0.id == typeId })?.name ?? "Unknown"
                                print("💾 Settings: Saved default conversation type: \(typeName) (id: \(typeId))")
                            } else {
                                print("💾 Settings: Cleared default conversation type")
                            }
                        }
                    }

                    Text("Default type for Quick Log and new conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Account") {
                    Button("Sign Out") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear & Re-sync", role: .destructive) {
                clearCacheAndResync()
            }
        } message: {
            Text("This will clear all cached data and fetch fresh contact information including avatars.")
        }
        .task {
            await loadConversationSettings()
        }
    }

    private func loadConversationSettings() async {
        // Load saved default
        selectedDefaultConversationType = userDefaultsService.defaultConversationType

        // Load field types from API
        guard let apiURL = authManager.apiURL,
              let apiToken = authManager.apiToken else { return }

        isLoadingFieldTypes = true

        do {
            let apiClient = MonicaAPIClient(baseURL: apiURL, apiToken: apiToken)
            let response = try await apiClient.getContactFieldTypes()
            contactFieldTypes = response.data
            print("✅ Settings: Loaded \(contactFieldTypes.count) contact field types")
        } catch {
            print("❌ Settings: Failed to load contact field types: \(error)")
        }

        isLoadingFieldTypes = false
    }

    private func clearCacheAndResync() {
        Task {
            print("🗑️ Clearing cache and forcing re-sync...")
            dataController.clearAllData()
            
            // Wait a moment for the clear to complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Trigger a fresh sync
            do {
                try await dataController.syncManager.syncContacts()
                print("✅ Cache cleared and re-sync completed")
            } catch {
                print("❌ Failed to re-sync after cache clear: \(error)")
            }
        }
    }
}

#Preview {
    let authManager = AuthenticationManager()
    let dataController = DataController(authManager: authManager)
    
    return ContentView()
        .environmentObject(authManager)
        .environmentObject(dataController)
}