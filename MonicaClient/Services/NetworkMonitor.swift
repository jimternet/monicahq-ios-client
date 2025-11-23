import Foundation
import Network
import Combine
import SwiftUI

/// Monitors network connectivity status
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType = NWInterface.InterfaceType.other
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = .other
                }
                
                // Log connection changes
                if let self = self {
                    print("🌐 Network status: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionTypeString)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private var connectionTypeString: String {
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        default:
            return "Unknown"
        }
    }
    
    func checkConnectivity() -> Bool {
        return isConnected
    }
    
    deinit {
        monitor.cancel()
    }
}

/// Network connectivity alert modifier
struct NetworkAlertModifier: ViewModifier {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingAlert = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: networkMonitor.isConnected) { newValue in
                if !newValue {
                    showingAlert = true
                }
            }
            .alert("No Internet Connection", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please check your internet connection and try again.")
            }
    }
}

extension View {
    func networkAlert() -> some View {
        modifier(NetworkAlertModifier())
    }
}