import Foundation
import SwiftUI

/// ViewModel for debt tracking feature
/// Manages state and business logic for debt CRUD operations
@MainActor
class DebtViewModel: ObservableObject {
    // MARK: - Published State

    @Published var debts: [Debt] = []
    @Published var netBalances: [NetBalance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiService: DebtAPIService

    // MARK: - Initialization

    init(apiService: DebtAPIService) {
        self.apiService = apiService
    }

    // MARK: - Computed Properties

    /// Outstanding debts only
    var outstandingDebts: [Debt] {
        debts.filter { $0.isOutstanding }
    }

    /// Settled debts only
    var settledDebts: [Debt] {
        debts.filter { $0.isSettled }
    }

    /// Debts where contact owes user
    var debtsOwedToMe: [Debt] {
        debts.filter { $0.direction == .theyOweMe && $0.isOutstanding }
    }

    /// Debts where user owes contact
    var debtsIOweThem: [Debt] {
        debts.filter { $0.direction == .iOweThem && $0.isOutstanding }
    }

    // MARK: - Fetch Operations

    /// Fetch debts for a specific contact
    func fetchDebts(contactId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            debts = try await apiService.fetchDebts(for: contactId)
            calculateNetBalances()
        } catch {
            errorMessage = "Failed to load debts: \(error.localizedDescription)"
            print("❌ Error fetching debts: \(error)")
        }

        isLoading = false
    }

    /// Fetch all debts across all contacts (for global view)
    func fetchAllDebts() async {
        isLoading = true
        errorMessage = nil

        do {
            debts = try await apiService.fetchAllDebts()
            calculateNetBalances()
        } catch {
            errorMessage = "Failed to load debts: \(error.localizedDescription)"
            print("❌ Error fetching all debts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Create Operations

    /// Create a new debt
    func createDebt(
        contactId: Int,
        direction: DebtDirection,
        amount: Double,
        reason: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newDebt = try await apiService.createDebt(
                for: contactId,
                direction: direction,
                amount: amount,
                reason: reason
            )
            debts.insert(newDebt, at: 0)
            calculateNetBalances()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create debt: \(error.localizedDescription)"
            print("❌ Error creating debt: \(error)")
            isLoading = false
            return false
        }
    }

    // MARK: - Update Operations

    /// Mark a debt as settled
    func markAsSettled(debt: Debt) async -> Bool {
        guard debt.isOutstanding else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let contactId = debt.contact?.id ?? 0
            let updatedDebt = try await apiService.markAsSettled(
                debtId: debt.id,
                contactId: contactId
            )

            if let index = debts.firstIndex(where: { $0.id == debt.id }) {
                debts[index] = updatedDebt
            }
            calculateNetBalances()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to settle debt: \(error.localizedDescription)"
            print("❌ Error settling debt: \(error)")
            isLoading = false
            return false
        }
    }

    /// Update a debt
    func updateDebt(
        debt: Debt,
        direction: DebtDirection?,
        amount: Double?,
        reason: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let contactId = debt.contact?.id ?? 0
            let updatedDebt = try await apiService.updateDebt(
                debtId: debt.id,
                contactId: contactId,
                direction: direction,
                amount: amount,
                reason: reason
            )

            if let index = debts.firstIndex(where: { $0.id == debt.id }) {
                debts[index] = updatedDebt
            }
            calculateNetBalances()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update debt: \(error.localizedDescription)"
            print("❌ Error updating debt: \(error)")
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Operations

    /// Delete a debt
    func deleteDebt(_ debt: Debt) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteDebt(debtId: debt.id)
            debts.removeAll { $0.id == debt.id }
            calculateNetBalances()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete debt: \(error.localizedDescription)"
            print("❌ Error deleting debt: \(error)")
            isLoading = false
            return false
        }
    }

    // MARK: - Net Balance Calculation

    /// Calculate net balances per currency from outstanding debts
    func calculateNetBalances() {
        var balancesByCurrency: [String: (theyOweMe: Double, iOweThem: Double)] = [:]

        for debt in outstandingDebts {
            // Extract currency from amountWithCurrency (e.g., "$50.00" -> "$")
            let currency = extractCurrency(from: debt.amountWithCurrency ?? "$\(debt.amount)")

            var current = balancesByCurrency[currency] ?? (0, 0)

            if debt.direction == .theyOweMe {
                current.theyOweMe += debt.amount
            } else {
                current.iOweThem += debt.amount
            }

            balancesByCurrency[currency] = current
        }

        netBalances = balancesByCurrency.map { currency, amounts in
            NetBalance(
                currency: currency,
                theyOweMe: amounts.theyOweMe,
                iOweThem: amounts.iOweThem
            )
        }.sorted { $0.currency < $1.currency }
    }

    /// Extract currency symbol from formatted amount string
    private func extractCurrency(from amountString: String) -> String {
        // Common currency symbols
        let currencySymbols = ["$", "€", "£", "¥", "₹", "₽", "₿", "kr", "R$", "A$", "C$", "HK$", "NZ$", "S$", "CHF"]

        for symbol in currencySymbols {
            if amountString.contains(symbol) {
                return symbol
            }
        }

        // Try to extract first non-numeric character
        let nonNumeric = amountString.filter { !$0.isNumber && $0 != "." && $0 != "," && $0 != "-" }
        if let first = nonNumeric.first {
            return String(first)
        }

        return "$" // Default fallback
    }

    // MARK: - Filtering

    /// Filter debts by direction
    func filteredDebts(direction: DebtDirection?) -> [Debt] {
        guard let direction = direction else { return debts }
        return debts.filter { $0.direction == direction }
    }

    /// Filter outstanding debts by direction
    func filteredOutstandingDebts(direction: DebtDirection?) -> [Debt] {
        guard let direction = direction else { return outstandingDebts }
        return outstandingDebts.filter { $0.direction == direction }
    }
}
