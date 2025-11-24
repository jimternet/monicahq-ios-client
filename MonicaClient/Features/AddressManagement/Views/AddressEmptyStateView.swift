//
//  AddressEmptyStateView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// Empty state view shown when a contact has no addresses
struct AddressEmptyStateView: View {

    var onAdd: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Addresses")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Add an address to keep track of where this contact lives or works.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let onAdd = onAdd {
                Button(action: onAdd) {
                    Label("Add Address", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Preview

#Preview {
    List {
        Section("Addresses") {
            AddressEmptyStateView {
                print("Add tapped")
            }
        }
    }
}
