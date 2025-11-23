import SwiftUI

@main
struct MonicaClientApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var dataController: DataController
    
    init() {
        let authManager = AuthenticationManager()
        _authManager = StateObject(wrappedValue: authManager)
        _dataController = StateObject(wrappedValue: DataController(authManager: authManager))

        // Register notification categories on app launch
        // TODO: Add NotificationManager back when it's added to the project
        // NotificationManager.shared.registerNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            if dataController.isLoaded {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authManager)
                    .environmentObject(dataController)
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        print("⏳ Waiting for Core Data to initialize...")
                    }
            }
        }
    }
}