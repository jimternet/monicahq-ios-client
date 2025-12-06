import SwiftUI

/// Form view for creating and editing debt records
struct DebtFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DebtViewModel

    let contactId: Int
    let contactName: String
    var existingDebt: Debt?

    // Form state
    @State private var direction: DebtDirection = .theyOweMe
    @State private var amountText: String = ""
    @State private var reason: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDirectionChangeConfirmation = false
    @State private var pendingDirection: DebtDirection?

    var isEditing: Bool {
        existingDebt != nil
    }

    var title: String {
        isEditing ? "Edit Debt" : "Add Debt"
    }

    var isValid: Bool {
        guard let amount = Double(amountText) else { return false }
        return amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Direction picker
                Section {
                    Picker("Direction", selection: $direction) {
                        ForEach(DebtDirection.allCases, id: \.self) { dir in
                            HStack {
                                Circle()
                                    .fill(dir.color)
                                    .frame(width: 12, height: 12)
                                Text(dir.displayLabel)
                            }
                            .tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: direction) { newValue in
                        if isEditing, let existing = existingDebt, existing.direction != newValue {
                            pendingDirection = newValue
                            showDirectionChangeConfirmation = true
                            direction = existing.direction // Revert until confirmed
                        }
                    }
                } header: {
                    Text("Who owes whom?")
                }

                // Amount section
                Section {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Amount")
                } footer: {
                    if !amountText.isEmpty, Double(amountText) == nil {
                        Text("Please enter a valid number")
                            .foregroundColor(.red)
                    } else if let amount = Double(amountText), amount <= 0 {
                        Text("Amount must be greater than zero")
                            .foregroundColor(.red)
                    }
                }

                // Reason section
                Section {
                    TextField("What's this for?", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Reason (optional)")
                }

                // Preview section
                Section {
                    HStack {
                        Circle()
                            .fill(direction.color)
                            .frame(width: 12, height: 12)
                        Text(previewText)
                            .font(.subheadline)
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        Task {
                            await saveDebt()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Change Direction?", isPresented: $showDirectionChangeConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingDirection = nil
                }
                Button("Change", role: .destructive) {
                    if let newDir = pendingDirection {
                        direction = newDir
                    }
                    pendingDirection = nil
                }
            } message: {
                Text("This will affect your net balance with \(contactName)")
            }
            .onAppear {
                if let debt = existingDebt {
                    direction = debt.direction
                    amountText = String(format: "%.2f", debt.amount)
                    reason = debt.reason ?? ""
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }

    private var previewText: String {
        let amountStr = Double(amountText).map { String(format: "$%.2f", $0) } ?? "$0.00"
        switch direction {
        case .theyOweMe:
            return "\(contactName) owes you \(amountStr)"
        case .iOweThem:
            return "You owe \(contactName) \(amountStr)"
        }
    }

    private func saveDebt() async {
        guard let amount = Double(amountText), amount > 0 else {
            errorMessage = "Please enter a valid amount greater than zero"
            showError = true
            return
        }

        isSaving = true

        let success: Bool
        if let existing = existingDebt {
            success = await viewModel.updateDebt(
                debt: existing,
                direction: direction != existing.direction ? direction : nil,
                amount: amount != existing.amount ? amount : nil,
                reason: reason.isEmpty ? nil : reason
            )
        } else {
            success = await viewModel.createDebt(
                contactId: contactId,
                direction: direction,
                amount: amount,
                reason: reason.isEmpty ? nil : reason
            )
        }

        isSaving = false

        if success {
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to save debt"
            showError = true
        }
    }
}

#Preview {
    let apiClient = MonicaAPIClient(
        baseURL: "https://monica.example.com",
        apiToken: "preview-token"
    )
    let apiService = DebtAPIService(apiClient: apiClient)
    return DebtFormView(
        viewModel: DebtViewModel(apiService: apiService),
        contactId: 1,
        contactName: "John Doe"
    )
}
