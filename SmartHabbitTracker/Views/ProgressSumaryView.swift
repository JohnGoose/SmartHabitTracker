import SwiftUI
import CoreData

struct ProgressSummaryView: View {
  @Environment(\.managedObjectContext) private var viewContext

  // All habits
  @FetchRequest(
    entity: HabitEntity.entity(),
    sortDescriptors: []
  ) private var habits: FetchedResults<HabitEntity>

  // All completions
  @FetchRequest(
    entity: CompletionEntity.entity(),
    sortDescriptors: []
  ) private var completions: FetchedResults<CompletionEntity>

  private var todayStart: Date {
    Calendar.current.startOfDay(for: Date())
  }
  private var tomorrowStart: Date {
    Calendar.current.date(byAdding: .day,
      value: 1,
      to: todayStart)!
  }

  var body: some View {
    VStack(spacing: 12) {
        ForEach(TimeOfDay.allCases, id: \.self) { time in
            HStack {
                Text(time.rawValue)
                    .frame(width: 80, alignment: .leading)
                    .foregroundColor(.white)
                
                let slotHabits = habits.filter { $0.timeOfDay == time.rawValue }
                let completedCount = slotHabits.filter(\.isCompleted).count
                let progress = slotHabits.isEmpty
                ? 0
                : Double(completedCount) / Double(slotHabits.count)
                
                ProgressView(value: progress)
                    .frame(height: 8)
                    .accentColor(color(for: time))
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 36, alignment: .trailing)
            }
        }

    }
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(16)
    .padding(.horizontal)
  }

  private func color(for t: TimeOfDay) -> Color {
    switch t {
      case .Morning:   return .yellow
      case .Afternoon: return .orange
      case .Evening:   return .purple
    }
  }
}
