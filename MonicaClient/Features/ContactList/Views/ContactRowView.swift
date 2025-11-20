import SwiftUI

/// A single contact row in the contact list
struct ContactRowView: View {
    let contact: ContactEntity
    
    var body: some View {
        HStack(spacing: Constants.UI.Spacing.medium) {
            // Avatar
            Circle()
                .fill(Color.monicaBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(contact.initials)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.monicaBlue)
                )
            
            // Contact Info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let description = contact.contactDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(1)
                } else if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.tertiaryText)
        }
        .padding(.vertical, Constants.UI.Spacing.small)
        .contentShape(Rectangle())
    }
}

#Preview("Contact with Email") {
    List {
        ContactRowView(contact: {
            let contact = ContactEntity()
            contact.firstName = "John"
            contact.lastName = "Doe"
            contact.email = "john.doe@example.com"
            return contact
        }())
    }
}

#Preview("Contact with Description") {
    List {
        ContactRowView(contact: {
            let contact = ContactEntity()
            contact.firstName = "Jane"
            contact.lastName = "Smith"
            contact.contactDescription = "Best friend from college"
            return contact
        }())
    }
}

#Preview("Contact Minimal") {
    List {
        ContactRowView(contact: {
            let contact = ContactEntity()
            contact.firstName = "Bob"
            return contact
        }())
    }
}