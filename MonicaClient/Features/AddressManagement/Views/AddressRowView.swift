//
//  AddressRowView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// A single row displaying an address with label and formatted text
struct AddressRowView: View {

    let address: Address
    var onTap: (() -> Void)?
    var onDirections: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label badge
            Text(address.displayLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(labelColor)
                .cornerRadius(4)

            // Formatted address
            Text(address.formattedAddress)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            // Action buttons row
            HStack(spacing: 16) {
                if onDirections != nil {
                    Button {
                        onDirections?()
                    } label: {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .font(.caption)
                    }
                }

                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - Label Color

    private var labelColor: Color {
        switch address.displayLabel.lowercased() {
        case "home":
            return .blue
        case "work":
            return .orange
        default:
            return .gray
        }
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = address.formattedAddress
    }
}

// MARK: - Preview

#Preview {
    List {
        AddressRowView(
            address: Address(
                id: 1,
                object: "address",
                name: "Home",
                street: "123 Main Street",
                city: "San Francisco",
                province: "CA",
                postalCode: "94102",
                country: Country.unitedStates,
                latitude: 37.7749,
                longitude: -122.4194,
                contact: nil,
                account: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            onDirections: {}
        )

        AddressRowView(
            address: Address(
                id: 2,
                object: "address",
                name: "Work",
                street: "456 Market Street",
                city: "San Francisco",
                province: "CA",
                postalCode: "94103",
                country: Country.unitedStates,
                latitude: nil,
                longitude: nil,
                contact: nil,
                account: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            onDirections: {}
        )
    }
}
