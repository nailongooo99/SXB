import Foundation

enum SalaryMode: String, CaseIterable, Identifiable {
    case monthly = "月薪制"
    case hourly = "时薪制"
    var id: String { rawValue }
}

final class SalarySettings: ObservableObject {
    @Published var mode: SalaryMode { didSet { save() } }
    @Published var amount: Double { didSet { save() } }
    @Published var dailyHours: Double { didSet { save() } }
    @Published var monthlyDays: Double { didSet { save() } }
    @Published var breakHours: Double { didSet { save() } }
    @Published var isAmountHidden: Bool { didSet { save() } }

    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mode = SalaryMode(rawValue: defaults.string(forKey: "salary.mode") ?? "月薪制") ?? .monthly
        amount = defaults.object(forKey: "salary.amount") as? Double ?? 10000
        dailyHours = defaults.object(forKey: "work.dailyHours") as? Double ?? 8
        monthlyDays = defaults.object(forKey: "work.monthlyDays") as? Double ?? 21.75
        breakHours = defaults.object(forKey: "work.breakHours") as? Double ?? 1
        isAmountHidden = defaults.bool(forKey: "privacy.amountHidden")
    }

    var hourlyRate: Double { mode == .hourly ? amount : amount / max(monthlyDays * max(dailyHours, 0.01), 0.01) }
    var perSecond: Double { hourlyRate / 3600 }
    var perMinute: Double { perSecond * 60 }
    var perHour: Double { hourlyRate }

    private func save() {
        defaults.set(mode.rawValue, forKey: "salary.mode")
        defaults.set(amount, forKey: "salary.amount")
        defaults.set(dailyHours, forKey: "work.dailyHours")
        defaults.set(monthlyDays, forKey: "work.monthlyDays")
        defaults.set(breakHours, forKey: "work.breakHours")
        defaults.set(isAmountHidden, forKey: "privacy.amountHidden")
    }
}
