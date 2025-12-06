import SwiftUI

/// Tab view wrapper for the Global Debts view
/// Handles creating the API service and view model with proper authentication
struct DebtsTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            if let apiClient = authManager.currentAPIClient {
                let apiService = DebtAPIService(apiClient: apiClient)
                let viewModel = DebtViewModel(apiService: apiService)
                GlobalDebtView(viewModel: viewModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("Not Authenticated")
                        .font(.headline)

                    Text("Please sign in to view debts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Debts")
            }
        }
    }
}

#Preview {
    DebtsTabView()
        .environmentObject(AuthenticationManager())
}
