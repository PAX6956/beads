import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var exportURL: URL?
    @State private var isShowingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var didDelete = false
    @AppStorage(QuoteLanguagePreference.storageKey) private var quoteLanguagePreference: QuoteLanguagePreference = .system

    @AppStorage(NotificationScheduler.quoteEnabledKey) private var quoteNotificationsEnabled = true
    @AppStorage(NotificationScheduler.reminderEnabledKey) private var reminderNotificationsEnabled = true
    @AppStorage(NotificationScheduler.quoteMinutesKey) private var quoteMinutesSinceMidnight = NotificationScheduler.defaultQuoteHour * 60
    @AppStorage(NotificationScheduler.reminderMinutesKey) private var reminderMinutesSinceMidnight = NotificationScheduler.defaultReminderHour * 60
    @State private var systemNotificationsDenied = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Quote Language", selection: $quoteLanguagePreference) {
                        ForEach(QuoteLanguagePreference.allCases) { option in
                            // `Text(String)` never consults the String Catalog —
                            // only literal/LocalizedStringKey initializers do —
                            // so a dynamic `displayName` needs this explicit
                            // wrap or it silently stays English forever.
                            Text(LocalizedStringKey(option.displayName)).tag(option)
                        }
                    }
                } footer: {
                    Text("Controls the language of daily quotes and micro-actions, independent of your device's system language.")
                }

                Section {
                    if systemNotificationsDenied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Notifications are off in iOS Settings — tap to enable", systemImage: "bell.slash")
                        }
                    }

                    Toggle("Daily quote", isOn: $quoteNotificationsEnabled)
                    if quoteNotificationsEnabled {
                        DatePicker("Quote time", selection: quoteTimeBinding, displayedComponents: .hourAndMinute)
                    }

                    Toggle("Evening reminder", isOn: $reminderNotificationsEnabled)
                    if reminderNotificationsEnabled {
                        DatePicker("Reminder time", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("The evening reminder never fires on a day you've already practiced.")
                }
                .onChange(of: quoteNotificationsEnabled) { _ in NotificationScheduler.rescheduleUpcoming() }
                .onChange(of: reminderNotificationsEnabled) { _ in NotificationScheduler.rescheduleUpcoming() }
                .onChange(of: quoteMinutesSinceMidnight) { _ in NotificationScheduler.rescheduleUpcoming() }
                .onChange(of: reminderMinutesSinceMidnight) { _ in NotificationScheduler.rescheduleUpcoming() }

                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share Exported File", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            exportURL = store.exportDataFile()
                            Haptics.lightTap()
                        } label: {
                            Label("Export my data", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button(role: .destructive) {
                        Haptics.warning()
                        isShowingDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            Label("Deleting…", systemImage: "trash")
                        } else {
                            Label("Delete all my data", systemImage: "trash")
                        }
                    }
                    .disabled(isDeleting)
                } footer: {
                    Text("Beads stores your practice and journal entries only in your own iCloud account — nothing is shared with anyone unless you choose to share a Ripple Card.")
                }

                #if DEBUG
                Section {
                    NavigationLink("Bead Tier Preview (Debug)") {
                        BeadTierDebugView()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all your data? This can't be undone.",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    isDeleting = true
                    Task {
                        await store.deleteAllData()
                        exportURL = nil
                        isDeleting = false
                        didDelete = true
                        Haptics.success()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("All your data has been deleted.", isPresented: $didDelete) {
                Button("OK", role: .cancel) {}
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                systemNotificationsDenied = settings.authorizationStatus == .denied
            }
        }
    }

    // DatePicker needs a Date binding, but @AppStorage doesn't support Date
    // natively — stored as minutes-since-midnight Int instead, converted
    // here in both directions.
    private var quoteTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutesSinceMidnight: quoteMinutesSinceMidnight) },
            set: { quoteMinutesSinceMidnight = Self.minutesSinceMidnight(from: $0) }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutesSinceMidnight: reminderMinutesSinceMidnight) },
            set: { reminderMinutesSinceMidnight = Self.minutesSinceMidnight(from: $0) }
        )
    }

    private static func date(fromMinutesSinceMidnight minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutesSinceMidnight(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PracticeStore())
}
