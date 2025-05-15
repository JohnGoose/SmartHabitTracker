import SwiftUI
import CoreData

struct HomeView: View {
  // MARK: – Core Data
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(
    sortDescriptors: [
      NSSortDescriptor(keyPath: \HabitEntity.timeOfDay, ascending: true),
      NSSortDescriptor(keyPath: \HabitEntity.order, ascending: true)
    ],
    animation: .spring()
  ) private var habits: FetchedResults<HabitEntity>

  // MARK: – UI State
  @State private var showingAddHabit = false
  @State private var showingCalendar = false
  @State private var editingHabit: HabitEntity? = nil

  // MARK: – Background
  private let background = LinearGradient(
    gradient: Gradient(colors: [Color.purple.opacity(0.8),
                                Color.blue.opacity(0.8)]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
    
    // MARK: – Daily-reset state
    @AppStorage("lastDailyReset")
    private var lastDailyReset: Date = .distantPast

    var body: some View {
      NavigationView {
        ZStack {
          background
            .ignoresSafeArea()

          VStack(spacing: 0) {
            ProgressSummaryView()
              .padding(.bottom, 8)

            List {
              ForEach(TimeOfDay.allCases, id: \.self) { time in
                Section(header:
                  header(for: time.rawValue)
                    .listRowBackground(Color.clear)
                ) {
                  ForEach(habitsFor(time: time.rawValue)) { habit in
                    HabitRow(habit: habit)
                      .listRowBackground(Color.clear)
                      .swipeActions(edge: .trailing) {
                        Button("Edit") { editingHabit = habit }
                          .tint(.blue)
                      }
                  }
                  .onDelete { offsets in
                    deleteHabits(at: offsets, in: time.rawValue)
                  }
                  .onMove { from, to in
                    moveHabits(from: from, to: to, in: time.rawValue)
                  }
                }
                .listRowBackground(Color.clear)
              }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)



          }
        }
        .navigationTitle("Your Habits")
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button { showingCalendar.toggle() } label: {
              Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.white)
            }
          }

          ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
              .font(.title2)
              .foregroundColor(.white)
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button { showingAddHabit.toggle() } label: {
              Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.white)
            }
          }
        }
      }
      // reset at midnight (or whenever view appears on a new day)
      .onAppear(perform: resetCompletionsIfNeeded)
      // sheets
      .sheet(item: $editingHabit) { habit in
        EditHabitView(habit: habit)
          .environment(\.managedObjectContext, viewContext)
      }
      .sheet(isPresented: $showingCalendar) {
        CalendarView()
          .environment(\.managedObjectContext, viewContext)
          // make the sheet only medium height (≈ half screen)
          .presentationDetents([.medium])
          // show the little grab-bar so users know they can pull it up/down
          .presentationDragIndicator(.visible)
      }


      .sheet(isPresented: $showingAddHabit) {
        NewHabitView()
          .environment(\.managedObjectContext, viewContext)
      }
      .accentColor(.white)
    }


  // MARK: – Helpers

  private func header(for title: String) -> some View {
    Text(title)
      .font(.title3).bold()
      .foregroundColor(.white)
      .padding(.top, 8)
      .listRowBackground(Color.clear)
  }
    
    // MARK: – Daily reset logic
    private func resetCompletionsIfNeeded() {
      let todayStart    = Calendar.current.startOfDay(for: .now)
      let lastResetDay  = Calendar.current.startOfDay(for: lastDailyReset)
      guard lastResetDay < todayStart else { return }
      // It’s a new day—clear all isCompleted flags
      for habit in habits {
        habit.isCompleted = false
      }
      do {
        try viewContext.save()
        // remember we reset today
        lastDailyReset = .now
      } catch {
        print("Failed to reset daily completions:", error)
      }
    }

  private func habitsFor(time: String) -> [HabitEntity] {
    habits.filter { $0.timeOfDay == time }
  }

  private func deleteHabits(at offsets: IndexSet, in time: String) {
    let sectionHabits = habitsFor(time: time)
    for i in offsets {
      viewContext.delete(sectionHabits[i])
    }
    try? viewContext.save()
  }

  private func moveHabits(from source: IndexSet, to dest: Int, in time: String) {
    var sectionHabits = habitsFor(time: time)
    sectionHabits.move(fromOffsets: source, toOffset: dest)
    // write back new order
    for idx in sectionHabits.indices {
      sectionHabits[idx].order = Int16(idx)
    }
    try? viewContext.save()
  }
}

// MARK: – Preview
struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
      .environment(\.managedObjectContext,
                   PersistenceController.shared.container.viewContext)
  }
}
