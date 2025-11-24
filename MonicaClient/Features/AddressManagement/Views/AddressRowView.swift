//
//  AddressRowView.swift
//  MonicaClient
//
//  Created for 002-contact-addresses feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI
import MapKit

/// A single row displaying an address with label, formatted text, and optional map preview
struct AddressRowView: View {

    let address: Address
    var onTap: (() -> Void)?
    var onDirections: (() -> Void)?

    @State private var region: MKCoordinateRegion?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 12) {
                // Left side: Label and address text
                VStack(alignment: .leading, spacing: 4) {
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
                        .lineLimit(4)
                }

                Spacer()

                // Right side: Map preview (if coordinates available)
                if address.hasCoordinates, let coordinate = address.coordinate {
                    mapPreview(coordinate: coordinate)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if onDirections != nil {
                Button {
                    onDirections?()
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
            }

            Button {
                copyToClipboard()
            } label: {
                Label("Copy Address", systemImage: "doc.on.doc")
            }

            Button {
                shareAddress()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .onAppear {
            setupRegion()
        }
    }

    // MARK: - Map Preview

    @ViewBuilder
    private func mapPreview(coordinate: CLLocationCoordinate2D) -> some View {
        if let region = region {
            Map(coordinateRegion: .constant(region), annotationItems: [AddressAnnotation(coordinate: coordinate)]) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
            .frame(width: 80, height: 60)
            .cornerRadius(8)
            .disabled(true)
        }
    }

    private func setupRegion() {
        if let coordinate = address.coordinate {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
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

    private func shareAddress() {
        let activityVC = UIActivityViewController(
            activityItems: [address.formattedAddress],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Address Annotation

struct AddressAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
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
            )
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
            )
        )
    }
}
