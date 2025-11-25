import SwiftUI

/// List view displaying call history for a contact
struct CallLogListView: View {
    @ObservedObject var viewModel: CallLogViewModel
    @State private var showingAddSheet = false
    @State private var editingCallLog: CallLogEntity?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.callLogs.isEmpty {
                // Loading state
                ProgressView("Loading call logs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.callLogs.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // List of call logs
                List {
                    ForEach(viewModel.callLogs) { callLog in
                        CallLogRowView(callLog: callLog, viewModel: viewModel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCallLog = callLog
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteCallLog(callLog)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingCallLog = callLog
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }

                    // Statistics footer
                    statisticsSection
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Call History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.resetForm()
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CallLogFormView(viewModel: viewModel) {
                viewModel.loadCallLogs()
            }
        }
        .sheet(item: $editingCallLog) { callLog in
            CallLogFormView(viewModel: viewModel, editingEntity: callLog) {
                viewModel.loadCallLogs()
            }
        }
        .onAppear {
            viewModel.loadCallLogs()
        }
        .refreshable {
            viewModel.loadCallLogs()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Call History")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Log your phone calls to keep track of conversations and stay connected.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.resetForm()
                showingAddSheet = true
            } label: {
                Label("Log a Call", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        Section {
            let stats = viewModel.getStatistics()

            HStack {
                Label("Total Calls", systemImage: "phone.fill")
                Spacer()
                Text("\(stats.total)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("With Details", systemImage: "note.text")
                Spacer()
                Text("\(stats.withDetails)")
                    .foregroundColor(.secondary)
            }

            if stats.pending > 0 {
                HStack {
                    Label("Pending Sync", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("\(stats.pending)")
                        .foregroundColor(.orange)
                }
            }
        } header: {
            Text("Statistics")
        }
    }
}

// MARK: - Preview

#Preview {
    let dataController = DataController(authManager: AuthenticationManager())
    let storage = CallLogStorage(dataController: dataController)
    let viewModel = CallLogViewModel(contactId: 1, storage: storage)

    return NavigationView {
        CallLogListView(viewModel: viewModel)
    }
}
