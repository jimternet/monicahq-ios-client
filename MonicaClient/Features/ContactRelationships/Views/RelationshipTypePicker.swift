import SwiftUI

/// View for selecting a relationship type, grouped by category
struct RelationshipTypePicker: View {
    @ObservedObject var viewModel: RelationshipViewModel
    @Binding var selectedType: RelationshipType?
    let sourceContactGender: String?
    let targetContactGender: String?

    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search/filter field
            searchField

            // Type list grouped by category
            if viewModel.isLoadingTypes {
                loadingView
            } else if filteredGroupedTypes.isEmpty {
                emptyStateView
            } else {
                typesList
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.secondaryText)

            TextField("Filter relationship types...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.small)
        .padding(Constants.UI.Spacing.medium)
    }

    // MARK: - Types List

    private var typesList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.UI.Spacing.medium) {
                ForEach(filteredGroupedTypes, id: \.0) { category, types in
                    categorySection(category: category, types: types)
                }
            }
            .padding(.horizontal, Constants.UI.Spacing.medium)
            .padding(.bottom, Constants.UI.Spacing.large)
        }
    }

    private func categorySection(category: RelationshipCategory, types: [RelationshipType]) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            // Category header
            HStack(spacing: Constants.UI.Spacing.small) {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.system(size: 14, weight: .medium))

                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)

                Spacer()

                Text("\(types.count)")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
            }
            .padding(.bottom, Constants.UI.Spacing.extraSmall)

            // Type rows
            VStack(spacing: Constants.UI.Spacing.extraSmall) {
                ForEach(types) { type in
                    RelationshipTypeRow(
                        type: type,
                        isSelected: selectedType?.id == type.id,
                        sourceContactGender: sourceContactGender,
                        targetContactGender: targetContactGender,
                        viewModel: viewModel,
                        onSelect: { selectedType = type }
                    )
                }
            }
        }
        .padding(.vertical, Constants.UI.Spacing.small)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            ProgressView()
            Text("Loading relationship types...")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.tertiaryText)

            Text("No relationship types found")
                .font(.headline)
                .foregroundColor(.secondaryText)

            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundColor(.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Filtered Types

    private var filteredGroupedTypes: [(RelationshipCategory, [RelationshipType])] {
        guard !searchText.isEmpty else {
            return viewModel.groupedRelationshipTypes
        }

        let query = searchText.lowercased()
        return viewModel.groupedRelationshipTypes.compactMap { category, types in
            let filteredTypes = types.filter { type in
                type.name.lowercased().contains(query) ||
                type.nameReverseRelationship.lowercased().contains(query)
            }
            guard !filteredTypes.isEmpty else { return nil }
            return (category, filteredTypes)
        }
    }
}

/// Row view for a single relationship type
struct RelationshipTypeRow: View {
    let type: RelationshipType
    let isSelected: Bool
    let sourceContactGender: String?
    let targetContactGender: String?
    @ObservedObject var viewModel: RelationshipViewModel
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .monicaBlue : .tertiaryText)
                    .font(.system(size: 20))

                // Relationship names
                VStack(alignment: .leading, spacing: 2) {
                    // Forward relationship (this contact is X of target)
                    Text(viewModel.displayName(for: type, gender: targetContactGender))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)

                    // Reverse relationship preview
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.tertiaryText)

                        Text(viewModel.reverseDisplayName(for: type, gender: sourceContactGender))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }

                Spacer()
            }
            .padding(Constants.UI.Spacing.medium)
            .background(isSelected ? Color.monicaBlue.opacity(0.1) : Color.secondaryBackground)
            .cornerRadius(Constants.UI.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.CornerRadius.small)
                    .stroke(isSelected ? Color.monicaBlue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel: RelationshipViewModel = {
            let apiClient = MonicaAPIClient(baseURL: "https://example.com", apiToken: "test")
            let service = RelationshipAPIService(apiClient: apiClient)
            return RelationshipViewModel(apiService: service)
        }()
        @State private var selectedType: RelationshipType?

        var body: some View {
            RelationshipTypePicker(
                viewModel: viewModel,
                selectedType: $selectedType,
                sourceContactGender: "male",
                targetContactGender: "female"
            )
        }
    }

    return PreviewWrapper()
}
