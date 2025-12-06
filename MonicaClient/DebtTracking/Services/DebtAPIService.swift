import Foundation

/// Service layer for debt tracking API operations
/// Wraps MonicaAPIClient debt methods with feature-specific logic
@MainActor
class DebtAPIService {
    private let apiClient: MonicaAPIClient

    init(apiClient: MonicaAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Fetch Operations

    /// Fetch all debts for a specific contact
    func fetchDebts(for contactId: Int) async throws -> [Debt] {
        let response = try await apiClient.getDebts(for: contactId)
        return response.data
    }

    /// Fetch all debts across all contacts (for global view)
    func fetchAllDebts(limit: Int = 100) async throws -> [Debt] {
        let response = try await apiClient.getAllDebts(limit: limit)
        return response.data
    }

    // MARK: - Create Operations

    /// Create a new debt record
    /// - Parameters:
    ///   - contactId: The contact ID
    ///   - direction: Debt direction (theyOweMe or iOweThem)
    ///   - amount: The debt amount (must be > 0)
    ///   - reason: Optional reason/description
    /// - Returns: The created debt
    func createDebt(
        for contactId: Int,
        direction: DebtDirection,
        amount: Double,
        reason: String?
    ) async throws -> Debt {
        let response = try await apiClient.createDebt(
            for: contactId,
            inDebt: direction.rawValue,
            status: DebtStatus.outstanding.rawValue,
            amount: amount,
            reason: reason
        )
        return response.data
    }

    // MARK: - Update Operations

    /// Mark a debt as settled
    func markAsSettled(debtId: Int, contactId: Int) async throws -> Debt {
        let response = try await apiClient.updateDebt(
            id: debtId,
            contactId: contactId,
            inDebt: nil,
            status: DebtStatus.settled.rawValue,
            amount: nil,
            reason: nil
        )
        return response.data
    }

    /// Update a debt with new values
    func updateDebt(
        debtId: Int,
        contactId: Int,
        direction: DebtDirection?,
        amount: Double?,
        reason: String?
    ) async throws -> Debt {
        let response = try await apiClient.updateDebt(
            id: debtId,
            contactId: contactId,
            inDebt: direction?.rawValue,
            status: nil,
            amount: amount,
            reason: reason
        )
        return response.data
    }

    /// Update debt status (settle or reopen)
    func updateDebtStatus(
        debtId: Int,
        contactId: Int,
        status: DebtStatus
    ) async throws -> Debt {
        let response = try await apiClient.updateDebt(
            id: debtId,
            contactId: contactId,
            inDebt: nil,
            status: status.rawValue,
            amount: nil,
            reason: nil
        )
        return response.data
    }

    // MARK: - Delete Operations

    /// Delete a debt record
    func deleteDebt(debtId: Int) async throws {
        try await apiClient.deleteDebt(id: debtId)
    }
}
