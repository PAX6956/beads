import Foundation
import UserNotifications

/// Local-only notifications (no APNs, no server) — a rolling window of the next
/// 14 days' quotes is scheduled every time the app comes to the foreground, so
/// reminders keep firing even if the user doesn't reopen the app daily. Content
/// per day is deterministic (see ContentLibrary.todayItem), so there's nothing
/// to fetch at schedule time.
///
/// Enabled/disabled state and times are user-configurable (Settings), stored
/// in plain UserDefaults rather than @AppStorage — this isn't a View, so it
/// just needs to read the current value each time it runs, not track changes.
enum NotificationScheduler {
    static let quoteEnabledKey = "notificationsQuoteEnabled"
    static let reminderEnabledKey = "notificationsReminderEnabled"
    static let quoteMinutesKey = "notificationsQuoteMinutes"
    static let reminderMinutesKey = "notificationsReminderMinutes"

    static let defaultQuoteHour = 8
    static let defaultReminderHour = 20

    private static let daysAhead = 14
    private static let center = UNUserNotificationCenter.current()

    private static var isQuoteEnabled: Bool {
        UserDefaults.standard.object(forKey: quoteEnabledKey) as? Bool ?? true
    }

    private static var isReminderEnabled: Bool {
        UserDefaults.standard.object(forKey: reminderEnabledKey) as? Bool ?? true
    }

    private static var quoteMinutesSinceMidnight: Int {
        UserDefaults.standard.object(forKey: quoteMinutesKey) as? Int ?? defaultQuoteHour * 60
    }

    private static var reminderMinutesSinceMidnight: Int {
        UserDefaults.standard.object(forKey: reminderMinutesKey) as? Int ?? defaultReminderHour * 60
    }

    static func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Call whenever the app becomes active, or a notification setting
    /// changes: refreshes the rolling window of scheduled notifications so
    /// it always covers "today" through +14 days, respecting current
    /// enabled/disabled and time preferences.
    static func rescheduleUpcoming(calendar: Calendar = .current, today: Date = Date()) {
        let library = ContentLibrary.loadSeed()
        guard !library.isEmpty else { return }

        center.removePendingNotificationRequests(withIdentifiers: (0..<daysAhead).flatMap { offset -> [String] in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return [] }
            return [quoteIdentifier(for: date), reminderIdentifier(for: date)]
        })

        let quoteEnabled = isQuoteEnabled
        let reminderEnabled = isReminderEnabled
        guard quoteEnabled || reminderEnabled else { return }

        for offset in 0..<daysAhead {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  let item = ContentLibrary.todayItem(from: library, calendar: calendar, date: date) else { continue }
            if quoteEnabled {
                scheduleQuoteNotification(for: date, item: item, calendar: calendar)
            }
            if reminderEnabled {
                scheduleReminderNotification(for: date, calendar: calendar)
            }
        }
    }

    /// Call right after a practice is marked complete so the same day's evening
    /// nudge doesn't also fire.
    static func cancelReminder(for date: Date = Date()) {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: date)])
    }

    /// Call when the user deletes all their data — nothing left to remind them about.
    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    private static func scheduleQuoteNotification(for date: Date, item: ContentItem, calendar: Calendar) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Today's practice")
        content.body = item.localizedQuote
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let minutes = quoteMinutesSinceMidnight
        components.hour = minutes / 60
        components.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: quoteIdentifier(for: date), content: content, trigger: trigger)
        center.add(request)
    }

    private static func scheduleReminderNotification(for date: Date, calendar: Calendar) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Beads")
        content.body = String(localized: "Your beads are still waiting for today.")
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let minutes = reminderMinutesSinceMidnight
        components.hour = minutes / 60
        components.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier(for: date), content: content, trigger: trigger)
        center.add(request)
    }

    private static func quoteIdentifier(for date: Date) -> String {
        "daily-quote-\(dayKey(date))"
    }

    private static func reminderIdentifier(for date: Date) -> String {
        "reminder-\(dayKey(date))"
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
