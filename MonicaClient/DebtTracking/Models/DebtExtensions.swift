import Foundation
import SwiftUI

/// Computed properties and helper methods for Debt model
extension Debt {
    /// Direction enum from raw string
    var direction: DebtDirection {
        DebtDirection(rawValue: inDebt) ?? .theyOweMe
    }

    /// Status enum from raw string
    var debtStatus: DebtStatus {
        DebtStatus(rawValue: status) ?? .outstanding
    }

    /// Whether debt is still outstanding
    var isOutstanding: Bool {
        status == "inprogress"
    }

    /// Whether debt is settled
    var isSettled: Bool {
        status == "completed"
    }

    /// Display name for contact (from nested object or fallback)
    var contactName: String {
        contact?.completeName ?? "Unknown"
    }

    /// Contact ID from nested object
    var contactId: Int {
        contact?.id ?? 0
    }

    /// Formatted creation date
    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// Formatted settled date (if applicable)
    var settledDate: String? {
        guard isSettled else { return nil }
        return updatedAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// Display amount with currency
    var displayAmount: String {
        amountWithCurrency ?? String(format: "$%.2f", amount)
    }

    /// Color for direction indicator
    var directionColor: Color {
        direction.color
    }

    /// Icon for debt status
    var statusIcon: String {
        debtStatus.icon
    }

    /// Label describing the debt direction
    var directionLabel: String {
        direction.displayLabel
    }

    /// Short label for debt direction
    var directionShortLabel: String {
        direction.shortLabel
    }
}
