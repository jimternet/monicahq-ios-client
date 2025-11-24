//
//  AddressFormView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// Form for creating or editing an address
struct AddressFormView: View {
    @ObservedObject var viewModel: AddressFormViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingCountryPicker = false

    var body: some View {
        NavigationView {
            Form {
                // Label Section
                Section(header: Text("Label")) {
                    TextField("Label (e.g., Home, Work)", text: $viewModel.name)
                        .textContentType(.addressCity) // Helps with autofill suggestions
                }

                // Address Fields Section
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $viewModel.street)
                        .textContentType(.streetAddressLine1)

                    TextField("City", text: $viewModel.city)
                        .textContentType(.addressCity)

                    TextField(viewModel.provinceLabel, text: $viewModel.province)
                        .textContentType(.addressState)

                    TextField(viewModel.postalCodeLabel, text: $viewModel.postalCode)
                        .textContentType(.postalCode)
                }

                // Country Section
                Section(header: Text("Country")) {
                    Button {
                        showingCountryPicker = true
                    } label: {
                        HStack {
                            if let country = viewModel.selectedCountry {
                                Text(country.flagEmoji)
                                Text(country.name)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Country")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                // Validation hint
                if !viewModel.isValid {
                    Section {
                        Text("Please fill in at least street, city, or select a country")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Error display
                if case .error(let message) = viewModel.state {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Address" : "Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.state == .saving)
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(
                    countries: viewModel.countries,
                    selectedCountry: $viewModel.selectedCountry,
                    isLoading: viewModel.isLoadingCountries
                )
            }
            .task {
                await viewModel.loadCountries()
            }
            .overlay {
                if viewModel.state == .saving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddressFormView(
        viewModel: AddressFormViewModel(
            contactId: 1,
            apiClient: MonicaAPIClient(baseURL: "", apiToken: "")
        )
    )
}
