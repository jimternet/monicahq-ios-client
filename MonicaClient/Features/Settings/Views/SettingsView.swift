import SwiftUI

/// Settings view for managing account, cache, and app configuration
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingTokenUpdateSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section {
                    HStack {
                        Label("Instance", systemImage: "server.rack")
                        Spacer()
                        Text(viewModel.instanceURL ?? "Not configured")
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Label("API Token", systemImage: "key.fill")
                        Spacer()
                        Text(viewModel.maskedToken)
                            .foregroundColor(.secondaryText)
                            .font(.system(.body, design: .monospaced))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingTokenUpdateSheet = true
                    }
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Label("Sign Out", systemImage: "arrow.right.square")
                                .foregroundColor(.errorRed)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Account")
                } footer: {
                    if let instanceType = viewModel.instanceType {
                        Text("Connected to \(instanceType.displayName) instance")
                            .font(.caption)
                    }
                }
                
                // Cache Management Section
                Section {
                    HStack {
                        Label("Cache Size", systemImage: "internaldrive")
                        Spacer()
                        if viewModel.isCalculatingCache {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(viewModel.cacheSize)
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    Button(action: {
                        showingClearCacheAlert = true
                    }) {
                        HStack {
                            Label("Clear Cache", systemImage: "trash")
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isCalculatingCache)
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Clearing cache will remove all locally stored contact data. Data will be re-synced from Monica on next refresh.")
                        .font(.caption)
                }
                
                // App Information Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondaryText)
                    }
                    
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Link(destination: URL(string: "https://github.com/monicahq/monica")!) {
                        HStack {
                            Label("Monica Documentation", systemImage: "book")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    Link(destination: URL(string: "https://www.monicahq.com")!) {
                        HStack {
                            Label("Monica Website", systemImage: "globe")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondaryText)
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // Advanced Section
                Section {
                    Button(action: {
                        viewModel.switchInstance()
                    }) {
                        HStack {
                            Label("Switch Instance", systemImage: "arrow.triangle.swap")
                            Spacer()
                        }
                    }
                    
                    Toggle(isOn: $viewModel.debugMode) {
                        Label("Debug Mode", systemImage: "ant")
                    }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Switching instance will sign you out and return to the setup screen.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadSettings()
            await viewModel.calculateCacheSize()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("Are you sure you want to sign out? You'll need to enter your API credentials again to access your contacts.")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearCache()
                }
            }
        } message: {
            Text("This will remove all locally stored data. Your contacts will be re-synced from Monica on the next refresh.")
        }
        .sheet(isPresented: $showingTokenUpdateSheet) {
            UpdateTokenView(viewModel: viewModel)
        }
    }
}

/// View for updating API token
struct UpdateTokenView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newToken = ""
    @State private var showPassword = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: Constants.UI.Spacing.large) {
                Text("Update API Token")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, Constants.UI.Spacing.large)
                
                Text("Enter a new API token for your Monica instance")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                    Text("New API Token")
                        .font(.headline)
                    
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Enter new API token", text: $newToken)
                            } else {
                                SecureField("Enter new API token", text: $newToken)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.errorRed)
                        .padding()
                        .background(Color.errorRed.opacity(0.1))
                        .cornerRadius(Constants.UI.CornerRadius.medium)
                }
                
                Spacer()
                
                Button(action: updateToken) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Updating...")
                        } else {
                            Text("Update Token")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(newToken.isEmpty ? Color.gray : Color.monicaBlue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.CornerRadius.medium)
                }
                .disabled(newToken.isEmpty || isUpdating)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateToken() {
        isUpdating = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.updateAPIToken(newToken)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isUpdating = false
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataController(authManager: AuthenticationManager()))
}