import SwiftUI

private struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

struct HistoryCalendarView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var monthAnchor = Date()
    @State private var makeUpDate: Date?

    private var calendar: Calendar { .current }

    private var completedDays: Set<DateComponents> {
        Set(store.practiceEntries.map { calendar.dateComponents([.year, .month, .day], from: $0.date) })
    }

    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysCount = calendar.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for dayOffset in 0..<daysCount {
            days.append(calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start))
        }
        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
            Text("Ringed days are within the last 3 days — tap to make up a missed practice.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .sheet(item: Binding(
            get: { makeUpDate.map(IdentifiableDate.init) },
            set: { makeUpDate = $0?.date }
        )) { wrapped in
            MakeUpPracticeSheet(date: wrapped.date)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthAnchor, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                .disabled(calendar.isDate(monthAnchor, equalTo: Date(), toGranularity: .month))
        }
    }

    private func shiftMonth(by value: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: monthAnchor) else { return }
        monthAnchor = newDate
    }

    private func dayCell(_ date: Date) -> some View {
        let isCompleted = completedDays.contains(calendar.dateComponents([.year, .month, .day], from: date))
        let isToday = calendar.isDateInToday(date)
        let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day ?? -1
        let isMakeUpEligible = !isCompleted && daysAgo > 0 && daysAgo <= 3

        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.footnote)
                .frame(width: 32, height: 32)
                .background(isCompleted ? Color.accentColor : Color.gray.opacity(0.15), in: Circle())
                .foregroundStyle(isCompleted ? .white : .primary)
                .overlay(
                    Circle().strokeBorder(isMakeUpEligible ? Color.accentColor : .clear, lineWidth: 1.5)
                )
            Circle()
                .fill(isToday ? Color.accentColor : .clear)
                .frame(width: 4, height: 4)
        }
        .onTapGesture {
            if isMakeUpEligible {
                Haptics.lightTap()
                makeUpDate = date
            }
        }
    }
}

#Preview {
    HistoryCalendarView()
        .environmentObject(PracticeStore())
}
