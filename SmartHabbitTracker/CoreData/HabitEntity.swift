import Foundation
import CoreData

@objc(HabitEntity)
public class HabitEntity: NSManagedObject {}

extension HabitEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitEntity> {
        return NSFetchRequest<HabitEntity>(entityName: "Habit")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var timeOfDay: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var streak: Int16
    @NSManaged public var lastCompletedDate: Date?
    @NSManaged public var order: Int16

}

extension HabitEntity: Identifiable {}
