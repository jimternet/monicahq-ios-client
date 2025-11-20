import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    
    /// Returns a relative date string (e.g., "2 hours ago", "Yesterday")
    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns a formatted date string using the app's preferred format
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Returns a formatted date and time string
    func formattedDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is within the last week
    var isWithinLastWeek: Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return self >= weekAgo
    }
}

// MARK: - Date Extensions
extension Date {
    
    /// Returns an ISO8601 formatted string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    
    /// Returns initials from a full name string
    var initials: String {
        return self.components(separatedBy: .whitespaces)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
    
    /// Trims whitespace and newlines
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string is a valid email format
    var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Checks if string is a valid URL format
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// Returns a localized string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Color Extensions
extension Color {
    
    /// App brand colors
    static let monicaBlue = Color(red: 0.2, green: 0.4, blue: 1.0)
    static let monicaGreen = Color(red: 0.0, green: 0.8, blue: 0.4)
    static let monicaRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let monicaOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Semantic colors
    static let successGreen = Color(red: 0.0, green: 0.7, blue: 0.3)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let errorRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    /// Background colors
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    /// Text colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    /// Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    
    /// Hides the keyboard when tapping outside text fields
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Applies conditional modifiers
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies a corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Adds a border with specified color and width
    func border(_ color: Color, width: CGFloat = 1) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Adds a shadow with app-standard parameters
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Array Extensions
extension Array where Element == Contact {
    
    /// Sort contacts by name
    func sortedByName() -> [Contact] {
        return sorted { contact1, contact2 in
            let name1 = "\(contact1.firstName ?? "") \(contact1.lastName ?? "")".trimmed
            let name2 = "\(contact2.firstName ?? "") \(contact2.lastName ?? "")".trimmed
            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }
    }
    
    /// Filter contacts by search query
    func filtered(by query: String) -> [Contact] {
        guard !query.trimmed.isEmpty else { return self }
        
        return filter { contact in
            let fullName = "\(contact.firstName ?? "") \(contact.lastName ?? "")".trimmed
            let nickname = contact.nickname ?? ""
            let email = contact.email ?? ""
            
            return fullName.localizedCaseInsensitiveContains(query) ||
                   nickname.localizedCaseInsensitiveContains(query) ||
                   email.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Optional Extensions
extension Optional where Wrapped == String {
    
    /// Returns the string value or empty string if nil
    var orEmpty: String {
        return self ?? ""
    }
    
    /// Returns true if the optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

// MARK: - Contact Extensions
extension Contact {
    
    /// Full display name
    var displayName: String {
        let fullName = "\(firstName ?? "") \(lastName ?? "")".trimmed
        return fullName.isEmpty ? "Unknown Contact" : fullName
    }
    
    /// Initials for avatar display
    /// Primary contact method (email or phone)
    var primaryContactMethod: String? {
        return email ?? phone
    }

    /// Check if contact has complete information
    var isComplete: Bool {
        return firstName != nil && !firstName!.isEmpty
    }
}