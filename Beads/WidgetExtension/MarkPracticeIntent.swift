import AppIntents
import WidgetKit

/// Runs entirely inside the widget process against the shared App Group
/// storage — no CloudKit push from here (that would need its own iCloud
/// entitlement + capability round-trip on this target). The main app
/// reconciles this entry to CloudKit the next time it's opened.
struct MarkPracticeIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Practice"
    static var description = IntentDescription("Marks today's practice as complete.")

    func perform() async throws -> some IntentResult {
        SharedStorage.markTodayComplete()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.beadsWidget)
        return .result()
    }
}
