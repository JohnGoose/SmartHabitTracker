import Foundation
import CoreData

@objc(CompletionEntity)
public class CompletionEntity: NSManagedObject {}

extension CompletionEntity {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<CompletionEntity> {
    NSFetchRequest<CompletionEntity>(entityName: "Completion")
  }

  @NSManaged public var id: UUID
  @NSManaged public var date: Date
  @NSManaged public var timeOfDay: String
}

extension CompletionEntity: Identifiable {}
