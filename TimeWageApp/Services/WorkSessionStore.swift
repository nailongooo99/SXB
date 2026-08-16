import CoreData
import Foundation

final class WorkSessionStore: ObservableObject {
    @Published private(set) var sessions: [WorkSession] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) { self.context = context; fetch() }

    func fetch() {
        let request = WorkSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkSession.startDate, ascending: false)]
        sessions = (try? context.fetch(request)) ?? []
    }

    @discardableResult
    func create(start: Date, end: Date? = nil, breakDuration: Double) -> WorkSession {
        let item = WorkSession(context: context)
        item.id = UUID(); item.startDate = start; item.endDate = end; item.breakDuration = breakDuration
        save(); return item
    }

    func delete(_ item: WorkSession) { context.delete(item); save() }
    func save() { try? context.save(); fetch() }
    func duration(of item: WorkSession) -> TimeInterval { max(0, (item.endDate ?? Date()).timeIntervalSince(item.startDate ?? Date()) - item.breakDuration) }
}
