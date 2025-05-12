import SwiftUI
import CoreData

struct EditHabitView: View {
  @ObservedObject var habit: HabitEntity
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.presentationMode) private var presentationMode

  @State private var name: String
  @State private var selected: TimeOfDay

  init(habit: HabitEntity) {
    self.habit = habit
    // seed state with existing values
    _name     = State(initialValue: habit.name)
    _selected = State(initialValue: TimeOfDay(rawValue: habit.timeOfDay) ?? .Morning)
  }

  var body: some View {
    NavigationView {
      Form {
        Section("Habit Name") {
          TextField("Name", text: $name)
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
      .navigationTitle("Edit Habit")
      .navigationBarItems(
        leading: Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        },
        trailing: Button("Save") {
          saveChanges()
          presentationMode.wrappedValue.dismiss()
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
      )
    }
  }

  private func saveChanges() {
    habit.name       = name
    habit.timeOfDay  = selected.rawValue
    // optionally adjust order if timeOfDay changed
    try? viewContext.save()
  }
}
