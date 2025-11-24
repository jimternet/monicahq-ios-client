//
//  AddressListView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// List view displaying all addresses for a contact
struct AddressListView: View {

    @ObservedObject var viewModel: AddressViewModel

    var onAddAddress: (() -> Void)?
    var onEditAddress: ((Address) -> Void)?
    var onDirections: ((Address) -> Void)?
    var onMapTap: ((Address) -> Void)?
    var onDeleteAddress: ((Address) -> Void)?

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView

            case .empty:
                AddressEmptyStateView(onAdd: onAddAddress)

            case .loaded(let addresses):
                addressList(addresses)

            case .error(let message):
                errorView(message)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    // MARK: - Address List

    private func addressList(_ addresses: [Address]) -> some View {
        ForEach(addresses) { address in
            AddressRowView(
                address: address,
                onTap: { onMapTap?(address) },
                onDirections: { onDirections?(address) }
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    onDeleteAddress?(address)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    onEditAddress?(address)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            Section("Addresses") {
                AddressListView(
                    viewModel: {
                        let vm = AddressViewModel(
                            contactId: 1,
                            apiClient: MonicaAPIClient(baseURL: "https://example.com", apiToken: "test")
                        )
                        return vm
                    }()
                )
            }
        }
        .navigationTitle("Contact")
    }
}
