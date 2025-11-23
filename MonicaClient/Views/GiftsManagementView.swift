import SwiftUI

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
    @State private var selectedCategory: GiftCategory = .idea

    var filteredGifts: [Gift] {
        gifts.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GiftCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    if isLoading {
                        ProgressView("Loading gifts...")
                    } else if filteredGifts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "gift")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No \(selectedCategory.rawValue)")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Add your first \(selectedCategory.rawValue.lowercased()) for \(contact.firstName ?? "this contact")")
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
            AddGiftView(contact: contact, initialCategory: selectedCategory) { newGift in
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
            let response = try await apiClient.getGifts(for: contact.id, limit: 100)
            gifts = response.data.sorted { $0.createdAt > $1.createdAt }
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
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let value = gift.value {
                    Text("$\(value, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let comment = gift.comment, !comment.isEmpty {
                Text(comment)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let url = gift.url, !url.isEmpty {
                    Label("Link", systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(gift.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct AddGiftView: View {
    let contact: Contact
    let initialCategory: GiftCategory
    let onGiftAdded: (Gift) -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var comment = ""
    @State private var url = ""
    @State private var value = ""
    @State private var category: GiftCategory
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(contact: Contact, initialCategory: GiftCategory, onGiftAdded: @escaping (Gift) -> Void) {
        self.contact = contact
        self.initialCategory = initialCategory
        self.onGiftAdded = onGiftAdded
        _category = State(initialValue: initialCategory)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Gift Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(GiftCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Value (optional)", text: $value)
                        .keyboardType(.decimalPad)

                    TextField("URL (optional)", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Notes") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
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
                    .disabled(name.isEmpty || isSubmitting)
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
                let giftValue = value.isEmpty ? nil : Double(value)

                let response = try await apiClient.createGift(
                    contactId: contact.id,
                    name: name,
                    comment: comment.isEmpty ? nil : comment,
                    status: category,
                    url: url.isEmpty ? nil : url,
                    value: giftValue
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

    @State private var name: String
    @State private var comment: String
    @State private var url: String
    @State private var value: String
    @State private var category: GiftCategory
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(gift: Gift, onGiftUpdated: @escaping (Gift) -> Void) {
        self.gift = gift
        self.onGiftUpdated = onGiftUpdated
        _name = State(initialValue: gift.name)
        _comment = State(initialValue: gift.comment ?? "")
        _url = State(initialValue: gift.url ?? "")
        _value = State(initialValue: gift.value.map { String($0) } ?? "")
        _category = State(initialValue: gift.category)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Gift Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(GiftCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Value (optional)", text: $value)
                        .keyboardType(.decimalPad)

                    TextField("URL (optional)", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Notes") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
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
                    .disabled(name.isEmpty || isSubmitting)
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
                let giftValue = value.isEmpty ? nil : Double(value)

                let response = try await apiClient.updateGift(
                    id: gift.id,
                    name: name,
                    comment: comment.isEmpty ? nil : comment,
                    status: category,
                    url: url.isEmpty ? nil : url,
                    value: giftValue
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
