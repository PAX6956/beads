import AppIntents
import WidgetKit

/// The main-app counterpart to the widget's MarkPracticeIntent — Siri and the
/// Shortcuts app need an intent declared where AppShortcutsProvider can find
/// it, which is the main app target, not the widget extension. Same shared
/// storage underneath, so "Hey Siri, practice with Beads" and tapping the
/// widget both just write to the one place PracticeStore also reads from.
struct MarkPracticeAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Practice"
    static var description = IntentDescription("Marks today's practice as complete.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let wasAlreadyDone = SharedStorage.markTodayComplete() == nil
        NotificationScheduler.cancelReminder()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.beadsWidget)

        if wasAlreadyDone {
            return .result(dialog: "You've already practiced today.")
        }
        return .result(dialog: "Nice — today's practice is marked complete.")
    }
}

struct BeadsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkPracticeAppIntent(),
            phrases: [
                "Practice with \(.applicationName)",
                "Mark today's practice in \(.applicationName)"
            ],
            shortTitle: "Practice",
            systemImageName: "checkmark.circle"
        )
    }
}
