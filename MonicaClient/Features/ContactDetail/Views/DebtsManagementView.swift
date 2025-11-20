import SwiftUI

struct DebtsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var debts: [Debt] = []
    @State private var isLoading = true
    @State private var showingAddDebt = false
    @State private var editingDebt: Debt?
    @State private var errorMessage: String?
    @State private var showingError = false

    var owedToYou: [Debt] {
        debts.filter { $0.inDebt }
    }

    var owedByYou: [Debt] {
        debts.filter { !$0.inDebt }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading debts...")
                } else if debts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Debts")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Track money owed to or by \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddDebt = true }) {
                            Label("Add Debt", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        if !owedToYou.isEmpty {
                            Section("Owed to You") {
                                ForEach(owedToYou) { debt in
                                    DebtRowView(debt: debt, onEdit: {
                                        editingDebt = debt
                                    }, onDelete: {
                                        deleteDebt(debt)
                                    })
                                }
                            }
                        }

                        if !owedByYou.isEmpty {
                            Section("You Owe") {
                                ForEach(owedByYou) { debt in
                                    DebtRowView(debt: debt, onEdit: {
                                        editingDebt = debt
                                    }, onDelete: {
                                        deleteDebt(debt)
                                    })
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadDebts()
                    }
                }
            }
            .navigationTitle("Debts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !debts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddDebt = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadDebts()
        }
        .sheet(isPresented: $showingAddDebt) {
            AddDebtView(contact: contact) { newDebt in
                debts.insert(newDebt, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingDebt) { debt in
            EditDebtView(debt: debt) { updatedDebt in
                if let index = debts.firstIndex(where: { $0.id == updatedDebt.id }) {
                    debts[index] = updatedDebt
                }
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
    private func loadDebts() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getDebts(for: contact.id)
            debts = response.data.sorted { $0.createdAt > $1.createdAt }
            print("✅ Loaded \(debts.count) debts")
        } catch {
            errorMessage = "Failed to load debts: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load debts: \(error)")
        }
        isLoading = false
    }

    private func deleteDebt(_ debt: Debt) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteDebt(id: debt.id)
                await MainActor.run {
                    debts.removeAll { $0.id == debt.id }
                }
                print("✅ Deleted debt")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete debt: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete debt: \(error)")
            }
        }
    }
}

struct DebtRowView: View {
    let debt: Debt
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("$\(String(format: "%.2f", debt.amount))")
                    .font(.headline)
                    .foregroundColor(debt.inDebt ? .green : .red)

                Spacer()

                statusBadge
            }

            if let reason = debt.reason, !reason.isEmpty {
                Text(reason)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text(debt.inDebt ? "They owe you" : "You owe them")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(debt.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private var statusBadge: some View {
        Text(debt.status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch debt.status.lowercased() {
        case "paid", "complete", "settled":
            return .green
        case "inprogress", "in progress":
            return .orange
        default:
            return .blue
        }
    }
}

struct AddDebtView: View {
    let contact: Contact
    let onDebtAdded: (Debt) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var reason = ""
    @State private var inDebt = true  // true = they owe you, false = you owe them
    @State private var status = "inprogress"
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    let statuses = [
        ("inprogress", "In Progress"),
        ("paid", "Paid"),
        ("complete", "Complete")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Debt Details") {
                    Picker("Direction", selection: $inDebt) {
                        Text("They owe you").tag(true)
                        Text("You owe them").tag(false)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.0) { status in
                            Text(status.1).tag(status.0)
                        }
                    }
                }

                Section("Reason") {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitDebt()
                    }
                    .disabled(amount.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitDebt() {
        guard let apiClient = authManager.currentAPIClient else { return }
        guard let amountValue = Double(amount) else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createDebt(
                    for: contact.id,
                    inDebt: inDebt,
                    status: status,
                    amount: amountValue,
                    reason: reason.isEmpty ? nil : reason
                )

                await MainActor.run {
                    onDebtAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create debt: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditDebtView: View {
    let debt: Debt
    let onDebtUpdated: (Debt) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String
    @State private var reason: String
    @State private var status: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    let statuses = [
        ("inprogress", "In Progress"),
        ("paid", "Paid"),
        ("complete", "Complete")
    ]

    init(debt: Debt, onDebtUpdated: @escaping (Debt) -> Void) {
        self.debt = debt
        self.onDebtUpdated = onDebtUpdated
        _amount = State(initialValue: String(format: "%.2f", debt.amount))
        _reason = State(initialValue: debt.reason ?? "")
        _status = State(initialValue: debt.status)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Debt Details") {
                    HStack {
                        Text(debt.inDebt ? "They owe you" : "You owe them")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.0) { status in
                            Text(status.1).tag(status.0)
                        }
                    }
                }

                Section("Reason") {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitDebt()
                    }
                    .disabled(amount.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitDebt() {
        guard let apiClient = authManager.currentAPIClient else { return }
        guard let amountValue = Double(amount) else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }

        Task {
            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.updateDebt(
                    id: debt.id,
                    status: status,
                    amount: amountValue,
                    reason: reason.isEmpty ? nil : reason
                )

                await MainActor.run {
                    onDebtUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update debt: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}
