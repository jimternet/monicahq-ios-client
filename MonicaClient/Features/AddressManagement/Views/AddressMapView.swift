//
//  AddressMapView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI
import MapKit

/// Full-screen map view showing an address location
struct AddressMapView: View {
    let address: Address
    let contactName: String?

    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var errorMessage: String?
    @State private var isLoading = false

    // MARK: - Initialization

    init(address: Address, contactName: String? = nil) {
        self.address = address
        self.contactName = contactName

        // Initialize region with address coordinates or default
        let coordinate = address.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                if let error = errorMessage {
                    errorView(error)
                } else {
                    mapView
                }

                if isLoading {
                    ProgressView("Loading map...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .navigationTitle(address.displayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "arrow.up.right.square")
                    }
                }
            }
            .task {
                await loadCoordinatesIfNeeded()
            }
        }
    }

    // MARK: - Subviews

    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: [address]) { addr in
            MapAnnotation(coordinate: addr.coordinate ?? region.center) {
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)

                    Text(contactName ?? addr.displayLabel)
                        .font(.caption)
                        .padding(4)
                        .background(Color(.systemBackground))
                        .cornerRadius(4)
                        .shadow(radius: 2)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Unable to show map")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadCoordinatesIfNeeded()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Private Methods

    private func loadCoordinatesIfNeeded() async {
        // If we already have coordinates, we're good
        if address.hasCoordinates {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let coordinate = try await GeocodingService.shared.geocodeAddress(address)
            await MainActor.run {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func openInMaps() {
        Task {
            do {
                try await GeocodingService.shared.openMap(for: address, contactName: contactName)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddressMapView(
        address: Address(
            id: 1,
            object: "address",
            name: "Home",
            street: "123 Main St",
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
        contactName: "John Doe"
    )
}
