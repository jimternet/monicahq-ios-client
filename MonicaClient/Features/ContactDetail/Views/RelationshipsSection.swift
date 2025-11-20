import SwiftUI

/// Section for displaying contact relationships
struct RelationshipsSection: View {
    let relationships: [Relationship]
    let onRelationshipTap: ((RelatedContact) -> Void)?
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: Constants.UI.Animation.defaultDuration)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.monicaBlue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Relationships")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text("(\(relationships.count))")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.tertiaryText)
                        .font(.system(size: 12, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: Constants.UI.Animation.fastDuration), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: Constants.UI.Spacing.small) {
                    if relationships.isEmpty {
                        emptyStateView
                    } else {
                        relationshipsContent
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.medium)
    }
    
    @ViewBuilder
    private var relationshipsContent: some View {
        LazyVStack(spacing: Constants.UI.Spacing.small) {
            ForEach(groupedRelationships, id: \.0) { relationshipType, relationships in
                RelationshipGroupView(
                    relationshipType: relationshipType,
                    relationships: relationships,
                    onRelationshipTap: onRelationshipTap
                )
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(.tertiaryText)
            
            Text("No Relationships")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
            
            Text("Family members and friends will appear here when they're connected to this contact.")
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.UI.Spacing.large)
        .frame(maxWidth: .infinity)
    }
    
    /// Group relationships by type for better organization
    private var groupedRelationships: [(String, [Relationship])] {
        let grouped = Dictionary(grouping: relationships) { relationship in
            relationship.relationshipType?.name ?? "Unknown"
        }
        return grouped.sorted { $0.key < $1.key }
    }
}

/// View for displaying a group of relationships of the same type
struct RelationshipGroupView: View {
    let relationshipType: String
    let relationships: [Relationship]
    let onRelationshipTap: ((RelatedContact) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            // Relationship type header
            HStack {
                Text(relationshipType.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text("\(relationships.count)")
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.tertiaryBackground)
                    .cornerRadius(8)
            }
            
            // Individual relationships
            VStack(spacing: Constants.UI.Spacing.extraSmall) {
                ForEach(relationships) { relationship in
                    if let contact = relationship.contact {
                        RelationshipRowView(
                            relationship: relationship,
                            contact: contact,
                            onTap: {
                                onRelationshipTap?(contact)
                            }
                        )
                    }
                }
            }
        }
        .padding(.vertical, Constants.UI.Spacing.small)
    }
}

/// Individual relationship row view
struct RelationshipRowView: View {
    let relationship: Relationship
    let contact: RelatedContact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                // Avatar
                AsyncImage(url: URL(string: contact.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(relationshipColor.opacity(0.2))
                        .overlay(
                            Text(contact.displayName.prefix(1).uppercased())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(relationshipColor)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                // Contact info
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    if let relationshipName = relationship.relationshipType?.displayName(for: contact.gender) {
                        Text(relationshipName)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, Constants.UI.Spacing.small)
            .padding(.vertical, Constants.UI.Spacing.small)
            .background(Color.primaryBackground)
            .cornerRadius(Constants.UI.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var relationshipColor: Color {
        guard let type = relationship.relationshipType?.name.lowercased() else {
            return .monicaBlue
        }
        
        switch type {
        case let t where t.contains("family") || t.contains("parent") || t.contains("child") || t.contains("sibling"):
            return .monicaRed
        case let t where t.contains("spouse") || t.contains("partner") || t.contains("significant"):
            return .monicaRed
        case let t where t.contains("friend"):
            return .monicaGreen
        case let t where t.contains("colleague") || t.contains("work"):
            return .monicaOrange
        default:
            return .monicaBlue
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Constants.UI.Spacing.medium) {
            RelationshipsSection(
                relationships: Relationship.mockRelationships,
                onRelationshipTap: { contact in
                    print("Tapped on \(contact.displayName)")
                }
            )
        }
        .padding()
    }
    .background(Color.primaryBackground)
}

// MARK: - Extensions for Preview
extension Relationship {
    static var mockRelationships: [Relationship] {
        [
            Relationship(
                id: 1,
                relationshipTypeId: 1,
                contactId: 1,
                ofContactId: 2,
                relationshipType: RelationshipType(
                    id: 1,
                    name: "spouse",
                    nameFemale: "wife",
                    nameMale: "husband",
                    delible: false
                ),
                contact: RelatedContact(
                    id: 2,
                    firstName: "Jane",
                    lastName: "Doe",
                    nickname: nil,
                    gender: "female",
                    avatarURL: nil
                ),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Relationship(
                id: 2,
                relationshipTypeId: 2,
                contactId: 1,
                ofContactId: 3,
                relationshipType: RelationshipType(
                    id: 2,
                    name: "child",
                    nameFemale: "daughter",
                    nameMale: "son",
                    delible: false
                ),
                contact: RelatedContact(
                    id: 3,
                    firstName: "Emily",
                    lastName: "Doe",
                    nickname: "Em",
                    gender: "female",
                    avatarURL: nil
                ),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Relationship(
                id: 3,
                relationshipTypeId: 3,
                contactId: 1,
                ofContactId: 4,
                relationshipType: RelationshipType(
                    id: 3,
                    name: "friend",
                    nameFemale: "friend",
                    nameMale: "friend",
                    delible: true
                ),
                contact: RelatedContact(
                    id: 4,
                    firstName: "Mike",
                    lastName: "Smith",
                    nickname: "Mikey",
                    gender: "male",
                    avatarURL: nil
                ),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}