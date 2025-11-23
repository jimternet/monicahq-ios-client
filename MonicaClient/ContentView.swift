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