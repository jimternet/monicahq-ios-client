import Foundation
import UserNotifications

/// Manages iOS local notifications for reminders
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            print("📱 Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            print("❌ Failed to request notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
        print("📱 Notification authorization status: \(authorizationStatus.rawValue)")
    }

    // MARK: - Schedule Notifications

    /// Schedule a notification for a reminder
    func scheduleNotification(for reminder: Reminder) async throws {
        if !isAuthorized {
            print("⚠️ Notifications not authorized, requesting...")
            let granted = await requestAuthorization()
            guard granted else {
                throw NotificationError.notAuthorized
            }
        }

        // Remove existing notification if any
        await cancelNotification(for: reminder)

        guard let nextDate = reminder.nextExpectedDate else {
            print("⚠️ No next expected date for reminder: \(reminder.title)")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = reminder.title

        if let contactName = reminder.contact?.displayName {
            content.body = "Reminder for \(contactName)"
        } else {
            content.body = "Don't forget!"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "REMINDER"
        content.userInfo = [
            "reminderId": reminder.id,
            "reminderTitle": reminder.title,
            "contactId": reminder.contact?.id ?? 0
        ]

        // Schedule for 9 AM on the reminder date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "reminder-\(reminder.id)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        print("🔔 Scheduled notification for '\(reminder.title)' at \(nextDate)")
    }

    /// Schedule notifications for multiple reminders
    func scheduleNotifications(for reminders: [Reminder]) async {
        for reminder in reminders {
            do {
                try await scheduleNotification(for: reminder)
            } catch {
                print("❌ Failed to schedule notification for '\(reminder.title)': \(error)")
            }
        }
    }

    /// Schedule notifications for upcoming reminders (next 30 days)
    func scheduleUpcomingNotifications(for reminders: [Reminder]) async {
        let now = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        let upcomingReminders = reminders.filter { reminder in
            guard let nextDate = reminder.nextExpectedDate else { return false }
            return nextDate >= now && nextDate <= thirtyDaysFromNow
        }

        print("📅 Scheduling notifications for \(upcomingReminders.count) upcoming reminders")
        await scheduleNotifications(for: upcomingReminders)
    }

    // MARK: - Cancel Notifications

    func cancelNotification(for reminder: Reminder) async {
        let identifier = "reminder-\(reminder.id)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🔕 Cancelled notification for '\(reminder.title)'")
    }

    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🔕 Cancelled all pending notifications")
    }

    // MARK: - Query Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    func getPendingNotificationCount() async -> Int {
        let pending = await getPendingNotifications()
        return pending.count
    }

    // MARK: - Badge Management

    func updateBadgeCount(to count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        updateBadgeCount(to: 0)
    }
}

// MARK: - Error Types

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permissions not granted. Please enable notifications in Settings."
        case .schedulingFailed:
            return "Failed to schedule notification."
        }
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_REMINDER",
            title: "View",
            options: .foreground
        )

        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_REMINDER",
            title: "Mark Complete",
            options: []
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [viewAction, completeAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([reminderCategory])
    }
}
