import Foundation
import SwiftUI
import Combine

/// View model for managing contact list state and operations
@MainActor
class ContactListViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 1
    @Published var hasMorePages = false
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var showErrorAlert = false
    @Published var lastError: Error?
    @Published var retryAction: (() async -> Void)?
    
    private var searchCancellable: AnyCancellable?
    private let searchDebounceTime: TimeInterval = 0.3
    
    init() {
        setupSearchDebouncing()
    }
    
    private func setupSearchDebouncing() {
        searchCancellable = $searchQuery
            .removeDuplicates()
            .debounce(for: .seconds(searchDebounceTime), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                Task {
                    await self.performSearch(query: query)
                }
            }
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            isSearching = false
            return
        }
        
        isSearching = true
        // Search is handled by the FetchRequest predicate in ContactListView
        // This is just for managing the search state
        isSearching = false
    }
    
    func clearError() {
        errorMessage = nil
        showErrorAlert = false
        lastError = nil
    }
    
    func handleError(_ error: Error, retryHandler: (() async -> Void)? = nil) {
        lastError = error
        retryAction = retryHandler
        
        // Get user-friendly error message
        if let apiError = error as? MonicaAPIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        showErrorAlert = true
        isLoading = false
        isSearching = false
    }
    
    func retry() async {
        if let action = retryAction {
            clearError()
            await action()
        }
    }
}

/// Contact list state for managing UI updates
struct ContactListState {
    var isRefreshing: Bool = false
    var isLoadingMore: Bool = false
    var hasError: Bool = false
    var errorMessage: String?
    var totalContacts: Int = 0
    var loadedPages: Int = 0
    var hasMorePages: Bool = false
}