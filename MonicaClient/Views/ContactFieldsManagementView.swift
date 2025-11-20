import SwiftUI

struct ContactFieldsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var contactFields: [ContactField] = []
    @State private var isLoading = true
    @State private var showingAddField = false
    @State private var editingField: ContactField?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading contact information...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedFields.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { type in
                            Section(header: Text(type.label)) {
                                ForEach(groupedFields[type] ?? []) { field in
                                    ContactFieldRow(
                                        field: field,
                                        onEdit: { editingField = field },
                                        onDelete: { deleteField(field) }
                                    )
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadContactFields()
                    }
                }
            }
            .navigationTitle("Contact Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddField = true
                    }
                }
            }
        }
        .task {
            await loadContactFields()
        }
        .sheet(isPresented: $showingAddField) {
            AddContactFieldView(contactId: contact.id) { newField in
                contactFields.append(newField)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingField) { field in
            EditContactFieldView(field: field, contactId: contact.id) { updatedField in
                if let index = contactFields.firstIndex(where: { $0.id == updatedField.id }) {
                    contactFields[index] = updatedField
                }
            }
            .environmentObject(authManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var groupedFields: [ContactField.ContactFieldType: [ContactField]] {
        Dictionary(grouping: contactFields) { $0.contactFieldTypeEnum }
    }
    
    @MainActor
    private func loadContactFields() async {
        guard let apiClient = authManager.currentAPIClient else { return }
        
        isLoading = true
        do {
            contactFields = try await apiClient.getContactFields(contactId: contact.id)
            print("✅ Loaded \(contactFields.count) contact fields")
        } catch {
            errorMessage = "Failed to load contact fields: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load contact fields: \(error)")
        }
        isLoading = false
    }
    
    private func deleteField(_ field: ContactField) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            do {
                try await apiClient.deleteContactField(contactId: contact.id, fieldId: field.id)
                await MainActor.run {
                    contactFields.removeAll { $0.id == field.id }
                }
                print("✅ Deleted contact field: \(field.contactFieldTypeEnum.label)")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete field: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete contact field: \(error)")
            }
        }
    }
}

struct ContactFieldRow: View {
    let field: ContactField
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: field.contactFieldTypeEnum.icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                if let label = field.label, !label.isEmpty {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(field.data)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if field.contactFieldTypeEnum.isActionable,
               let url = field.contactFieldTypeEnum.getActionURL(for: field.data) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if field.contactFieldTypeEnum.isActionable,
               let url = field.contactFieldTypeEnum.getActionURL(for: field.data) {
                UIApplication.shared.open(url)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
}

struct AddContactFieldView: View {
    let contactId: Int
    let onFieldAdded: (ContactField) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: ContactField.ContactFieldType = .email
    @State private var fieldData = ""
    @State private var fieldLabel = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ContactField.ContactFieldType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Field Information") {
                    TextField("Label (optional)", text: $fieldLabel)
                    TextField(placeholderText, text: $fieldData)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalizationType)
                }
            }
            .navigationTitle("Add Contact Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitField()
                    }
                    .disabled(fieldData.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var placeholderText: String {
        switch selectedType {
        case .email: return "john@example.com"
        case .phone: return "+1 (555) 123-4567"
        case .address: return "123 Main St, City, State"
        case .website: return "https://example.com"
        case .social: return "@username"
        case .other: return "Information"
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch selectedType {
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .website: return .URL
        default: return .default
        }
    }
    
    private var autocapitalizationType: TextInputAutocapitalization {
        switch selectedType {
        case .email, .website: return .never
        default: return .sentences
        }
    }
    
    private func submitField() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            await MainActor.run { isSubmitting = true }
            
            do {
                let newField = try await apiClient.createContactField(
                    contactId: contactId,
                    type: selectedType,
                    data: fieldData,
                    label: fieldLabel.isEmpty ? nil : fieldLabel
                )
                
                await MainActor.run {
                    onFieldAdded(newField)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create field: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditContactFieldView: View {
    let field: ContactField
    let contactId: Int
    let onFieldUpdated: (ContactField) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: ContactField.ContactFieldType
    @State private var fieldData: String
    @State private var fieldLabel: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    init(field: ContactField, contactId: Int, onFieldUpdated: @escaping (ContactField) -> Void) {
        self.field = field
        self.contactId = contactId
        self.onFieldUpdated = onFieldUpdated
        _selectedType = State(initialValue: field.contactFieldTypeEnum)
        _fieldData = State(initialValue: field.data)
        _fieldLabel = State(initialValue: field.label ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ContactField.ContactFieldType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Field Information") {
                    TextField("Label (optional)", text: $fieldLabel)
                    TextField("Value", text: $fieldData)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalizationType)
                }
            }
            .navigationTitle("Edit Contact Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitField()
                    }
                    .disabled(fieldData.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch selectedType {
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .website: return .URL
        default: return .default
        }
    }
    
    private var autocapitalizationType: TextInputAutocapitalization {
        switch selectedType {
        case .email, .website: return .never
        default: return .sentences
        }
    }
    
    private func submitField() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }
            
            await MainActor.run { isSubmitting = true }
            
            do {
                let updatedField = try await apiClient.updateContactField(
                    contactId: contactId,
                    fieldId: field.id,
                    type: selectedType,
                    data: fieldData,
                    label: fieldLabel.isEmpty ? nil : fieldLabel
                )
                
                await MainActor.run {
                    onFieldUpdated(updatedField)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update field: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    let contact = Contact(
        id: 1,
        uuid: "test",
        object: "contact",
        hashId: "test",
        firstName: "John",
        lastName: "Doe",
        nickname: nil,
        completeName: "John Doe",
        initials: "JD",
        description: nil,
        gender: nil,
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
        email: "john@example.com",
        phone: "+1234567890",
        birthdate: nil,
        birthdateIsAgeBased: false,
        birthdateAge: nil,
        isBirthdateKnown: false,
        address: "123 Main St",
        company: "ACME Corp",
        jobTitle: "Developer",
        notes: "Test notes",
        relationships: nil,
        information: nil,
        addresses: nil,
        tags: nil,
        statistics: nil,
        url: "test",
        account: Account(id: 1),
        createdAt: Date(),
        updatedAt: Date()
    )
    
    ContactFieldsManagementView(contact: contact)
        .environmentObject(AuthenticationManager())
}