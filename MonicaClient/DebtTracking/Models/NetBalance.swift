import Foundation

/// Calculated net balance for a contact (per currency)
/// Positive = contact owes user, Negative = user owes contact
struct NetBalance: Identifiable {
    let currency: String          // Currency symbol/code from amountWithCurrency
    let theyOweMe: Double         // Sum of debts where direction = "yes"
    let iOweThem: Double          // Sum of debts where direction = "no"

    var id: String { currency }

    var netAmount: Double {
        theyOweMe - iOweThem
    }

    var displayNet: String {
        let sign = netAmount >= 0 ? "+" : ""
        return "\(sign)\(currency)\(String(format: "%.2f", abs(netAmount)))"
    }

    var isPositive: Bool {
        netAmount >= 0
    }

    var summary: String {
        if netAmount > 0 {
            return "They owe you \(currency)\(String(format: "%.2f", netAmount))"
        } else if netAmount < 0 {
            return "You owe \(currency)\(String(format: "%.2f", abs(netAmount)))"
        } else {
            return "Settled"
        }
    }
}
