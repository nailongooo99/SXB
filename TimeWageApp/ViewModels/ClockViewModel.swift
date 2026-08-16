import Foundation

final class ClockViewModel: ObservableObject {
    @Published private(set) var now = Date()
    @Published var activeStart: Date?
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.now = Date() }
    }
    deinit { timer?.invalidate() }
    var isWorking: Bool { activeStart != nil }
    var workedSeconds: TimeInterval { guard let activeStart else { return 0 }; return max(0, now.timeIntervalSince(activeStart)) }
}
