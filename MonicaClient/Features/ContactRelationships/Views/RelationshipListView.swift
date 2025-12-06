import SwiftUI

/// Full-screen view for managing all relationships for a contact
struct RelationshipListView: View {
    @ObservedObject var viewModel: RelationshipViewModel
    let contact: Contact
    let onContactTap: (Int) -> Void

    @State private var showingAddRelationship = false
    @State private var relationshipToEdit: Relationship?
    @State private var relationshipToDelete: Relationship?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.isLoadingRelationships {
                loadingView
            } else if viewModel.relationships.isEmpty {
                emptyStateView
            } else {
                relationshipsList
            }
        }
        .navigationTitle("Relationships")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddRelationship = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRelationship) {
            RelationshipFormView(
                viewModel: viewModel,
                sourceContact: contact,
                existingRelationship: nil,
                onSave: {
                    Task {
                        await viewModel.refreshRelationships()
                    }
                }
            )
        }
        .sheet(item: $relationshipToEdit) { relationship in
            RelationshipFormView(
                viewModel: viewModel,
                sourceContact: contact,
                existingRelationship: relationship,
                onSave: {
                    Task {
                        await viewModel.refreshRelationships()
                    }
                }
            )
        }
        .alert("Delete Relationship?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let relationship = relationshipToDelete {
                    Task {
                        await viewModel.deleteRelationship(relationshipId: relationship.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                relationshipToDelete = nil
            }
        } message: {
            if let relationship = relationshipToDelete {
                Text("This will remove the relationship with \(relationship.ofContact.completeName).")
            }
        }
        .refreshable {
            await viewModel.refreshRelationships()
        }
        .task {
            await viewModel.loadRelationshipTypesIfNeeded()
            await viewModel.loadRelationships(for: contact.id)
        }
    }

    // MARK: - Relationships List

    private var relationshipsList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.UI.Spacing.medium) {
                ForEach(viewModel.groupedRelationships, id: \.0) { category, relationships in
                    categorySection(category: category, relationships: relationships)
                }
            }
            .padding(Constants.UI.Spacing.medium)
        }
    }

    private func categorySection(category: RelationshipCategory, relationships: [Relationship]) -> some View {
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

                Text("\(relationships.count)")
                    .font(.caption)
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
            }

            // Relationship rows
            VStack(spacing: Constants.UI.Spacing.small) {
                ForEach(relationships) { relationship in
                    RelationshipListRow(
                        relationship: relationship,
                        category: category,
                        viewModel: viewModel,
                        onTap: { onContactTap(relationship.ofContact.id) },
                        onEdit: { relationshipToEdit = relationship },
                        onDelete: {
                            relationshipToDelete = relationship
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.medium)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            ProgressView()
            Text("Loading relationships...")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.large) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.tertiaryText)

            VStack(spacing: Constants.UI.Spacing.small) {
                Text("No Relationships")
                    .font(.headline)
                    .foregroundColor(.primaryText)

                Text("Add family members, friends, and colleagues to keep track of how \(contact.completeName) is connected to others.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: { showingAddRelationship = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Relationship")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Constants.UI.Spacing.large)
                .padding(.vertical, Constants.UI.Spacing.medium)
                .background(Color.monicaBlue)
                .cornerRadius(Constants.UI.CornerRadius.medium)
            }
        }
        .padding(Constants.UI.Spacing.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Row view for a relationship in the full list
struct RelationshipListRow: View {
    let relationship: Relationship
    let category: RelationshipCategory
    @ObservedObject var viewModel: RelationshipViewModel
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                // Avatar
                contactAvatar

                // Contact info
                VStack(alignment: .leading, spacing: 2) {
                    Text(relationship.ofContact.completeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)

                    Text(viewModel.displayName(
                        for: relationship.relationshipType,
                        gender: relationship.ofContact.gender
                    ))
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
                }

                Spacer()

                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(Constants.UI.Spacing.medium)
            .background(Color.primaryBackground)
            .cornerRadius(Constants.UI.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Relationship", systemImage: "pencil")
            }

            Button(action: onTap) {
                Label("View Contact", systemImage: "person.crop.circle")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }

            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.monicaBlue)
        }
    }

    @ViewBuilder
    private var contactAvatar: some View {
        if let avatarURL = relationship.ofContact.information.avatar.url,
           let url = URL(string: avatarURL) {
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
            .fill(category.color.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Text(relationship.ofContact.initials)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(category.color)
            )
    }
}

// Make Relationship Identifiable for sheet binding
extension Relationship: Identifiable {}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel: RelationshipViewModel = {
            let apiClient = MonicaAPIClient(baseURL: "https://example.com", apiToken: "test")
            let service = RelationshipAPIService(apiClient: apiClient)
            return RelationshipViewModel(apiService: service)
        }()

        var body: some View {
            NavigationView {
                RelationshipListView(
                    viewModel: viewModel,
                    contact: Contact.preview,
                    onContactTap: { id in print("Tapped contact \(id)") }
                )
            }
        }
    }

    return PreviewWrapper()
}
