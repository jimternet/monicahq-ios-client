import SwiftUI

/// View showing net balance summary per currency
struct DebtSummaryView: View {
    let netBalances: [NetBalance]

    var body: some View {
        if netBalances.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Net Balance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ForEach(netBalances) { balance in
                    HStack {
                        Circle()
                            .fill(balance.isPositive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(balance.summary)
                            .font(.body)
                            .foregroundColor(balance.isPositive ? .green : .red)

                        Spacer()

                        Text(balance.displayNet)
                            .font(.headline)
                            .foregroundColor(balance.isPositive ? .green : .red)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
}

/// Compact version for inline display
struct DebtSummaryCompactView: View {
    let netBalances: [NetBalance]

    var body: some View {
        if netBalances.isEmpty {
            Text("No outstanding debts")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            HStack(spacing: 8) {
                ForEach(netBalances) { balance in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(balance.isPositive ? Color.green : Color.red)
                            .frame(width: 6, height: 6)

                        Text(balance.displayNet)
                            .font(.subheadline)
                            .foregroundColor(balance.isPositive ? .green : .red)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DebtSummaryView(netBalances: [
            NetBalance(currency: "$", theyOweMe: 150, iOweThem: 50),
            NetBalance(currency: "€", theyOweMe: 0, iOweThem: 30)
        ])

        DebtSummaryCompactView(netBalances: [
            NetBalance(currency: "$", theyOweMe: 100, iOweThem: 0)
        ])
    }
    .padding()
}
