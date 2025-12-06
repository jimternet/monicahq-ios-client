import SwiftUI

/// List view displaying all debts for a contact with summary header
struct DebtListView: View {
    @ObservedObject var viewModel: DebtViewModel
    let contactId: Int
    let contactName: String

    @State private var showingAddDebt = false
    @State private var debtToEdit: Debt?
    @State private var showDeleteConfirmation = false
    @State private var debtToDelete: Debt?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.debts.isEmpty {
                ProgressView("Loading debts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.debts.isEmpty {
                emptyStateView
            } else {
                debtsList
            }
        }
        .navigationTitle("Debts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddDebt = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDebt) {
            DebtFormView(
                viewModel: viewModel,
                contactId: contactId,
                contactName: contactName
            )
        }
        .sheet(item: $debtToEdit) { debt in
            DebtFormView(
                viewModel: viewModel,
                contactId: contactId,
                contactName: contactName,
                existingDebt: debt
            )
        }
        .alert("Delete Debt", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                debtToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let debt = debtToDelete {
                    Task {
                        await viewModel.deleteDebt(debt)
                    }
                }
                debtToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this debt? This action cannot be undone.")
        }
        .task {
            await viewModel.fetchDebts(contactId: contactId)
        }
        .refreshable {
            await viewModel.fetchDebts(contactId: contactId)
        }
        .overlay {
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.cornerRadius(8))
                        .padding()
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Debts")
                .font(.title2)
                .fontWeight(.medium)

            Text("Track money lent to or borrowed from \(contactName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddDebt = true
            } label: {
                Label("Add Debt", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var debtsList: some View {
        List {
            // Net balance summary header
            if !viewModel.netBalances.isEmpty {
                Section {
                    DebtSummaryView(netBalances: viewModel.netBalances)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // Outstanding debts section
            if !viewModel.outstandingDebts.isEmpty {
                Section {
                    ForEach(viewModel.outstandingDebts) { debt in
                        DebtRowView(
                            debt: debt,
                            onMarkSettled: {
                                Task {
                                    await viewModel.markAsSettled(debt: debt)
                                }
                            },
                            onEdit: {
                                debtToEdit = debt
                            },
                            onDelete: {
                                debtToDelete = debt
                                showDeleteConfirmation = true
                            }
                        )
                    }
                } header: {
                    Text("Outstanding (\(viewModel.outstandingDebts.count))")
                }
            }

            // Settled debts section
            if !viewModel.settledDebts.isEmpty {
                Section {
                    ForEach(viewModel.settledDebts) { debt in
                        DebtRowView(
                            debt: debt,
                            onEdit: {
                                debtToEdit = debt
                            },
                            onDelete: {
                                debtToDelete = debt
                                showDeleteConfirmation = true
                            }
                        )
                    }
                } header: {
                    Text("Settled (\(viewModel.settledDebts.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = DebtAPIService(apiClient: apiClient)
    return NavigationStack {
        DebtListView(
            viewModel: DebtViewModel(apiService: apiService),
            contactId: 1,
            contactName: "John Doe"
        )
    }
}
