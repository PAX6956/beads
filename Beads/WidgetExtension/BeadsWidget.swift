import WidgetKit
import SwiftUI

struct BeadsWidgetEntry: TimelineEntry {
    let date: Date
    let quote: String
    let hasCompletedToday: Bool
    let streak: Int
}

struct BeadsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeadsWidgetEntry {
        BeadsWidgetEntry(date: Date(), quote: "Simplicity is the return to the root.", hasCompletedToday: false, streak: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeadsWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeadsWidgetEntry>) -> Void) {
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(6 * 3600)
        completion(Timeline(entries: [currentEntry()], policy: .after(nextMidnight)))
    }

    private func currentEntry() -> BeadsWidgetEntry {
        let library = ContentLibrary.loadSeed()
        let item = ContentLibrary.todayItem(from: library)
        let entries = SharedStorage.loadPracticeEntries()
        let hasCompleted = entries.contains { Calendar.current.isDateInToday($0.date) }
        return BeadsWidgetEntry(
            date: Date(),
            quote: item?.quote ?? "Take a quiet breath.",
            hasCompletedToday: hasCompleted,
            streak: BeadsProgress.currentStreak(entries: entries)
        )
    }
}

struct BeadsWidgetView: View {
    let entry: BeadsWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.quote)
                .font(.caption.weight(.medium))
                .lineLimit(4)
                .minimumScaleFactor(0.8)
            Spacer()
            HStack {
                Text("\(entry.streak)d streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.hasCompletedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button(intent: MarkPracticeIntent()) {
                        Text("Practice")
                            .font(.caption2.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct BeadsWidget: Widget {
    static let kind = "BeadsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: BeadsWidgetProvider()) { entry in
            BeadsWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Practice")
        .description("See today's quote and mark your practice without opening the app.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    BeadsWidget()
} timeline: {
    BeadsWidgetEntry(date: .now, quote: "Simplicity is the return to the root.", hasCompletedToday: false, streak: 12)
}
