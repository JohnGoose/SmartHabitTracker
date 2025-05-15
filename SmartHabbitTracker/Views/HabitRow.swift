import SwiftUI
import CoreData
import UIKit

struct HabitRow: View {
  @ObservedObject var habit: HabitEntity

    var body: some View {
      HStack(spacing: 16) {
        Button {
          // prepare and fire a success haptic
          let generator = UINotificationFeedbackGenerator()
          generator.prepare()
          
          withAnimation(.spring()) {
            toggleCompletion()
          }

          generator.notificationOccurred(.success)
        } label: {
          Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 24))
            .foregroundColor(habit.isCompleted ? .green : .gray)
        }

        Text(habit.name)
          .font(.headline)
          .foregroundColor(.white)

        Spacer()
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
        // define the bounds of “today”
        let todayStart = Calendar.current.startOfDay(for: now)
        let tomorrow   = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        // flip the Bool on the habit
        habit.isCompleted.toggle()

        let req: NSFetchRequest<CompletionEntity> = CompletionEntity.fetchRequest()
        req.predicate = NSPredicate(
            format: "timeOfDay == %@ AND date >= %@ AND date < %@",
            habit.timeOfDay as CVarArg,
            todayStart as NSDate,
            tomorrow   as NSDate
        )

        if habit.isCompleted {
            // mark it done: insert a new record
            let c = CompletionEntity(context: ctx)
            c.id        = UUID()
            c.date      = now
            c.timeOfDay = habit.timeOfDay
        } else {
            // undo: delete any existing for this slot
            if let hits = try? ctx.fetch(req) {
                hits.forEach(ctx.delete)
            }
        }

        var newStreak = 0
        for offset in 0..<7 {
            let day     = Calendar.current.date(byAdding: .day, value: -offset, to: todayStart)!
            let start   = Calendar.current.startOfDay(for: day)
            let end     = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let count   = try! ctx.count(
                for: {
                    let r = CompletionEntity.fetchRequest()
                    r.predicate = NSPredicate(
                        format: "timeOfDay == %@ AND date >= %@ AND date < %@",
                        habit.timeOfDay as CVarArg,
                        start as NSDate,
                        end   as NSDate
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
                todayStart as NSDate,
                tomorrow   as NSDate
            )
            return r
        }())
        let uniqueSlots = Set(todayCompletions.compactMap(\.timeOfDay))
        if uniqueSlots.count == 3 {
            newStreak += 1
        }

        // 5️⃣ store the new streak and save
        habit.streak = Int16(newStreak)
        // (optionally) habit.lastCompletedDate = now

        do {
            try ctx.save()
        } catch {
            print("⚠️ Failed to save context after toggling completion:", error)
        }
    }


}
