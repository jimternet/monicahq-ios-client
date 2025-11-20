import SwiftUI

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController

    let contact: ContactEntity

    @State private var firstName: String
    @State private var lastName: String
    @State private var nickname: String
    @State private var email: String
    @State private var phone: String
    @State private var company: String
    @State private var jobTitle: String
    @State private var notes: String
    @State private var birthdate: Date?
    @State private var selectedGender: Gender?
    @State private var isDeceased: Bool
    @State private var showBirthdatePicker: Bool
    @State private var isStarred: Bool

    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(contact: ContactEntity) {
        self.contact = contact

        _firstName = State(initialValue: contact.firstName ?? "")
        _lastName = State(initialValue: contact.lastName ?? "")
        _nickname = State(initialValue: contact.nickname ?? "")
        _email = State(initialValue: contact.email ?? "")
        _phone = State(initialValue: contact.phone ?? "")
        _company = State(initialValue: contact.company ?? "")
        _jobTitle = State(initialValue: contact.jobTitle ?? "")
        _notes = State(initialValue: contact.notes ?? "")
        _birthdate = State(initialValue: contact.birthdate)
        _isDeceased = State(initialValue: contact.isDeceased)
        _showBirthdatePicker = State(initialValue: contact.birthdate != nil)
        _isStarred = State(initialValue: contact.isStarred)
        _selectedGender = State(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Nickname", text: $nickname)

                    if !authManager.availableGenders.isEmpty {
                        Picker("Gender", selection: $selectedGender) {
                            Text("Not specified").tag(nil as Gender?)
                            ForEach(authManager.availableGenders) { gender in
                                Text(gender.name).tag(gender as Gender?)
                            }
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
                    Toggle("Starred", isOn: $isStarred)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateContact()
                    }
                    .disabled(firstName.isEmpty || isUpdating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    private func updateContact() {
        guard let apiClient = authManager.currentAPIClient else { return }

        isUpdating = true

        Task {
            do {
                // Prepare birthdate components if provided
                var birthdateDay: Int?
                var birthdateMonth: Int?
                var birthdateYear: Int?

                if showBirthdatePicker, let date = birthdate {
                    let calendar = Calendar.current
                    birthdateDay = calendar.component(.day, from: date)
                    birthdateMonth = calendar.component(.month, from: date)
                    birthdateYear = calendar.component(.year, from: date)
                }

                // Update the contact using the API
                let updatedContact = try await apiClient.updateContact(
                    contactId: Int(contact.id),
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    nickname: nickname.isEmpty ? nil : nickname,
                    genderId: selectedGender?.id,
                    birthdateDay: birthdateDay,
                    birthdateMonth: birthdateMonth,
                    birthdateYear: birthdateYear,
                    isBirthdateKnown: showBirthdatePicker && birthdate != nil,
                    isDeceased: isDeceased,
                    isStarred: isStarred
                )

                print("✅ Updated contact: \(updatedContact.completeName)")

                // Sync to Core Data
                await dataController.importContacts([updatedContact], markAsDetailSynced: true)

                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Failed to update contact: \(error)")
            }
        }
    }
}
