import SwiftUI
import CoreData

struct NewHabitView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.presentationMode) private var presentationMode

  @State private var name               = ""
  @State private var selected: TimeOfDay = .Morning

  // fetch *all* habits so we can compute a new order
  @FetchRequest(entity: HabitEntity.entity(), sortDescriptors: [])
  private var allHabits: FetchedResults<HabitEntity>

  var body: some View {
    NavigationView {
      Form {
        Section("Habit Name") {
          TextField("e.g. Drink Water", text: $name)
        }
        Section("Time of Day") {
          Picker("", selection: $selected) {
            ForEach(TimeOfDay.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
        }
      }
      .navigationTitle("New Habit")
      .navigationBarItems(
        leading: Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        },
        trailing: Button("Save") {
          addHabit()
          presentationMode.wrappedValue.dismiss()
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
      )
    }
  }

  private func addHabit() {
    let newHabit = HabitEntity(context: viewContext)
    newHabit.id                = UUID()
    newHabit.name              = name
    newHabit.timeOfDay         = selected.rawValue
    newHabit.isCompleted       = false
    newHabit.streak            = 0
    newHabit.lastCompletedDate = nil

    // compute next order in this section
    let sameSection = allHabits.filter { $0.timeOfDay == selected.rawValue }
    let maxOrder    = sameSection.map(\.order).max() ?? -1
    newHabit.order = maxOrder + 1

    try? viewContext.save()
  }
}
