//
//  CountryPickerView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

/// Searchable country picker view
struct CountryPickerView: View {
    let countries: [Country]
    @Binding var selectedCountry: Country?
    let isLoading: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // MARK: - Computed Properties

    /// Filtered countries based on search text
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countries
        }
        return countries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText) ||
            country.iso.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if countries.isEmpty {
                    emptyView
                } else {
                    countryList
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if selectedCountry != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedCountry = nil
                            dismiss()
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading countries...")
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No countries available")
                .foregroundColor(.secondary)
            Text("Could not load country list from server")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var countryList: some View {
        List {
            ForEach(filteredCountries) { country in
                Button {
                    selectedCountry = country
                    dismiss()
                } label: {
                    HStack {
                        Text(country.flagEmoji)
                            .font(.title2)
                        Text(country.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCountry?.id == country.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Countries") {
    CountryPickerView(
        countries: Country.previewCountries,
        selectedCountry: .constant(nil),
        isLoading: false
    )
}

#Preview("Loading") {
    CountryPickerView(
        countries: [],
        selectedCountry: .constant(nil),
        isLoading: true
    )
}

#Preview("Empty") {
    CountryPickerView(
        countries: [],
        selectedCountry: .constant(nil),
        isLoading: false
    )
}
