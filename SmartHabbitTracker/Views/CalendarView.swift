import SwiftUI
import CoreData

struct CalendarView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @FetchRequest(
    entity: CompletionEntity.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \CompletionEntity.date, ascending: true)]
  ) private var completions: FetchedResults<CompletionEntity>

  @FetchRequest(
    entity: HabitEntity.entity(),
    sortDescriptors: []
  ) private var habits: FetchedResults<HabitEntity>

  @State private var displayMonth = Date()
  private let cal = Calendar.current

  var body: some View {
    VStack {
      monthHeader
      weekdayHeader
      daysGrid
    }
    .padding()
    .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: – Month selector
  private var monthHeader: some View {
    HStack {
      Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
      Spacer()
      Text(monthYear(from: displayMonth))
        .font(.title2).bold()
      Spacer()
      Button { changeMonth(by: +1) } label: { Image(systemName: "chevron.right") }
    }
    .padding(.horizontal)
  }

  // MARK: – Weekday labels
  private var weekdayHeader: some View {
    let cols = Array(repeating: GridItem(.flexible()), count: 7)
    return LazyVGrid(columns: cols) {
      ForEach(cal.shortWeekdaySymbols, id: \.self) { wd in
        Text(wd).font(.caption).frame(maxWidth: .infinity)
      }
    }
  }

  // MARK: – The calendar grid
  private var daysGrid: some View {
    let cols = Array(repeating: GridItem(.flexible()), count: 7)
    let days = makeDays()
    return LazyVGrid(columns: cols, spacing: 8) {
      ForEach(days, id: \.self) { date in
        DayCell(
          date: date,
          completions: completionsFor(date: date),
          allHabits: Array(habits)
        )
      }
    }
  }

  // MARK: – Helpers

  private func changeMonth(by n: Int) {
    guard let m = cal.date(byAdding: .month, value: n, to: displayMonth)
    else { return }
    displayMonth = m
  }

  private func monthYear(from d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "LLLL yyyy"
    return f.string(from: d)
  }

  private func makeDays() -> [Date?] {
    guard
      let monthRange = cal.range(of: .day, in: .month, for: displayMonth),
      let firstOfMonth = cal.date(from:
        cal.dateComponents([.year, .month], from: displayMonth))
    else { return [] }

    var days: [Date?] = []
    let firstWeekday = cal.component(.weekday, from: firstOfMonth)
    days.append(contentsOf: Array(repeating: nil, count: firstWeekday - 1))

    for day in monthRange {
      if let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
        days.append(date)
      }
    }

    while days.count % 7 != 0 { days.append(nil) }
    return days
  }

  private func completionsFor(date: Date?) -> [CompletionEntity] {
    guard let d = date else { return [] }
    let start = cal.startOfDay(for: d)
    let end   = cal.date(byAdding: .day, value: 1, to: start)!
    return completions.filter { $0.date >= start && $0.date < end }
  }
}


/// A single day cell showing up to three dots (one per slot) if *all* habits in that slot are done.
struct DayCell: View {
  var date: Date?
  var completions: [CompletionEntity]
  var allHabits: [HabitEntity]

  private let cal = Calendar.current

  var body: some View {
    VStack(spacing: 2) {
      if let d = date {
        // Day number
        Text("\(cal.component(.day, from: d))")
          .font(.subheadline)
          .frame(maxWidth: .infinity)

        // Dots for each time-of-day where 100% done
        HStack(spacing: 4) {
          ForEach(TimeOfDay.allCases, id: \.self) { slot in
            if isSlotComplete(slot, on: d) {
              Circle()
                .frame(width: 6, height: 6)
                .foregroundColor(color(for: slot))
            }
          }

          // Bonus flame when *all three* slots done
          if TimeOfDay.allCases.allSatisfy({ isSlotComplete($0, on: d) }) {
            Image(systemName: "flame.fill")
              .resizable()
              .frame(width: 10, height: 10)
              .foregroundColor(.orange)
          }
        }
      }
    }
    .frame(minHeight: 44)
  }

  /// Checks if for a given slot you completed *every* habit in that slot on this day.
  private func isSlotComplete(_ slot: TimeOfDay, on day: Date) -> Bool {
    let start = cal.startOfDay(for: day)
    let end   = cal.date(byAdding: .day, value: 1, to: start)!

    // total number of habits assigned to this slot
    let total = allHabits.filter { $0.timeOfDay == slot.rawValue }.count
    guard total > 0 else { return false }

    // number of completions you made in this slot on that day
    let done = completions
      .filter { $0.timeOfDay == slot.rawValue }
      .filter { $0.date >= start && $0.date < end }
      .count

    return done >= total
  }

  private func color(for slot: TimeOfDay) -> Color {
    switch slot {
      case .Morning:   return .yellow
      case .Afternoon: return .orange
      case .Evening:   return .purple
    }
  }
}
