import CoreData

extension WorkSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkSession> {
        NSFetchRequest<WorkSession>(entityName: "WorkSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var breakDuration: Double
    @NSManaged public var note: String?
}
