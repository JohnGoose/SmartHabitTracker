import SwiftUI

@main
struct SmartHabitTrackerApp: App {
    // Use the default Core Data stack from the template
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
