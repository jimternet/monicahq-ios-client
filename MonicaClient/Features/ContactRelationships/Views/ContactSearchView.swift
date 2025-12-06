import SwiftUI

/// View for searching and selecting a contact to create a relationship with
struct ContactSearchView: View {
    @ObservedObject var viewModel: RelationshipViewModel
    let excludeContactId: Int
    let onContactSelected: (Contact) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            searchField

            // Results
            if viewModel.isSearching {
                loadingView
            } else if !searchText.isEmpty && viewModel.searchResults.isEmpty {
                emptyStateView
            } else if !viewModel.searchResults.isEmpty {
                resultsList
            } else {
                instructionsView
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)

            TextField("Search contacts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    Task {
                        await viewModel.searchContacts(
                            query: newValue,
                            excludeContactId: excludeContactId
                        )
                    }
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearchResults()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.small)
        .padding(Constants.UI.Spacing.medium)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.UI.Spacing.small) {
                ForEach(viewModel.searchResults) { contact in
                    ContactSearchRow(contact: contact) {
                        onContactSelected(contact)
                    }
                }
            }
            .padding(.horizontal, Constants.UI.Spacing.medium)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(.tertiaryText)

            Text("No contacts found")
                .font(.headline)
                .foregroundColor(.secondaryText)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.tertiaryText)

            Text("Search for a contact")
                .font(.headline)
                .foregroundColor(.secondaryText)

            Text("Type a name to find the contact you want to create a relationship with")
                .font(.subheadline)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Row view for displaying a contact in search results
struct ContactSearchRow: View {
    let contact: Contact
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                // Avatar
                contactAvatar

                // Contact info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.completeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)

                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(Constants.UI.Spacing.medium)
            .background(Color.secondaryBackground)
            .cornerRadius(Constants.UI.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var contactAvatar: some View {
        if let avatarURL = contact.avatarURL, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsAvatar
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            initialsAvatar
        }
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(avatarColor.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Text(contact.initials)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(avatarColor)
            )
    }

    private var avatarColor: Color {
        if let colorString = contact.avatarColor {
            return Color(hex: colorString) ?? .monicaBlue
        }
        return .monicaBlue
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel: RelationshipViewModel = {
            let apiClient = MonicaAPIClient(baseURL: "https://example.com", apiToken: "test")
            let service = RelationshipAPIService(apiClient: apiClient)
            return RelationshipViewModel(apiService: service)
        }()

        var body: some View {
            ContactSearchView(
                viewModel: viewModel,
                excludeContactId: 1,
                onContactSelected: { contact in
                    print("Selected: \(contact.completeName)")
                }
            )
        }
    }

    return PreviewWrapper()
}
