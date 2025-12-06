import SwiftUI

/// Global view showing all debts across all contacts
struct GlobalDebtView: View {
    @ObservedObject var viewModel: DebtViewModel
    @State private var filterDirection: DebtDirection?
    @State private var showSettled = false
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
        .navigationTitle("All Debts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Filter", selection: $filterDirection) {
                        Text("All").tag(nil as DebtDirection?)
                        ForEach(DebtDirection.allCases, id: \.self) { dir in
                            Text(dir.displayLabel).tag(dir as DebtDirection?)
                        }
                    }

                    Toggle("Show Settled", isOn: $showSettled)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: $debtToEdit) { debt in
            if let contactId = debt.contact?.id, let contactName = debt.contact?.completeName {
                DebtFormView(
                    viewModel: viewModel,
                    contactId: contactId,
                    contactName: contactName,
                    existingDebt: debt
                )
            }
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
            await viewModel.fetchAllDebts()
        }
        .refreshable {
            await viewModel.fetchAllDebts()
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

    private var filteredDebts: [Debt] {
        var result = viewModel.debts

        // Filter by direction
        if let direction = filterDirection {
            result = result.filter { $0.direction == direction }
        }

        // Filter by status
        if !showSettled {
            result = result.filter { $0.isOutstanding }
        }

        return result
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Debts")
                .font(.title2)
                .fontWeight(.medium)

            Text("You don't have any debts recorded yet.\nAdd debts from individual contact pages.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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
                } header: {
                    Text("Net Balance")
                }
            }

            // Stats section
            Section {
                statsRow
            }

            // Debts grouped by contact
            let groupedDebts = Dictionary(grouping: filteredDebts) { $0.contactName }
            let sortedContactNames = groupedDebts.keys.sorted()

            ForEach(sortedContactNames, id: \.self) { contactName in
                Section {
                    ForEach(groupedDebts[contactName] ?? []) { debt in
                        DebtRowView(
                            debt: debt,
                            onMarkSettled: debt.isOutstanding ? {
                                Task {
                                    await viewModel.markAsSettled(debt: debt)
                                }
                            } : nil,
                            onEdit: {
                                debtToEdit = debt
                            },
                            onDelete: {
                                debtToDelete = debt
                                showDeleteConfirmation = true
                            },
                            showContactName: false
                        )
                    }
                } header: {
                    contactHeader(for: contactName, debts: groupedDebts[contactName] ?? [])
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var statsRow: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Outstanding")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.outstandingDebts.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .center) {
                Text("They Owe Me")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.debtsOwedToMe.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("I Owe Them")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.debtsIOweThem.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func contactHeader(for name: String, debts: [Debt]) -> some View {
        let outstanding = debts.filter { $0.isOutstanding }
        let total = outstanding.reduce(0.0) { sum, debt in
            if debt.direction == .theyOweMe {
                return sum + debt.amount
            } else {
                return sum - debt.amount
            }
        }

        return HStack {
            Text(name)
            Spacer()
            if outstanding.count > 0 {
                Text(total >= 0 ? "+$\(String(format: "%.2f", abs(total)))" : "-$\(String(format: "%.2f", abs(total)))")
                    .font(.caption)
                    .foregroundColor(total >= 0 ? .green : .red)
            }
        }
    }
}

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = DebtAPIService(apiClient: apiClient)
    return NavigationStack {
        GlobalDebtView(viewModel: DebtViewModel(apiService: apiService))
    }
}
