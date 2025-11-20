import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var nickname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var jobTitle = ""
    @State private var notes = ""
    @State private var birthdate: Date?
    @State private var selectedGender: Gender?
    @State private var isDeceased = false
    @State private var showBirthdatePicker = false

    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Nickname", text: $nickname)

                    Picker("Gender", selection: $selectedGender) {
                        Text("Not specified").tag(nil as Gender?)
                        ForEach(authManager.availableGenders) { gender in
                            Text(gender.name).tag(gender as Gender?)
                        }
                    }
                }

                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Work Information")) {
                    TextField("Company", text: $company)
                    TextField("Job Title", text: $jobTitle)
                }

                Section(header: Text("Personal Information")) {
                    Toggle("Show Birthdate", isOn: $showBirthdatePicker)

                    if showBirthdatePicker {
                        DatePicker("Birthdate", selection: Binding(
                            get: { birthdate ?? Date() },
                            set: { birthdate = $0 }
                        ), displayedComponents: .date)
                    }

                    Toggle("Deceased", isOn: $isDeceased)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createContact()
                    }
                    .disabled(firstName.isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    private func createContact() {
        guard let apiClient = authManager.currentAPIClient else { return }

        isCreating = true

        Task {
            do {
                // Create basic contact
                var newContact = Contact(
                    id: 0,  // Will be assigned by server
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    nickname: nickname.isEmpty ? nil : nickname,
                    completeName: "\(firstName) \(lastName)",
                    gender: selectedGender?.name,
                    isStarred: false,
                    isPartial: false,
                    isActive: true,
                    isDead: isDeceased,
                    information: nil,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    company: company.isEmpty ? nil : company,
                    jobTitle: jobTitle.isEmpty ? nil : jobTitle,
                    birthdate: birthdate,
                    notes: notes.isEmpty ? nil : notes,
                    addresses: [],
                    tags: [],
                    createdAt: Date(),
                    updatedAt: Date()
                )

                // Create the contact
                let createdContact = try await apiClient.createContact(newContact)
                print("✅ Created contact: \(createdContact.completeName)")

                // Add contact fields (email, phone) if provided
                if !email.isEmpty {
                    _ = try await apiClient.createContactField(
                        contactId: createdContact.id,
                        type: .email,
                        data: email,
                        label: "Personal"
                    )
                }

                if !phone.isEmpty {
                    _ = try await apiClient.createContactField(
                        contactId: createdContact.id,
                        type: .phone,
                        data: phone,
                        label: "Mobile"
                    )
                }

                // Sync to Core Data
                await dataController.importContacts([createdContact], markAsDetailSynced: true)

                await MainActor.run {
                    isCreating = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Failed to create contact: \(error)")
            }
        }
    }
}

#Preview {
    AddContactView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataController(authManager: AuthenticationManager()))
}
