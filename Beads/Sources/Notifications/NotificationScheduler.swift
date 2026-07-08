import Foundation
import UserNotifications

/// Local-only notifications (no APNs, no server) — a rolling window of the next
/// 14 days' quotes is scheduled every time the app comes to the foreground, so
/// reminders keep firing even if the user doesn't reopen the app daily. Content
/// per day is deterministic (see ContentLibrary.todayItem), so there's nothing
/// to fetch at schedule time.
enum NotificationScheduler {
    static let dailyQuoteHour = 8
    static let reminderHour = 20
    private static let daysAhead = 14
    private static let center = UNUserNotificationCenter.current()

    static func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Call whenever the app becomes active: refreshes the rolling window of
    /// scheduled notifications so it always covers "today" through +14 days.
    static func rescheduleUpcoming(calendar: Calendar = .current, today: Date = Date()) {
        let library = ContentLibrary.loadSeed()
        guard !library.isEmpty else { return }

        center.removePendingNotificationRequests(withIdentifiers: (0..<daysAhead).flatMap { offset -> [String] in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return [] }
            return [quoteIdentifier(for: date), reminderIdentifier(for: date)]
        })

        for offset in 0..<daysAhead {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today),
                  let item = ContentLibrary.todayItem(from: library, calendar: calendar, date: date) else { continue }
            scheduleQuoteNotification(for: date, item: item, calendar: calendar)
            scheduleReminderNotification(for: date, calendar: calendar)
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
        content.title = "Today's practice"
        content.body = item.localizedQuote
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = dailyQuoteHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: quoteIdentifier(for: date), content: content, trigger: trigger)
        center.add(request)
    }

    private static func scheduleReminderNotification(for date: Date, calendar: Calendar) {
        let content = UNMutableNotificationContent()
        content.title = "Beads"
        content.body = "Your beads are still waiting for today."
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = reminderHour
        components.minute = 0
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
