import SwiftUI

/// Row view for displaying a single debt entry
struct DebtRowView: View {
    let debt: Debt
    var onMarkSettled: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var showContactName: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Direction indicator
            Circle()
                .fill(debt.directionColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                // Amount and direction
                HStack {
                    Text(debt.displayAmount)
                        .font(.headline)
                        .strikethrough(debt.isSettled)
                        .opacity(debt.isSettled ? 0.6 : 1.0)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(debt.directionShortLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Contact name (for global view)
                if showContactName {
                    Text(debt.contactName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                // Reason
                if let reason = debt.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Date info
                HStack(spacing: 8) {
                    Text(debt.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let settledDate = debt.settledDate {
                        Text("• Settled \(settledDate)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Status badge
            if debt.isSettled {
                Image(systemName: debt.statusIcon)
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            if debt.isOutstanding, let onMarkSettled = onMarkSettled {
                Button {
                    onMarkSettled()
                } label: {
                    Label("Settle", systemImage: "checkmark.circle")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }
}

#Preview {
    List {
        // Preview requires creating a sample Debt
        // In real usage, Debt comes from API
        Text("DebtRowView Preview")
    }
}
