import SwiftUI

/// Form view for creating or editing a relationship between contacts
struct RelationshipFormView: View {
    @ObservedObject var viewModel: RelationshipViewModel
    @Environment(\.dismiss) private var dismiss

    let sourceContact: Contact
    let existingRelationship: Relationship?
    let onSave: () -> Void

    @State private var selectedContact: Contact?
    @State private var selectedRelationshipType: RelationshipType?
    @State private var currentStep: FormStep = .selectContact
    @State private var showingCancelConfirmation = false

    enum FormStep {
        case selectContact
        case selectType
    }

    var isEditMode: Bool {
        existingRelationship != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                // Content based on step
                Group {
                    switch currentStep {
                    case .selectContact:
                        contactSelectionStep
                    case .selectType:
                        typeSelectionStep
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Relationship" : "Add Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .selectType {
                        Button("Save") {
                            Task {
                                await saveRelationship()
                            }
                        }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Discard Changes?", isPresented: $showingCancelConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .task {
                await viewModel.loadRelationshipTypesIfNeeded()

                // Pre-populate for edit mode
                if let relationship = existingRelationship {
                    selectedRelationshipType = relationship.relationshipType
                    // In edit mode, skip to type selection
                    currentStep = .selectType
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            stepIndicator(step: 1, title: "Contact", isActive: currentStep == .selectContact, isComplete: selectedContact != nil || isEditMode)

            Rectangle()
                .fill(selectedContact != nil || isEditMode ? Color.monicaBlue : Color.tertiaryBackground)
                .frame(height: 2)
                .frame(maxWidth: 40)

            stepIndicator(step: 2, title: "Type", isActive: currentStep == .selectType, isComplete: selectedRelationshipType != nil)
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
    }

    private func stepIndicator(step: Int, title: String, isActive: Bool, isComplete: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.monicaBlue : (isComplete ? Color.monicaGreen : Color.tertiaryBackground))
                    .frame(width: 28, height: 28)

                if isComplete && !isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isActive ? .white : .secondaryText)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .primaryText : .secondaryText)
        }
    }

    // MARK: - Step 1: Contact Selection

    @ViewBuilder
    private var contactSelectionStep: some View {
        if isEditMode, let relationship = existingRelationship {
            // In edit mode, show the fixed contact
            VStack(spacing: Constants.UI.Spacing.large) {
                relationshipPreview(contact: relationship.ofContact)

                Button(action: { currentStep = .selectType }) {
                    HStack {
                        Text("Continue to Type Selection")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.monicaBlue)
                    .cornerRadius(Constants.UI.CornerRadius.medium)
                }
                .padding(.horizontal, Constants.UI.Spacing.medium)

                Spacer()
            }
            .padding(.top, Constants.UI.Spacing.large)
        } else {
            ContactSearchView(
                viewModel: viewModel,
                excludeContactId: sourceContact.id,
                onContactSelected: { contact in
                    selectedContact = contact
                    currentStep = .selectType
                }
            )
        }
    }

    private func relationshipPreview(contact: RelatedContact) -> some View {
        HStack(spacing: Constants.UI.Spacing.medium) {
            Circle()
                .fill(Color.monicaBlue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(contact.initials)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.monicaBlue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Editing relationship with")
                    .font(.caption)
                    .foregroundColor(.secondaryText)

                Text(contact.completeName)
                    .font(.headline)
                    .foregroundColor(.primaryText)
            }

            Spacer()
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.medium)
        .padding(.horizontal, Constants.UI.Spacing.medium)
    }

    // MARK: - Step 2: Type Selection

    private var typeSelectionStep: some View {
        VStack(spacing: 0) {
            // Selected contact summary
            if let contact = selectedContact {
                selectedContactSummary(contact: contact)
            } else if let relationship = existingRelationship {
                selectedContactSummary(relatedContact: relationship.ofContact)
            }

            // Validation error
            if let validationError = viewModel.validationError {
                errorBanner(message: validationError.localizedDescription)
            }

            // Type picker
            RelationshipTypePicker(
                viewModel: viewModel,
                selectedType: $selectedRelationshipType,
                sourceContactGender: sourceContact.gender,
                targetContactGender: targetContactGender
            )

            // Saving indicator
            if viewModel.isSaving {
                savingOverlay
            }
        }
    }

    private func selectedContactSummary(contact: Contact) -> some View {
        Button(action: {
            if !isEditMode {
                currentStep = .selectContact
            }
        }) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                Circle()
                    .fill(Color.monicaBlue.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(contact.initials)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.monicaBlue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sourceContact.completeName) is...")
                        .font(.caption)
                        .foregroundColor(.secondaryText)

                    Text("...of \(contact.completeName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                }

                Spacer()

                if !isEditMode {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }
            .padding(Constants.UI.Spacing.medium)
            .background(Color.secondaryBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isEditMode)
    }

    private func selectedContactSummary(relatedContact: RelatedContact) -> some View {
        HStack(spacing: Constants.UI.Spacing.medium) {
            Circle()
                .fill(Color.monicaBlue.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(relatedContact.initials)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.monicaBlue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(sourceContact.completeName) is...")
                    .font(.caption)
                    .foregroundColor(.secondaryText)

                Text("...of \(relatedContact.completeName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
            }

            Spacer()
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.monicaRed)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.monicaRed)

            Spacer()
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.monicaRed.opacity(0.1))
    }

    private var savingOverlay: some View {
        HStack(spacing: Constants.UI.Spacing.small) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Saving...")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
    }

    // MARK: - Helpers

    private var targetContactGender: String? {
        if let contact = selectedContact {
            return contact.gender
        } else if let relationship = existingRelationship {
            return relationship.ofContact.gender
        }
        return nil
    }

    private var canSave: Bool {
        guard selectedRelationshipType != nil else { return false }

        if isEditMode {
            return true
        } else {
            return selectedContact != nil
        }
    }

    private var hasUnsavedChanges: Bool {
        if isEditMode {
            return selectedRelationshipType?.id != existingRelationship?.relationshipType.id
        } else {
            return selectedContact != nil || selectedRelationshipType != nil
        }
    }

    // MARK: - Save Action

    private func saveRelationship() async {
        guard let typeId = selectedRelationshipType?.id else { return }

        viewModel.clearErrors()

        if isEditMode, let relationship = existingRelationship {
            // Update existing relationship
            if await viewModel.updateRelationship(
                relationshipId: relationship.id,
                relationshipTypeId: typeId
            ) != nil {
                onSave()
                dismiss()
            }
        } else if let targetContact = selectedContact {
            // Create new relationship
            if await viewModel.createRelationship(
                sourceContactId: sourceContact.id,
                targetContactId: targetContact.id,
                relationshipTypeId: typeId
            ) != nil {
                onSave()
                dismiss()
            }
        }
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
            RelationshipFormView(
                viewModel: viewModel,
                sourceContact: Contact.preview,
                existingRelationship: nil,
                onSave: { print("Saved!") }
            )
        }
    }

    return PreviewWrapper()
}

// MARK: - Contact Preview Extension

extension Contact {
    static var preview: Contact {
        Contact(
            id: 1,
            uuid: "test-uuid",
            object: "contact",
            hashId: "test-hash",
            firstName: "John",
            lastName: "Doe",
            nickname: nil,
            completeName: "John Doe",
            initials: "JD",
            description: nil,
            gender: "male",
            genderType: nil,
            isStarred: false,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: nil,
            phone: nil,
            birthdate: nil,
            birthdateIsAgeBased: nil,
            birthdateAge: nil,
            isBirthdateKnown: nil,
            address: nil,
            company: "Acme Corp",
            jobTitle: nil,
            notes: nil,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "https://example.com",
            account: Account(id: 1),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
