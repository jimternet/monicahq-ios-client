import SwiftUI

struct ContactDetailView: View {
    @ObservedObject var contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) private var dismiss

    // TODO: Re-enable contact editing
    // @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with avatar
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(contact.initials)
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                        )
                    Spacer()
                }
                .padding(.top)

                // Basic Information Section
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("Basic Information", systemImage: "person")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        // TODO: Re-enable contact editing
                        // Button("Edit") {
                        //     showingEditSheet = true
                        // }
                        // .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))

                    VStack(spacing: 0) {
                        BasicInfoRow(icon: "person", label: "Name", value: contact.fullName)

                        // Gender
                        if let gender = contact.gender {
                            BasicInfoRow(icon: "figure.stand", label: "Gender", value: gender)
                        }

                        // Age/Birthday
                        if let ageDisplay = formatAgeDisplay(contact: contact) {
                            BasicInfoRow(icon: "gift", label: "Age", value: ageDisplay)
                        }

                        if let jobTitle = contact.jobTitle {
                            BasicInfoRow(icon: "briefcase", label: "Position", value: jobTitle)
                        }

                        if let company = contact.company {
                            BasicInfoRow(icon: "building.2", label: "Organization", value: company)
                        }

                        if let updatedAt = contact.updatedAt {
                            BasicInfoRow(icon: "clock", label: "Last updated", value: timeAgo(from: updatedAt))
                        }
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }
                .cornerRadius(10)
                .padding(.horizontal)

                // Contact Information Section
                if contact.email != nil || contact.phone != nil || contact.address != nil {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Contact Information")
                            .font(.headline)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))

                        VStack(spacing: 0) {
                            if let email = contact.email {
                                ContactInfoRow(icon: "envelope", label: "Email", value: email, isLink: true)
                            }

                            if let phone = contact.phone {
                                ContactInfoRow(icon: "phone", label: "Phone", value: phone, isLink: true)
                            }

                            if let address = contact.address {
                                ContactInfoRow(icon: "location", label: "Address", value: address, isLink: false)
                            }
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                // Notes Section
                NotesSection(contact: contact)
                    .padding(.horizontal)

                // Relationships Section
                RelationshipsSection(contact: contact)
                    .padding(.horizontal)

                // How You Met Section
                HowYouMetSection(contact: contact)
                    .padding(.horizontal)

                // Work Information Section
                WorkInformationSection(contact: contact)
                    .padding(.horizontal)

                // Food Preferences Section
                FoodPreferencesSection(contact: contact)
                    .padding(.horizontal)

                // Stay in Touch Section
                StayInTouchSection(contact: contact)
                    .padding(.horizontal)

                // Tags Section
                TagsSection(contact: contact)
                    .padding(.horizontal)

                // Addresses Section
                AddressesSection(contact: contact)
                    .padding(.horizontal)

                // Gifts Section
                GiftsSection(contact: contact)
                    .padding(.horizontal)

                // Tasks Section
                TasksSection(contact: contact)
                    .padding(.horizontal)

                // Manage Section - Links to CRUD Management Views
                ManageSection(contactId: Int(contact.id))
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(contact.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // TODO: Re-enable contact editing
                    // Button(action: { showingEditSheet = true }) {
                    //     Label("Edit Contact", systemImage: "pencil")
                    // }

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Contact", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // TODO: Re-enable contact editing sheet
        // .sheet(isPresented: $showingEditSheet) {
        //     EditContactView(contact: contact)
        //         .environmentObject(authManager)
        //         .environmentObject(dataController)
        // }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Are you sure you want to delete \(contact.fullName)? This action cannot be undone.")
        }
    }

    private func deleteContact() {
        guard let apiClient = authManager.currentAPIClient else { return }

        isDeleting = true

        Task {
            do {
                // Delete from API
                try await apiClient.deleteContact(id: Int(contact.id))
                print("✅ Deleted contact from API: \(contact.fullName)")

                // Delete from Core Data
                await MainActor.run {
                    if let context = contact.managedObjectContext {
                        context.delete(contact)
                        dataController.save()
                        print("✅ Deleted contact from Core Data: \(contact.fullName)")
                    }

                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                }
                print("❌ Failed to delete contact: \(error)")
            }
        }
    }

    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Helper function to show time ago
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours) hr, \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    // Helper function to calculate age from birthdate
    private func calculateAge(from birthdate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year ?? 0
    }

    // Helper function to format age display from Contact model
    private func formatAgeDisplay(contact: Contact) -> String? {
        // Check if birthdate is age-based
        if let isAgeBased = contact.birthdateIsAgeBased, isAgeBased, let age = contact.birthdateAge {
            return "probably \(age) years old"
        }

        // Check if we have a birthdate
        if let birthdate = contact.birthdate {
            let age = calculateAge(from: birthdate)
            return "\(age) years old"
        }

        return nil
    }

    // Helper function to format age display from ContactEntity model
    private func formatAgeDisplay(contact: ContactEntity) -> String? {
        // Check if birthdate is age-based
        if contact.birthdateIsAgeBased && contact.birthdateAge > 0 {
            return "probably \(contact.birthdateAge) years old"
        }

        // Check if we have a birthdate
        if let birthdate = contact.birthdate {
            let age = calculateAge(from: birthdate)
            return "\(age) years old"
        }

        return nil
    }

    // Helper function to format age display
    // Handles different age/birthdate scenarios:
    // - is_age_based: true -> "probably X years old"
    // - is_year_unknown: true -> "Birthday: Month Day"
    // - normal birthdate -> "X years old"
    private func formatAge(from dateInfo: DateInfo) -> String? {
        if let isAgeBased = dateInfo.isAgeBased, isAgeBased, let date = dateInfo.date {
            let age = calculateAge(from: date)
            return "probably \(age) years old"
        } else if let isYearUnknown = dateInfo.isYearUnknown, isYearUnknown, let date = dateInfo.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return "Birthday: \(formatter.string(from: date))"
        } else if let date = dateInfo.date {
            let age = calculateAge(from: date)
            return "\(age) years old"
        }
        return nil
    }
}

// MARK: - Info Row Components

struct BasicInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isLink: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isLink {
                    if label == "Email" {
                        Link(value, destination: URL(string: "mailto:\(value)")!)
                            .font(.body)
                    } else if label == "Phone" {
                        Link(value, destination: URL(string: "tel:\(value)")!)
                            .font(.body)
                    } else {
                        Text(value)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            if isLink {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content()
        }
    }
}

// MARK: - Basic Info Editor

struct BasicInfoEditorView: View {
    let contact: ContactEntity
    let onSave: (String?, String?, String?, Int?) -> Void

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var nickname: String
    @State private var genderId: Int?
    @State private var showingBirthdayEditor = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    // Birthday state
    @State private var birthdayOption: BirthdayOption = .unknown
    @State private var birthdate: Date = Date()
    @State private var birthdayDay: Int = 1
    @State private var birthdayMonth: Int = 1
    @State private var estimatedAge: Int = 30

    // Use genders from authManager instead of fetching them
    private var availableGenders: [Gender] {
        authManager.availableGenders
    }

    private var isLoadingGenders: Bool {
        availableGenders.isEmpty
    }

    private var birthdayDisplayText: String {
        switch birthdayOption {
        case .unknown:
            return "I do not know this person's age"
        case .ageBased:
            return "Probably \(estimatedAge) years old"
        case .dayMonthOnly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            var dateComponents = DateComponents()
            dateComponents.month = birthdayMonth
            dateComponents.day = birthdayDay
            dateComponents.year = Calendar.current.component(.year, from: Date())
            if let date = Calendar.current.date(from: dateComponents) {
                return "Birthday: \(formatter.string(from: date))"
            }
            return "Birthday: Month \(birthdayMonth), Day \(birthdayDay)"
        case .exactDate:
            let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(age) years old (\(formatter.string(from: birthdate)))"
        }
    }

    init(contact: ContactEntity, onSave: @escaping (String?, String?, String?, Int?) -> Void) {
        self.contact = contact
        self.onSave = onSave
        _firstName = State(initialValue: contact.firstName ?? "")
        _lastName = State(initialValue: contact.lastName ?? "")
        _nickname = State(initialValue: contact.nickname ?? "")
        _genderId = State(initialValue: nil)

        // Initialize birthday state from contact
        if contact.birthdateIsAgeBased && contact.birthdateAge > 0 {
            // Age-based birthday
            _birthdayOption = State(initialValue: .ageBased)
            _estimatedAge = State(initialValue: Int(contact.birthdateAge))
        } else if let birthdate = contact.birthdate {
            _birthdate = State(initialValue: birthdate)
            _birthdayOption = State(initialValue: .exactDate)

            let components = Calendar.current.dateComponents([.year, .month, .day], from: birthdate)
            if let month = components.month, let day = components.day {
                _birthdayMonth = State(initialValue: month)
                _birthdayDay = State(initialValue: day)
            }
            if components.year != nil {
                let age = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
                _estimatedAge = State(initialValue: age)
            }
        } else {
            _birthdayOption = State(initialValue: .unknown)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                .headerProminence(.increased)

                Section("Nickname") {
                    TextField("Nickname (optional)", text: $nickname)
                }
                .headerProminence(.increased)

                if !isLoadingGenders && !availableGenders.isEmpty {
                    Section("Gender") {
                        Picker("Gender", selection: $genderId) {
                            Text("Not specified").tag(nil as Int?)
                            ForEach(availableGenders) { gender in
                                Text(gender.name).tag(gender.id as Int?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .headerProminence(.increased)
                }

                Section("Age / Birthday") {
                    Button(action: {
                        showingBirthdayEditor = true
                    }) {
                        HStack {
                            Text(birthdayDisplayText)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBirthdayEditor) {
                BirthdayEditorView(
                    birthdayOption: $birthdayOption,
                    birthdate: $birthdate,
                    birthdayDay: $birthdayDay,
                    birthdayMonth: $birthdayMonth,
                    estimatedAge: $estimatedAge
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBasicInfo()
                    }
                    .disabled(isSubmitting || firstName.isEmpty)
                }
            }
        }
        .task {
            // Match the contact's current gender name to a gender ID from cached genders
            if let currentGender = contact.gender, genderId == nil {
                genderId = availableGenders.first(where: { $0.name.lowercased() == currentGender.lowercased() })?.id
                print("📝 Matched current gender '\(currentGender)' to ID: \(genderId?.description ?? "nil")")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func saveBasicInfo() {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            showingError = true
            return
        }

        isSubmitting = true

        Task {
            do {
                // Prepare birthday fields based on selected option
                var birthdayDay: Int? = nil
                var birthdayMonth: Int? = nil
                var birthdayYear: Int? = nil
                var birthdayIsAgeBased: Bool? = nil
                var isBirthdayKnown = false
                var birthdayAge: Int? = nil

                print("🎂 Birthday option selected: \(birthdayOption)")
                print("🎂 Estimated age: \(estimatedAge)")

                switch birthdayOption {
                case .unknown:
                    isBirthdayKnown = false
                case .ageBased:
                    isBirthdayKnown = true
                    birthdayIsAgeBased = true
                    birthdayAge = estimatedAge
                    print("🎂 Age-based: isBirthdayKnown=\(isBirthdayKnown), birthdayIsAgeBased=\(birthdayIsAgeBased ?? false), birthdayAge=\(birthdayAge ?? 0)")
                    // Leave day/month/year as nil for age-based entries
                    // The API uses the age field directly, not calculated dates
                case .dayMonthOnly:
                    isBirthdayKnown = true
                    birthdayIsAgeBased = false
                    birthdayDay = self.birthdayDay
                    birthdayMonth = self.birthdayMonth
                    birthdayYear = 1900 // Placeholder year
                case .exactDate:
                    isBirthdayKnown = true
                    birthdayIsAgeBased = false
                    let components = Calendar.current.dateComponents([.year, .month, .day], from: birthdate)
                    birthdayYear = components.year
                    birthdayMonth = components.month
                    birthdayDay = components.day
                }

                // Create update payload
                let payload = ContactUpdatePayload(
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName,
                    nickname: nickname.isEmpty ? nil : nickname,
                    genderId: genderId,
                    birthdateDay: birthdayDay,
                    birthdateMonth: birthdayMonth,
                    birthdateYear: birthdayYear,
                    birthdateIsAgeBased: birthdayIsAgeBased,
                    isBirthdateKnown: isBirthdayKnown,
                    birthdateAge: birthdayAge,
                    isPartial: nil,
                    isDeceased: false,
                    deceasedDate: nil,
                    deceasedDateIsAgeBased: nil,
                    deceasedDateIsYearUnknown: nil,
                    deceasedDateAge: nil,
                    isDeceasedDateKnown: false,
                    company: nil,
                    jobTitle: nil,
                    notes: nil,
                    description: nil,
                    gender: nil,
                    isStarred: nil,
                    foodPreferences: nil,
                    howYouMetGeneralInformation: nil,
                    firstMetDate: nil,
                    stayInTouchFrequency: nil,
                    stayInTouchTriggerDate: nil
                )

                // Update via API
                _ = try await apiClient.updateContact(id: Int(contact.id), payload: payload)

                // Update local state
                await MainActor.run {
                    onSave(
                        firstName.isEmpty ? nil : firstName,
                        lastName.isEmpty ? nil : lastName,
                        nickname.isEmpty ? nil : nickname,
                        genderId
                    )
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingNotesManagement = false
    @State private var notesCount: Int = 0
    @State private var isLoadingCount = true

    var body: some View {
        DetailSection(title: "Notes") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingCount {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if notesCount > 0 {
                    HStack {
                        Text("\(notesCount) note\(notesCount == 1 ? "" : "s")")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showingNotesManagement = true }) {
                            Text("View")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingNotesManagement = true }) {
                        Label("Add Note", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadNotesCount()
        }
        .sheet(isPresented: $showingNotesManagement) {
            if let apiContact = convertToContact(contact) {
                NotesManagementView(contact: apiContact)
                    .environmentObject(authManager)
            }
        }
    }

    private func loadNotesCount() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoadingCount = false
            return
        }

        do {
            let response = try await apiClient.getNotes(for: Int(contact.id), limit: 1)
            notesCount = response.meta?.total ?? 0
        } catch {
            print("Failed to load notes count: \(error)")
            notesCount = 0
        }
        isLoadingCount = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Notes Management Views

struct NotesManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var notes: [Note] = []
    @State private var isLoading = true
    @State private var showingAddNote = false
    @State private var editingNote: Note?
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading notes...")
                } else if notes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Notes")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Add your first note for \(contact.firstName ?? "this contact")")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showingAddNote = true }) {
                            Label("Add Note", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(notes) { note in
                            NoteRowView(note: note, onEdit: {
                                editingNote = note
                            }, onDelete: {
                                deleteNote(note)
                            })
                        }
                    }
                    .refreshable {
                        await loadNotes()
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !notes.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddNote = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadNotes()
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(contact: contact) { newNote in
                notes.insert(newNote, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingNote) { note in
            EditNoteView(note: note) { updatedNote in
                if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
                    notes[index] = updatedNote
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

    @MainActor
    private func loadNotes() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getNotes(for: contact.id, limit: 100)
            notes = response.data.sorted {
                ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
            }
            print("✅ Loaded \(notes.count) notes")
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load notes: \(error)")
        }
        isLoading = false
    }

    private func deleteNote(_ note: Note) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteNote(id: note.id)
                await MainActor.run {
                    notes.removeAll { $0.id == note.id }
                }
                print("✅ Deleted note")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete note: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete note: \(error)")
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.body)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)

            HStack {
                if let createdAt = note.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct AddNoteView: View {
    let contact: Contact
    let onNoteAdded: (Note) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var noteBody = ""
    @State private var isFavorite = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Content") {
                    TextEditor(text: $noteBody)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitNote()
                    }
                    .disabled(noteBody.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitNote() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                // Create Note object with placeholder data
                let noteToCreate = Note(
                    id: 0, // Will be assigned by server
                    contactId: contact.id,
                    body: noteBody,
                    isFavorited: isFavorite
                )

                let createdNote = try await apiClient.createNote(for: contact.id, note: noteToCreate)

                await MainActor.run {
                    onNoteAdded(createdNote)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create note: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditNoteView: View {
    let note: Note
    let onNoteUpdated: (Note) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var noteBody: String
    @State private var isFavorite: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(note: Note, onNoteUpdated: @escaping (Note) -> Void) {
        self.note = note
        self.onNoteUpdated = onNoteUpdated
        _noteBody = State(initialValue: note.body)
        _isFavorite = State(initialValue: note.isFavorite)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Content") {
                    TextEditor(text: $noteBody)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitNote()
                    }
                    .disabled(noteBody.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitNote() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                // Create updated Note object
                let updatedNote = Note(
                    id: note.id,
                    contactId: note.contactId,
                    body: noteBody,
                    isFavorited: isFavorite
                )

                let savedNote = try await apiClient.updateNote(updatedNote)

                await MainActor.run {
                    onNoteUpdated(savedNote)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update note: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Relationships Section

struct RelationshipsSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingRelationshipsManagement = false
    @State private var relationshipsCount: Int = 0
    @State private var isLoadingCount = true

    var body: some View {
        DetailSection(title: "Relationships") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingCount {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if relationshipsCount > 0 {
                    HStack {
                        Text("\(relationshipsCount) relationship\(relationshipsCount == 1 ? "" : "s")")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showingRelationshipsManagement = true }) {
                            Text("View")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingRelationshipsManagement = true }) {
                        Label("Add Relationship", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadRelationshipsCount()
        }
        .sheet(isPresented: $showingRelationshipsManagement) {
            if let apiContact = convertToContact(contact) {
                RelationshipsManagementView(contact: apiContact)
                    .environmentObject(authManager)
            }
        }
    }

    private func loadRelationshipsCount() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoadingCount = false
            return
        }

        do {
            let relationships = try await apiClient.fetchContactRelationships(contactId: Int(contact.id))
            relationshipsCount = relationships.count
        } catch {
            print("Failed to load relationships count: \(error)")
            relationshipsCount = 0
        }
        isLoadingCount = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Relationships Management Views

struct RelationshipsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var relationships: [Relationship] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedGroupId: Int? = nil
    @State private var showingAddRelationship = false

    // Use relationship type groups from authManager
    private var relationshipTypeGroups: [RelationshipTypeGroup] {
        authManager.availableRelationshipTypeGroups
    }

    // Create categories dynamically from the API groups
    private var categories: [(id: Int?, name: String)] {
        var result: [(id: Int?, name: String)] = [( id: nil, name: "All")]
        result.append(contentsOf: relationshipTypeGroups.map { (id: $0.id, name: $0.name) })
        return result
    }

    var filteredRelationships: [Relationship] {
        guard let groupId = selectedGroupId else {
            return relationships
        }
        return relationships.filter { $0.relationshipType.relationshipTypeGroupId == groupId }
    }

    private var selectedCategoryName: String {
        categories.first(where: { $0.id == selectedGroupId })?.name ?? "All"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker - dynamically built from API groups
                if categories.count <= 5 {
                    // Use segmented picker for 5 or fewer categories
                    Picker("Category", selection: $selectedGroupId) {
                        ForEach(categories, id: \.id) { category in
                            Text(category.name).tag(category.id as Int?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                } else {
                    // Use menu picker for more than 5 categories
                    Picker("Category", selection: $selectedGroupId) {
                        ForEach(categories, id: \.id) { category in
                            Text(category.name).tag(category.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                }

                // Content
                Group {
                    if isLoading {
                        ProgressView("Loading relationships...")
                    } else if filteredRelationships.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No \(selectedCategoryName) Relationships")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Add relationships to keep track of \(contact.firstName ?? "this contact")'s connections")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: { showingAddRelationship = true }) {
                                Label("Add Relationship", systemImage: "plus.circle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredRelationships) { relationship in
                                RelationshipRowView(relationship: relationship)
                            }
                            .onDelete { indexSet in
                                deleteRelationships(at: indexSet)
                            }
                        }
                        .refreshable {
                            await loadRelationships()
                        }
                    }
                }
            }
            .navigationTitle("Relationships")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !relationships.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddRelationship = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadRelationships()
        }
        .sheet(isPresented: $showingAddRelationship) {
            AddRelationshipView(contact: contact) {
                Task {
                    await loadRelationships()
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

    @MainActor
    private func loadRelationships() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            relationships = try await apiClient.fetchContactRelationships(contactId: contact.id)
            print("✅ Loaded \(relationships.count) relationships")
        } catch {
            errorMessage = "Failed to load relationships: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load relationships: \(error)")
        }
        isLoading = false
    }

    private func deleteRelationships(at offsets: IndexSet) {
        guard let apiClient = authManager.currentAPIClient else { return }

        Task {
            for index in offsets {
                let relationship = filteredRelationships[index]

                do {
                    try await apiClient.deleteRelationship(relationshipId: relationship.id)
                    print("✅ Deleted relationship \(relationship.id)")

                    // Remove from local array
                    await MainActor.run {
                        if let globalIndex = relationships.firstIndex(where: { $0.id == relationship.id }) {
                            relationships.remove(at: globalIndex)
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to delete relationship: \(error.localizedDescription)"
                        showingError = true
                        print("❌ Failed to delete relationship: \(error)")
                    }
                }
            }
        }
    }
}

struct RelationshipRowView: View {
    let relationship: Relationship

    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            InitialsAvatar(
                initials: relationship.ofContact.initials,
                backgroundColor: .blue,
                size: 40
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(relationship.ofContact.completeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(relationship.relationshipType.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add Relationship View

struct AddRelationshipView: View {
    let contact: Contact
    let onRelationshipAdded: () -> Void

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchResults: [Contact] = []
    @State private var selectedContact: Contact?
    @State private var selectedRelationshipType: RelationshipType?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var hasMoreResults = false

    // Use relationship types from authManager instead of fetching them
    private var relationshipTypes: [RelationshipType] {
        authManager.availableRelationshipTypes
    }

    // Group relationship types by their group for better organization
    private var groupedRelationshipTypes: [(RelationshipTypeGroup, [RelationshipType])] {
        let groups = authManager.availableRelationshipTypeGroups
        return groups.map { group in
            let typesInGroup = relationshipTypes.filter { $0.relationshipTypeGroupId == group.id }
            return (group, typesInGroup)
        }.filter { !$0.1.isEmpty }  // Only include groups that have types
    }

    var displayedContacts: [Contact] {
        searchResults.filter { $0.id != contact.id }
    }

    // Format relationship type name for display (remove possessive form)
    private func displayName(for type: RelationshipType) -> String {
        // The API returns names like "real_name's grandfather" or "love_relationship"
        // We want to show just "grandfather" or "significant other"
        let name = type.name

        // Remove possessive patterns like "real_name's " or "contact_name's "
        if let apostropheRange = name.range(of: "'s ") {
            return String(name[apostropheRange.upperBound...])
        }

        // Replace underscores with spaces and capitalize
        return name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Select Contact") {
                    TextField("Search contacts by name", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: searchText) { newValue in
                            Task {
                                await performSearch(query: newValue)
                            }
                        }

                    if let selected = selectedContact {
                        HStack {
                            InitialsAvatar(
                                initials: selected.initials,
                                backgroundColor: .blue,
                                size: 30
                            )
                            Text(selected.completeName)
                                .font(.body)
                            Spacer()
                            Button("Change") {
                                selectedContact = nil
                                searchText = ""
                                searchResults = []
                            }
                            .font(.subheadline)
                        }
                    } else {
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 8)
                                Spacer()
                            }
                        } else if searchText.isEmpty {
                            Text("Start typing to search for contacts")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.caption)
                        } else if displayedContacts.isEmpty {
                            Text("No contacts found")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(displayedContacts) { c in
                                Button(action: {
                                    selectedContact = c
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    HStack {
                                        InitialsAvatar(
                                            initials: c.initials,
                                            backgroundColor: .blue,
                                            size: 30
                                        )
                                        VStack(alignment: .leading) {
                                            Text(c.completeName)
                                                .foregroundColor(.primary)
                                            if let nickname = c.nickname {
                                                Text(nickname)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }

                            if hasMoreResults {
                                Text("Not all results shown - please be more specific with your search")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .italic()
                            }
                        }
                    }
                }

                if selectedContact != nil {
                    // Show relationship types grouped by category
                    ForEach(groupedRelationshipTypes, id: \.0.id) { group, types in
                        Section(group.name.capitalized) {
                            ForEach(types) { type in
                                Button(action: {
                                    selectedRelationshipType = type
                                }) {
                                    HStack {
                                        Text(displayName(for: type))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedRelationshipType?.id == type.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let type = selectedRelationshipType {
                        Section {
                            Text("\(contact.firstName ?? "This contact") is \(displayName(for: type).lowercased()) of \(selectedContact?.firstName ?? "the selected contact")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addRelationship()
                    }
                    .disabled(selectedContact == nil || selectedRelationshipType == nil || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @MainActor
    private func performSearch(query: String) async {
        // Don't search if query is too short
        guard query.count >= 2 else {
            searchResults = []
            hasMoreResults = false
            return
        }

        guard let apiClient = authManager.currentAPIClient else {
            return
        }

        isSearching = true

        do {
            let response = try await apiClient.searchContacts(query: query, limit: 50)
            searchResults = response.data

            // Check if there might be more results (if we got exactly the limit)
            hasMoreResults = response.data.count >= 50

            print("✅ Found \(searchResults.count) contacts for query '\(query)'")
        } catch {
            print("❌ Search failed: \(error.localizedDescription)")
            searchResults = []
            hasMoreResults = false
        }

        isSearching = false
    }

    private func addRelationship() {
        guard let apiClient = authManager.currentAPIClient,
              let selectedContact = selectedContact,
              let selectedType = selectedRelationshipType else {
            return
        }

        isSubmitting = true

        Task {
            do {
                _ = try await apiClient.createRelationship(
                    contactIs: contact.id,
                    ofContact: selectedContact.id,
                    relationshipTypeId: selectedType.id
                )

                await MainActor.run {
                    onRelationshipAdded()
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create relationship: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - How You Met Section

struct HowYouMetSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditor = false
    @State private var howYouMet: HowYouMet?
    @State private var isLoading = true

    var body: some View {
        DetailSection(title: "How You Met") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let info = howYouMet, info.generalInformation != nil || info.firstMetDate != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let generalInfo = info.generalInformation, !generalInfo.isEmpty {
                            Text(generalInfo)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }

                        if let dateInfo = info.firstMetDate, let date = dateInfo.date {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("First met: \(date.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: { showingEditor = true }) {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingEditor = true }) {
                        Label("Add How You Met", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadHowYouMet()
        }
        .sheet(isPresented: $showingEditor) {
            if let apiContact = convertToContact(contact) {
                HowYouMetEditorView(contact: apiContact, howYouMet: howYouMet) { updated in
                    howYouMet = updated
                }
                .environmentObject(authManager)
            }
        }
    }

    private func loadHowYouMet() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoading = false
            return
        }

        do {
            let fullContact = try await apiClient.fetchSingleContact(id: Int(contact.id))
            howYouMet = fullContact.information?.howYouMet
        } catch {
            print("Failed to load how you met: \(error)")
        }
        isLoading = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - How You Met Editor

struct HowYouMetEditorView: View {
    let contact: Contact
    let howYouMet: HowYouMet?
    let onSave: (HowYouMet?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Story") {
                    if let info = howYouMet?.generalInformation, !info.isEmpty {
                        Text(info)
                            .frame(minHeight: 150, alignment: .topLeading)
                    } else {
                        Text("No information about how you met")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .headerProminence(.increased)

                Section("First Met Date") {
                    if let date = howYouMet?.firstMetDate?.date {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(date, style: .date)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No date recorded")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .headerProminence(.increased)

                Section {
                    Text("How you met information is read-only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("How You Met")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Work Information Section

struct WorkInformationSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditor = false
    @State private var careerInfo: CareerInfo?
    @State private var isLoading = true

    var body: some View {
        DetailSection(title: "Work Information") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let career = careerInfo, career.job != nil || career.company != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let job = career.job, !job.isEmpty {
                            HStack {
                                Image(systemName: "briefcase")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(job)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }

                        if let company = career.company, !company.isEmpty {
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(company)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }

                        Button(action: { showingEditor = true }) {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingEditor = true }) {
                        Label("Add Work Information", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadWorkInformation()
        }
        .sheet(isPresented: $showingEditor) {
            if let apiContact = convertToContact(contact) {
                WorkInformationEditorView(contact: apiContact, careerInfo: careerInfo) { updated in
                    careerInfo = updated
                }
                .environmentObject(authManager)
            }
        }
    }

    private func loadWorkInformation() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoading = false
            return
        }

        do {
            let fullContact = try await apiClient.fetchSingleContact(id: Int(contact.id))
            careerInfo = fullContact.information?.career
        } catch {
            print("Failed to load work information: \(error)")
        }
        isLoading = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Work Information Editor

struct WorkInformationEditorView: View {
    let contact: Contact
    let careerInfo: CareerInfo?
    let onSave: (CareerInfo?) -> Void

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var jobTitle: String
    @State private var company: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(contact: Contact, careerInfo: CareerInfo?, onSave: @escaping (CareerInfo?) -> Void) {
        self.contact = contact
        self.careerInfo = careerInfo
        self.onSave = onSave
        _jobTitle = State(initialValue: careerInfo?.job ?? "")
        _company = State(initialValue: careerInfo?.company ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Position") {
                    TextField("Job Title", text: $jobTitle)
                }
                .headerProminence(.increased)

                Section("Organization") {
                    TextField("Company", text: $company)
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Work Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkInformation()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func saveWorkInformation() {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "Not authenticated"
            showingError = true
            return
        }

        isSubmitting = true

        Task {
            do {
                // Update via /contacts/{id}/work endpoint
                try await apiClient.updateContactWork(
                    contactId: contact.id,
                    jobTitle: jobTitle.isEmpty ? nil : jobTitle,
                    company: company.isEmpty ? nil : company
                )

                // Update local state
                await MainActor.run {
                    let updatedCareerInfo = CareerInfo(
                        job: jobTitle.isEmpty ? nil : jobTitle,
                        company: company.isEmpty ? nil : company
                    )
                    onSave(updatedCareerInfo)
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Food Preferences Section

struct FoodPreferencesSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditor = false
    @State private var foodPreferences: String?
    @State private var isLoading = true

    var body: some View {
        DetailSection(title: "Food Preferences") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let prefs = foodPreferences, !prefs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(prefs)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Button(action: { showingEditor = true }) {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingEditor = true }) {
                        Label("Add Food Preferences", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadFoodPreferences()
        }
        .sheet(isPresented: $showingEditor) {
            if let apiContact = convertToContact(contact) {
                FoodPreferencesEditorView(contact: apiContact, foodPreferences: foodPreferences) { updated in
                    foodPreferences = updated
                }
                .environmentObject(authManager)
            }
        }
    }

    private func loadFoodPreferences() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoading = false
            return
        }

        do {
            let fullContact = try await apiClient.fetchSingleContact(id: Int(contact.id))
            foodPreferences = fullContact.information?.foodPreferences
        } catch {
            print("Failed to load food preferences: \(error)")
        }
        isLoading = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Food Preferences Editor

struct FoodPreferencesEditorView: View {
    let contact: Contact
    let foodPreferences: String?
    let onSave: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Preferences") {
                    if let preferences = foodPreferences, !preferences.isEmpty {
                        Text(preferences)
                            .frame(minHeight: 150, alignment: .topLeading)
                    } else {
                        Text("No food preferences recorded")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .headerProminence(.increased)

                Section {
                    Text("Food preferences are read-only. They can include likes, dislikes, allergies, dietary restrictions, favorite foods, etc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Food Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Stay in Touch Section

struct StayInTouchSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingEditor = false
    @State private var stayInTouchInfo: (frequency: String?, triggerDate: Date?)?
    @State private var isLoading = true

    var body: some View {
        DetailSection(title: "Stay in Touch") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let info = stayInTouchInfo, info.frequency != nil || info.triggerDate != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let frequency = info.frequency, !frequency.isEmpty {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("Every \(frequency)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }

                        if let triggerDate = info.triggerDate {
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("Next: \(triggerDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }

                        Button(action: { showingEditor = true }) {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingEditor = true }) {
                        Label("Set Reminder", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadStayInTouch()
        }
        .sheet(isPresented: $showingEditor) {
            if let apiContact = convertToContact(contact) {
                StayInTouchEditorView(contact: apiContact, stayInTouchInfo: stayInTouchInfo) { updated in
                    stayInTouchInfo = updated
                }
                .environmentObject(authManager)
            }
        }
    }

    private func loadStayInTouch() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoading = false
            return
        }

        do {
            let fullContact = try await apiClient.fetchSingleContact(id: Int(contact.id))
            stayInTouchInfo = (frequency: fullContact.stayInTouchFrequency, triggerDate: fullContact.stayInTouchTriggerDate)
        } catch {
            print("Failed to load stay in touch: \(error)")
        }
        isLoading = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Stay in Touch Editor

struct StayInTouchEditorView: View {
    let contact: Contact
    let stayInTouchInfo: (frequency: String?, triggerDate: Date?)?
    let onSave: ((frequency: String?, triggerDate: Date?)?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Frequency") {
                    HStack {
                        Text("Contact every")
                        Spacer()
                        if let frequency = stayInTouchInfo?.frequency {
                            Text(frequency)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .headerProminence(.increased)

                Section("Next Contact") {
                    if let triggerDate = stayInTouchInfo?.triggerDate {
                        HStack {
                            Text("Reminder date")
                            Spacer()
                            Text(triggerDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No reminder set")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .headerProminence(.increased)

                Section {
                    Text("Stay in Touch information is read-only. It helps you maintain regular contact with people who matter to you.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Stay in Touch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tags Section

struct TagsSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var tags: [Tag] = []
    @State private var isLoading = true

    var body: some View {
        DetailSection(title: "Tags") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if !tags.isEmpty {
                    // Tag badges in a flexible wrapped layout
                    FlowLayout(spacing: 8) {
                        ForEach(tags) { tag in
                            TagBadge(tag: tag)
                        }
                    }
                } else {
                    Text("No tags")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .task {
            await loadTags()
        }
    }

    private func loadTags() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoading = false
            return
        }

        do {
            tags = try await apiClient.fetchContactTags(contactId: Int(contact.id))
            print("✅ Loaded \(tags.count) tags for contact")
        } catch {
            print("❌ Failed to load tags: \(error)")
            tags = []
        }
        isLoading = false
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tagColor.opacity(0.2))
            .foregroundColor(tagColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tagColor.opacity(0.4), lineWidth: 1)
            )
    }

    // Generate a consistent color based on tag name
    private var tagColor: Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .red, .yellow, .cyan, .indigo, .teal
        ]
        let hash = tag.name.hash
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))

                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Addresses Section

struct AddressesSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingAddressManagement = false
    @State private var addressesCount: Int = 0
    @State private var isLoadingCount = true

    var body: some View {
        DetailSection(title: "Addresses") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingCount {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if addressesCount > 0 {
                    HStack {
                        Text("\(addressesCount) address\(addressesCount == 1 ? "" : "es")")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showingAddressManagement = true }) {
                            Text("View")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingAddressManagement = true }) {
                        Label("Add Address", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadAddressesCount()
        }
        .sheet(isPresented: $showingAddressManagement) {
            if let apiClient = authManager.currentAPIClient {
                AddressManagementSheet(contactId: Int(contact.id), apiClient: apiClient)
            }
        }
    }

    private func loadAddressesCount() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoadingCount = false
            return
        }

        do {
            let addresses = try await apiClient.fetchAddresses(contactId: Int(contact.id))
            addressesCount = addresses.count
        } catch {
            print("Failed to load addresses count: \(error)")
            addressesCount = 0
        }
        isLoadingCount = false
    }
}

/// Sheet wrapper for address management that creates and manages the ViewModel
struct AddressManagementSheet: View {
    let contactId: Int
    let apiClient: MonicaAPIClient

    @StateObject private var viewModel: AddressViewModel
    @State private var showingAddForm = false
    @State private var addressToEdit: Address?
    @State private var addressToDelete: Address?
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(contactId: Int, apiClient: MonicaAPIClient) {
        self.contactId = contactId
        self.apiClient = apiClient
        _viewModel = StateObject(wrappedValue: AddressViewModel(
            contactId: contactId,
            apiClient: apiClient,
            cacheService: CacheService.shared
        ))
    }

    var body: some View {
        NavigationView {
            List {
                AddressListView(
                    viewModel: viewModel,
                    onAddAddress: { showingAddForm = true },
                    onEditAddress: { address in addressToEdit = address },
                    onDirections: { address in openDirections(for: address) },
                    onMapTap: { address in openDirections(for: address) },
                    onDeleteAddress: { address in
                        addressToDelete = address
                        showDeleteConfirmation = true
                    }
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Addresses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await viewModel.loadAddresses()
        }
        .sheet(isPresented: $showingAddForm) {
            AddressFormSheet(
                contactId: contactId,
                apiClient: apiClient,
                mode: .create,
                onDismiss: {
                    showingAddForm = false
                    Task { await viewModel.loadAddresses() }
                }
            )
        }
        .sheet(item: $addressToEdit) { address in
            AddressFormSheet(
                contactId: contactId,
                apiClient: apiClient,
                mode: .edit(address),
                onDismiss: {
                    addressToEdit = nil
                    Task { await viewModel.loadAddresses() }
                }
            )
        }
        .alert("Delete Address", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                addressToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let address = addressToDelete {
                    Task {
                        await viewModel.deleteAddress(id: address.id)
                    }
                }
                addressToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this address? This action cannot be undone.")
        }
    }

    private func openDirections(for address: Address) {
        let addressString = address.formattedAddress
        if let encoded = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "maps://?daddr=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

/// Sheet wrapper for address form that handles navigation and callbacks
struct AddressFormSheet: View {
    let contactId: Int
    let apiClient: MonicaAPIClient
    let mode: AddressFormMode
    let onDismiss: () -> Void

    @StateObject private var formViewModel: AddressFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(contactId: Int, apiClient: MonicaAPIClient, mode: AddressFormMode, onDismiss: @escaping () -> Void) {
        self.contactId = contactId
        self.apiClient = apiClient
        self.mode = mode
        self.onDismiss = onDismiss
        _formViewModel = StateObject(wrappedValue: AddressFormViewModel(
            contactId: contactId,
            apiClient: apiClient,
            cacheService: CacheService.shared,
            mode: mode
        ))
    }

    var body: some View {
        AddressFormView(viewModel: formViewModel)
            .onChange(of: formViewModel.state) { newState in
                if newState == .success {
                    onDismiss()
                }
            }
    }
}

// MARK: - Gifts Section

struct GiftsSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingGiftsManagement = false
    @State private var giftsCount: Int = 0
    @State private var isLoadingCount = true

    var body: some View {
        DetailSection(title: "Gifts") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingCount {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if giftsCount > 0 {
                    HStack {
                        Text("\(giftsCount) gift\(giftsCount == 1 ? "" : "s")")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showingGiftsManagement = true }) {
                            Text("View")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingGiftsManagement = true }) {
                        Label("Add Gift", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadGiftsCount()
        }
        .sheet(isPresented: $showingGiftsManagement) {
            if let apiContact = convertToContact(contact) {
                GiftsManagementView(contact: apiContact)
                    .environmentObject(authManager)
            }
        }
    }

    private func loadGiftsCount() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoadingCount = false
            return
        }

        do {
            let response = try await apiClient.getGifts(for: Int(contact.id))
            giftsCount = response.data.count
        } catch {
            print("Failed to load gifts count: \(error)")
            giftsCount = 0
        }
        isLoadingCount = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Gifts Management Views

struct GiftsManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var gifts: [Gift] = []
    @State private var isLoading = true
    @State private var showingAddGift = false
    @State private var editingGift: Gift?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedCategory: GiftCategory?

    var filteredGifts: [Gift] {
        guard let category = selectedCategory else {
            return gifts
        }
        return gifts.filter { $0.category == category }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as GiftCategory?)
                    ForEach(GiftCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as GiftCategory?)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    if isLoading {
                        ProgressView("Loading gifts...")
                    } else if filteredGifts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "gift")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No \(selectedCategory?.rawValue ?? "Gifts")")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Add gifts to remember what to give or what \(contact.firstName ?? "this contact") has received")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: { showingAddGift = true }) {
                                Label("Add Gift", systemImage: "plus.circle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredGifts) { gift in
                                GiftRowView(gift: gift, onEdit: {
                                    editingGift = gift
                                }, onDelete: {
                                    deleteGift(gift)
                                })
                            }
                        }
                        .refreshable {
                            await loadGifts()
                        }
                    }
                }
            }
            .navigationTitle("Gifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !gifts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddGift = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadGifts()
        }
        .sheet(isPresented: $showingAddGift) {
            AddGiftView(contact: contact) { newGift in
                gifts.insert(newGift, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingGift) { gift in
            EditGiftView(gift: gift) { updatedGift in
                if let index = gifts.firstIndex(where: { $0.id == updatedGift.id }) {
                    gifts[index] = updatedGift
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

    @MainActor
    private func loadGifts() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getGifts(for: contact.id)
            gifts = response.data.sorted {
                ($0.createdAt) > ($1.createdAt)
            }
            print("✅ Loaded \(gifts.count) gifts")
        } catch {
            errorMessage = "Failed to load gifts: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load gifts: \(error)")
        }
        isLoading = false
    }

    private func deleteGift(_ gift: Gift) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteGift(id: gift.id)
                await MainActor.run {
                    gifts.removeAll { $0.id == gift.id }
                }
                print("✅ Deleted gift")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete gift: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete gift: \(error)")
            }
        }
    }
}

struct GiftRowView: View {
    let gift: Gift
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(gift.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Text(gift.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)
            }

            if let comment = gift.comment, !comment.isEmpty {
                Text(comment)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let value = gift.value {
                    Text("$\(value, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let url = gift.url, !url.isEmpty {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private var categoryColor: Color {
        switch gift.category {
        case .idea:
            return .orange
        case .given:
            return .green
        case .received:
            return .blue
        }
    }
}

struct AddGiftView: View {
    let contact: Contact
    let onGiftAdded: (Gift) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var giftName = ""
    @State private var giftComment = ""
    @State private var giftUrl = ""
    @State private var giftValue = ""
    @State private var isAnIdea = false
    @State private var hasBeenOffered = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Gift Details") {
                    TextField("Name", text: $giftName)

                    Toggle("This is a gift idea", isOn: $isAnIdea)
                    Toggle("Gift has been offered", isOn: $hasBeenOffered)
                        .disabled(isAnIdea)
                }

                Section("Additional Information") {
                    TextField("Comment (optional)", text: $giftComment, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("URL (optional)", text: $giftUrl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("Value (optional)", text: $giftValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitGift()
                    }
                    .disabled(giftName.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitGift() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let valueDouble = Double(giftValue.trimmingCharacters(in: .whitespaces))
                let response = try await apiClient.createGift(
                    for: contact.id,
                    name: giftName,
                    comment: giftComment.isEmpty ? nil : giftComment,
                    isAnIdea: isAnIdea,
                    hasBeenOffered: hasBeenOffered && !isAnIdea,
                    url: giftUrl.isEmpty ? nil : giftUrl,
                    value: valueDouble
                )

                await MainActor.run {
                    onGiftAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create gift: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditGiftView: View {
    let gift: Gift
    let onGiftUpdated: (Gift) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var giftName: String
    @State private var giftComment: String
    @State private var giftUrl: String
    @State private var giftValue: String
    @State private var isAnIdea: Bool
    @State private var hasBeenOffered: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(gift: Gift, onGiftUpdated: @escaping (Gift) -> Void) {
        self.gift = gift
        self.onGiftUpdated = onGiftUpdated
        _giftName = State(initialValue: gift.name)
        _giftComment = State(initialValue: gift.comment ?? "")
        _giftUrl = State(initialValue: gift.url ?? "")
        _giftValue = State(initialValue: gift.value != nil ? String(gift.value!) : "")
        _isAnIdea = State(initialValue: gift.isAnIdea)
        _hasBeenOffered = State(initialValue: gift.hasBeenOffered)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Gift Details") {
                    TextField("Name", text: $giftName)

                    Toggle("This is a gift idea", isOn: $isAnIdea)
                    Toggle("Gift has been offered", isOn: $hasBeenOffered)
                        .disabled(isAnIdea)
                }

                Section("Additional Information") {
                    TextField("Comment (optional)", text: $giftComment, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("URL (optional)", text: $giftUrl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("Value (optional)", text: $giftValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitGift()
                    }
                    .disabled(giftName.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitGift() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let valueDouble = Double(giftValue.trimmingCharacters(in: .whitespaces))
                let response = try await apiClient.updateGift(
                    id: gift.id,
                    name: giftName,
                    comment: giftComment.isEmpty ? nil : giftComment,
                    isAnIdea: isAnIdea,
                    hasBeenOffered: hasBeenOffered && !isAnIdea,
                    url: giftUrl.isEmpty ? nil : giftUrl,
                    value: valueDouble
                )

                await MainActor.run {
                    onGiftUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update gift: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Tasks Section

struct TasksSection: View {
    let contact: ContactEntity
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingTasksManagement = false
    @State private var tasksCount: Int = 0
    @State private var pendingTasksCount: Int = 0
    @State private var isLoadingCount = true

    var body: some View {
        DetailSection(title: "Tasks") {
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingCount {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if tasksCount > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(tasksCount) task\(tasksCount == 1 ? "" : "s")")
                                .font(.body)
                                .foregroundColor(.secondary)

                            if pendingTasksCount > 0 {
                                Text("\(pendingTasksCount) pending")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        Button(action: { showingTasksManagement = true }) {
                            Text("View")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Button(action: { showingTasksManagement = true }) {
                        Label("Add Task", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await loadTasksCount()
        }
        .sheet(isPresented: $showingTasksManagement) {
            if let apiContact = convertToContact(contact) {
                TasksManagementView(contact: apiContact)
                    .environmentObject(authManager)
            }
        }
    }

    private func loadTasksCount() async {
        guard let apiClient = authManager.currentAPIClient else {
            isLoadingCount = false
            return
        }

        do {
            let response = try await apiClient.getTasks(for: Int(contact.id))
            tasksCount = response.data.count
            pendingTasksCount = response.data.filter { !$0.isCompleted }.count
        } catch {
            print("Failed to load tasks count: \(error)")
            tasksCount = 0
            pendingTasksCount = 0
        }
        isLoadingCount = false
    }

    // Helper to convert ContactEntity to Contact for API calls
    private func convertToContact(_ entity: ContactEntity) -> Contact? {
        return Contact(
            id: Int(entity.id),
            uuid: "",
            object: "contact",
            hashId: "",
            firstName: entity.firstName,
            lastName: entity.lastName,
            nickname: entity.nickname,
            completeName: entity.fullName,
            initials: entity.initials,
            description: nil,
            gender: nil,
            genderType: nil,
            isStarred: entity.isStarred,
            isPartial: false,
            isActive: true,
            isDead: false,
            isMe: false,
            lastCalled: nil,
            lastActivityTogether: nil,
            stayInTouchFrequency: nil,
            stayInTouchTriggerDate: nil,
            email: entity.email,
            phone: entity.phone,
            birthdate: entity.birthdate,
            birthdateIsAgeBased: entity.birthdateIsAgeBased,
            birthdateAge: Int(entity.birthdateAge),
            isBirthdateKnown: entity.isBirthdateKnown,
            address: entity.address,
            company: entity.company,
            jobTitle: entity.jobTitle,
            notes: entity.notes,
            relationships: nil,
            information: nil,
            addresses: nil,
            tags: nil,
            statistics: nil,
            url: "",
            account: Account(id: 1),
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}

// MARK: - Tasks Management Views

struct TasksManagementView: View {
    let contact: Contact
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var tasks: [MonicaTask] = []
    @State private var isLoading = true
    @State private var showingAddTask = false
    @State private var editingTask: MonicaTask?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showCompletedTasks = false

    var filteredTasks: [MonicaTask] {
        if showCompletedTasks {
            return tasks
        } else {
            return tasks.filter { !$0.isCompleted }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter toggle
                Toggle("Show completed tasks", isOn: $showCompletedTasks)
                    .padding()

                // Content
                Group {
                    if isLoading {
                        ProgressView("Loading tasks...")
                    } else if filteredTasks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text(showCompletedTasks ? "No Tasks" : "No Pending Tasks")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Add tasks to track things you need to do for \(contact.firstName ?? "this contact")")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: { showingAddTask = true }) {
                                Label("Add Task", systemImage: "plus.circle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRowView(task: task, onToggle: {
                                    toggleTaskCompletion(task)
                                }, onEdit: {
                                    editingTask = task
                                }, onDelete: {
                                    deleteTask(task)
                                })
                            }
                        }
                        .refreshable {
                            await loadTasks()
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !tasks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            await loadTasks()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(contact: contact) { newTask in
                tasks.insert(newTask, at: 0)
            }
            .environmentObject(authManager)
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task) { updatedTask in
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    tasks[index] = updatedTask
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

    @MainActor
    private func loadTasks() async {
        guard let apiClient = authManager.currentAPIClient else { return }

        isLoading = true
        do {
            let response = try await apiClient.getTasks(for: contact.id)
            tasks = response.data.sorted {
                // Sort by: incomplete first, then by creation date
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }
                return $0.createdAt > $1.createdAt
            }
            print("✅ Loaded \(tasks.count) tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            showingError = true
            print("❌ Failed to load tasks: \(error)")
        }
        isLoading = false
    }

    private func toggleTaskCompletion(_ task: MonicaTask) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                let response = try await apiClient.updateTask(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    isCompleted: !task.isCompleted
                )

                let updatedTask = response.data
                await MainActor.run {
                    tasks = tasks.map { $0.id == task.id ? updatedTask : $0 }
                }
                print("✅ Toggled task completion")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update task: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to toggle task completion: \(error)")
            }
        }
    }

    private func deleteTask(_ task: MonicaTask) {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            do {
                try await apiClient.deleteTask(id: task.id)
                await MainActor.run {
                    tasks.removeAll { $0.id == task.id }
                }
                print("✅ Deleted task")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete task: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Failed to delete task: \(error)")
            }
        }
    }
}

struct TaskRowView: View {
    let task: MonicaTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct AddTaskView: View {
    let contact: Contact
    let onTaskAdded: (MonicaTask) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $taskTitle)
                }

                Section("Description") {
                    TextEditor(text: $taskDescription)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitTask()
                    }
                    .disabled(taskTitle.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitTask() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.createTask(
                    for: contact.id,
                    title: taskTitle,
                    description: taskDescription.isEmpty ? nil : taskDescription,
                    isCompleted: false
                )

                await MainActor.run {
                    onTaskAdded(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create task: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

struct EditTaskView: View {
    let task: MonicaTask
    let onTaskUpdated: (MonicaTask) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var taskTitle: String
    @State private var taskDescription: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(task: MonicaTask, onTaskUpdated: @escaping (MonicaTask) -> Void) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        _taskTitle = State(initialValue: task.title)
        _taskDescription = State(initialValue: task.description ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $taskTitle)
                }

                Section("Description") {
                    TextEditor(text: $taskDescription)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitTask()
                    }
                    .disabled(taskTitle.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func submitTask() {
        Task {
            guard let apiClient = authManager.currentAPIClient else { return }

            await MainActor.run { isSubmitting = true }

            do {
                let response = try await apiClient.updateTask(
                    id: task.id,
                    title: taskTitle,
                    description: taskDescription.isEmpty ? nil : taskDescription,
                    isCompleted: nil
                )

                await MainActor.run {
                    onTaskUpdated(response.data)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update task: \(error.localizedDescription)"
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Birthday Editor

enum BirthdayOption: Hashable {
    case unknown
    case ageBased
    case dayMonthOnly
    case exactDate
}

struct BirthdayEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var birthdayOption: BirthdayOption
    @Binding var birthdate: Date
    @Binding var birthdayDay: Int
    @Binding var birthdayMonth: Int
    @Binding var estimatedAge: Int

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Birthday Information", selection: $birthdayOption) {
                        Text("I do not know this person's age").tag(BirthdayOption.unknown)
                        Text("This person is probably...").tag(BirthdayOption.ageBased)
                        Text("I know the day and month...").tag(BirthdayOption.dayMonthOnly)
                        Text("I know this person's exact birthday").tag(BirthdayOption.exactDate)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if birthdayOption == .ageBased {
                    Section {
                        Stepper("Age: \(estimatedAge)", value: $estimatedAge, in: 1...120)
                    } header: {
                        Text("Estimated Age")
                    }
                }

                if birthdayOption == .dayMonthOnly {
                    Section {
                        Picker("Month", selection: $birthdayMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthName(for: month)).tag(month)
                            }
                        }

                        Picker("Day", selection: $birthdayDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    } header: {
                        Text("Birthday (Day and Month)")
                    }
                }

                if birthdayOption == .exactDate {
                    Section {
                        DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
                            .datePickerStyle(.automatic)
                    } header: {
                        Text("Exact Birthdate")
                    }
                }
            }
            .navigationTitle("Age / Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }
}

// MARK: - Manage Section
struct ManageSection: View {
    let contactId: Int
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataController: DataController
    @State private var contact: Contact?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Manage")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
            } else if let contact = contact {
                VStack(spacing: 0) {
                    // TODO: Add other management views once API support is implemented
                    // ManagementNavigationLink(
                    //     icon: "note.text",
                    //     title: "Notes",
                    //     destination: NotesManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "checkmark.circle",
                    //     title: "Tasks",
                    //     destination: TasksManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "gift",
                    //     title: "Gifts",
                    //     destination: GiftsManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "figure.walk",
                    //     title: "Activities",
                    //     destination: ActivitiesManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "bell",
                    //     title: "Reminders",
                    //     destination: RemindersManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "message",
                    //     title: "Conversations",
                    //     destination: ConversationsManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "dollarsign.circle",
                    //     title: "Debts",
                    //     destination: DebtsManagementView(contact: contact)
                    // )
                    //
                    // ManagementNavigationLink(
                    //     icon: "doc",
                    //     title: "Documents",
                    //     destination: DocumentsManagementView(contact: contact)
                    // )

                    ManagementNavigationLink(
                        icon: "phone",
                        title: "Call History",
                        destination: CallLogListView(
                            viewModel: CallLogViewModel(
                                contactId: contact.id,
                                storage: CallLogStorage(dataController: dataController)
                            )
                        )
                    )

                    ManagementNavigationLink(
                        icon: "envelope",
                        title: "Contact Fields",
                        destination: ContactFieldsManagementView(contact: contact)
                    )
                }
                .background(Color(UIColor.systemGroupedBackground))
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .cornerRadius(10)
        .task {
            await loadContact()
        }
    }

    @MainActor
    private func loadContact() async {
        guard let apiClient = authManager.currentAPIClient else {
            errorMessage = "No API client available"
            isLoading = false
            return
        }

        isLoading = true
        do {
            contact = try await apiClient.fetchSingleContact(id: contactId)
        } catch {
            errorMessage = "Failed to load contact: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct ManagementNavigationLink<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.blue)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        Divider()
            .padding(.leading, 48)
    }
}

#Preview {
    NavigationView {
        ContactDetailView(contact: ContactEntity())
    }
}