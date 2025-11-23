import Foundation

/// Date formatting utilities for consistent date display throughout the app
class DateFormatting {
    
    static let shared = DateFormatting()
    
    private init() {}
    
    // MARK: - Formatters
    
    private lazy var iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private lazy var displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private lazy var displayWithTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private lazy var relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    private lazy var shortRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    private lazy var birthdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()
    
    private lazy var yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Parse ISO8601 date string from API
    func parseISO8601(_ dateString: String) -> Date? {
        return iso8601Formatter.date(from: dateString)
    }
    
    /// Format date to ISO8601 string for API
    func formatISO8601(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    /// Format date for display in lists (e.g., "Jan 15, 2024")
    func formatForDisplay(_ date: Date) -> String {
        return displayFormatter.string(from: date)
    }
    
    /// Format date with time for detailed views (e.g., "Jan 15, 2024 at 2:30 PM")
    func formatForDisplayWithTime(_ date: Date) -> String {
        return displayWithTimeFormatter.string(from: date)
    }
    
    /// Format date as relative string (e.g., "2 hours ago", "Yesterday")
    func formatRelative(_ date: Date) -> String {
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format date as short relative string (e.g., "2h ago", "1d ago")
    func formatShortRelative(_ date: Date) -> String {
        return shortRelativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format birthday (e.g., "March 15")
    func formatBirthday(_ date: Date) -> String {
        return birthdayFormatter.string(from: date)
    }
    
    /// Get age from birthdate
    func age(from birthdate: Date) -> Int? {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
        return ageComponents.year
    }
    
    /// Check if birthday is upcoming (within next 30 days)
    func isUpcomingBirthday(_ birthdate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        guard let thisYear = calendar.dateComponents([.year], from: now).year else { return false }
        
        // Get birthday for this year
        var birthdayComponents = calendar.dateComponents([.month, .day], from: birthdate)
        birthdayComponents.year = thisYear
        
        guard let birthdayThisYear = calendar.date(from: birthdayComponents) else { return false }
        
        // If birthday already passed this year, check next year
        let birthdayToCheck = birthdayThisYear < now ?
            calendar.date(byAdding: .year, value: 1, to: birthdayThisYear) ?? birthdayThisYear :
            birthdayThisYear
        
        // Check if within next 30 days
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: now) ?? now
        return birthdayToCheck <= thirtyDaysFromNow && birthdayToCheck >= now
    }
    
    /// Get days until birthday
    func daysUntilBirthday(_ birthdate: Date) -> Int? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let thisYear = calendar.dateComponents([.year], from: now).year else { return nil }
        
        // Get birthday for this year
        var birthdayComponents = calendar.dateComponents([.month, .day], from: birthdate)
        birthdayComponents.year = thisYear
        
        guard let birthdayThisYear = calendar.date(from: birthdayComponents) else { return nil }
        
        // If birthday already passed this year, check next year
        let birthdayToCheck = birthdayThisYear < now ?
            calendar.date(byAdding: .year, value: 1, to: birthdayThisYear) ?? birthdayThisYear :
            birthdayThisYear
        
        let days = calendar.dateComponents([.day], from: now, to: birthdayToCheck).day
        return days
    }
    
    /// Format time ago string with smart formatting
    func smartTimeAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        switch timeInterval {
        case 0..<60:
            return "Just now"
        case 60..<3600:
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        case 3600..<86400:
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        case 86400..<604800:
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        default:
            return formatForDisplay(date)
        }
    }
    
    /// Check if date is recent (within last 24 hours)
    func isRecent(_ date: Date) -> Bool {
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return date >= dayAgo
    }
    
    /// Check if date is stale (older than 1 week)
    func isStale(_ date: Date) -> Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return date < weekAgo
    }
    
    /// Get localized month name
    func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    /// Get localized day of week
    func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}