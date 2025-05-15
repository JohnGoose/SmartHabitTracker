import SwiftUI
import CoreData

struct HabitRow: View {
  @ObservedObject var habit: HabitEntity

  var body: some View {
    HStack(spacing: 16) {
      Button {
        withAnimation(.spring()) {
          toggleCompletion()
        }
      } label: {
        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 24))
          .foregroundColor(habit.isCompleted ? .green : .gray)
      }

      Text(habit.name)
        .font(.headline)
        .foregroundColor(.white)

      Spacer()

      if habit.streak > 0 {
        HStack(spacing: 4) {
          Image(systemName: "flame.fill")
          Text("\(habit.streak)")
        }
        .font(.subheadline).bold()
        .foregroundColor(.orange)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal)
    .background(.ultraThinMaterial)     // nice blur
    .cornerRadius(16)                    // rounded cards
    .shadow(color: Color.black.opacity(0.2),
            radius: 8, x: 0, y: 4)      // subtle depth
  }

    private func toggleCompletion() {
        guard let ctx = habit.managedObjectContext else { return }
        
        let now = Date()
        habit.isCompleted.toggle()
        

        let todayStart = Calendar.current.startOfDay(for: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        let req: NSFetchRequest<CompletionEntity> = CompletionEntity.fetchRequest()
        req.predicate = NSPredicate(
            format: "timeOfDay == %@ AND date >= %@ AND date < %@",
            habit.timeOfDay,
            todayStart as NSDate,
            tomorrow as NSDate
        )
        
        if habit.isCompleted {
            // add one
            let c = CompletionEntity(context: ctx)
            c.id          = UUID()
            c.date        = now
            c.timeOfDay   = habit.timeOfDay
        } else {
            // remove any existing
            if let hits = try? ctx.fetch(req) {
                hits.forEach(ctx.delete)
            }
        }
        
        let daysBack = (0...6).map { Calendar.current.date(byAdding: .day, value: -$0, to: todayStart)! }
        var newStreak = 0
        for day in daysBack {
            let start = Calendar.current.startOfDay(for: day)
            let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let count = try! ctx.count(
                for: {
                    let r = CompletionEntity.fetchRequest()
                    r.predicate = NSPredicate(
                        format: "timeOfDay == %@ AND date >= %@ AND date < %@",
                        habit.timeOfDay, start as NSDate, end as NSDate
                    )
                    return r
                }()
            )
            if count > 0 {
                newStreak += 1
            } else {
                break
            }
        }
        
        let todayCompletions = try! ctx.fetch({
            let r = CompletionEntity.fetchRequest()
            r.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                todayStart as NSDate, tomorrow as NSDate
            )
            return r
        }())
        let uniqueSlots = Set(todayCompletions.map(\.timeOfDay))
        if uniqueSlots.count == 3 {
            newStreak += 1
        }
    }

}
