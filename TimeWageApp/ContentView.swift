import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var settings = SalarySettings()
    @StateObject private var clock = ClockViewModel()
    @StateObject private var store: WorkSessionStore

    init() {
        let context = PersistenceController.shared.container.viewContext
        _store = StateObject(wrappedValue: WorkSessionStore(context: context))
    }

    var body: some View {
        TabView {
            DashboardView(settings: settings, clock: clock, store: store).tabItem { Label("首页", systemImage: "chart.line.uptrend.xyaxis") }
            TimeClockView(settings: settings, clock: clock, store: store).tabItem { Label("打卡", systemImage: "clock") }
            StatisticsView(settings: settings, store: store).tabItem { Label("统计", systemImage: "chart.bar.xaxis") }
            SettingsView(settings: settings).tabItem { Label("设置", systemImage: "gearshape") }
        }.tint(.green)
    }
}

struct DashboardView: View {
    @ObservedObject var settings: SalarySettings
    @ObservedObject var clock: ClockViewModel
    @ObservedObject var store: WorkSessionStore
    private var todaySeconds: TimeInterval { store.sessions.filter { Calendar.current.isDateInToday($0.startDate ?? .distantPast) }.reduce(0) { $0 + store.duration(of: $1) } + clock.workedSeconds }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack { Text("今日已赚").font(.headline); Spacer(); Button { settings.isAmountHidden.toggle() } label: { Image(systemName: settings.isAmountHidden ? "eye.slash" : "eye") }.accessibilityLabel("隐藏或显示金额") }
                    Text(settings.isAmountHidden ? "****" : String(format: "¥%.2f", todaySeconds * settings.perSecond)).font(.system(size: 48, weight: .bold, design: .rounded)).animation(.easeOut(duration: 0.25), value: todaySeconds)
                    Text(clock.isWorking ? "正在工作" : "未打卡").foregroundStyle(clock.isWorking ? .green : .secondary)
                    HStack(spacing: 12) { RateCard(title: "每秒", value: settings.perSecond, hidden: settings.isAmountHidden); RateCard(title: "每分钟", value: settings.perMinute, hidden: settings.isAmountHidden); RateCard(title: "每小时", value: settings.perHour, hidden: settings.isAmountHidden) }
                    Label("今日工时：\(formatDuration(todaySeconds))", systemImage: "hourglass")
                }.padding()
            }.navigationTitle("时薪宝")
        }
    }
}

private struct RateCard: View { let title: String; let value: Double; let hidden: Bool; var body: some View { VStack { Text(title).font(.caption).foregroundStyle(.secondary); Text(hidden ? "****" : String(format: "¥%.2f", value)).font(.headline) }.frame(maxWidth: .infinity).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)) } }

struct TimeClockView: View {
    @ObservedObject var settings: SalarySettings; @ObservedObject var clock: ClockViewModel; @ObservedObject var store: WorkSessionStore
    @State private var editing: WorkSession?
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(clock.isWorking ? "工作中" : "准备开始").font(.title2.bold())
                Text(formatDuration(clock.workedSeconds)).font(.system(size: 42, weight: .bold, design: .rounded)).monospacedDigit()
                Button(clock.isWorking ? "下班打卡" : "上班打卡") { toggleClock() }.buttonStyle(.borderedProminent).controlSize(.large).tint(clock.isWorking ? .orange : .green)
                List {
                    ForEach(store.sessions, id: \.objectID) { item in
                        Button { editing = item } label: { SessionRow(item: item, store: store, hidden: settings.isAmountHidden, rate: settings.perSecond) }.foregroundStyle(.primary)
                    }.onDelete { offsets in offsets.map { store.sessions[$0] }.forEach(store.delete) }
                }.listStyle(.insetGrouped)
            }.padding(.top).navigationTitle("打卡").sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) { if let item = editing { EditSessionView(item: item, store: store) } }
        }
    }
    private func toggleClock() { if let start = clock.activeStart { _ = store.create(start: start, end: clock.now, breakDuration: settings.breakHours * 3600); clock.activeStart = nil } else { clock.activeStart = clock.now } }
}

private struct SessionRow: View { let item: WorkSession; let store: WorkSessionStore; let hidden: Bool; let rate: Double; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(item.startDate ?? Date(), format: .dateTime.year().month().day()); HStack { Text(item.startDate ?? Date(), format: .dateTime.hour().minute()); Text("-"); Text(item.endDate ?? Date(), format: .dateTime.hour().minute()) }.font(.caption).foregroundStyle(.secondary); HStack { Text(formatDuration(store.duration(of: item))); Spacer(); Text(hidden ? "****" : String(format: "¥%.2f", store.duration(of: item) * rate)).bold() } } } }

private struct EditSessionView: View { @Environment(\.dismiss) private var dismiss; @ObservedObject var item: WorkSession; let store: WorkSessionStore; var body: some View { NavigationStack { Form { DatePicker("开始", selection: Binding(get: { item.startDate ?? Date() }, set: { item.startDate = $0 })); DatePicker("结束", selection: Binding(get: { item.endDate ?? Date() }, set: { item.endDate = $0 })); Stepper("休息：\(Int(item.breakDuration / 60)) 分钟", value: $item.breakDuration, in: 0...7200, step: 60) }.navigationTitle("编辑记录").toolbar { ToolbarItem(placement: .confirmationAction) { Button("保存") { store.save(); dismiss() } } } } } }

struct StatisticsView: View { @ObservedObject var settings: SalarySettings; @ObservedObject var store: WorkSessionStore; var body: some View { NavigationStack { List { Summary(title: "今日", items: summary(for: Date())); Summary(title: "本周", items: summary(for: Date(), component: .weekOfYear)); Summary(title: "本月", items: summary(for: Date(), component: .month)); Summary(title: "全部累计", items: allSummary) }.navigationTitle("统计") } }
    private var allSummary: [String] { ["收入：\(income(store.sessions))", "工时：\(formatDuration(store.sessions.reduce(0) { $0 + store.duration(of: $1) }))"] }
    private func summary(for date: Date, component: Calendar.Component? = nil) -> [String] { let items = store.sessions.filter { item in guard let start = item.startDate else { return false }; if component == .weekOfYear { return Calendar.current.component(.weekOfYear, from: start) == Calendar.current.component(.weekOfYear, from: date) }; if component == .month { return Calendar.current.isDate(start, equalTo: date, toGranularity: .month) }; return Calendar.current.isDateInToday(start) }; return ["收入：\(income(items))", "工时：\(formatDuration(items.reduce(0) { $0 + store.duration(of: $1) }))"] }
    private func income(_ items: [WorkSession]) -> String { let value = items.reduce(0) { $0 + store.duration(of: $1) * settings.perSecond }; return String(format: "¥%.2f", value) }
}
private struct Summary: View { let title: String; let items: [String]; var body: some View { Section(title) { ForEach(items, id: \.self) { Text($0) } } } }

struct SettingsView: View { @ObservedObject var settings: SalarySettings; var body: some View { NavigationStack { Form { Section("薪资") { Picker("模式", selection: $settings.mode) { ForEach(SalaryMode.allCases) { Text($0.rawValue).tag($0) } }; TextField("金额", value: $settings.amount, format: .number).keyboardType(.decimalPad) }; Section("工作制度") { TextField("每日工作小时", value: $settings.dailyHours, format: .number).keyboardType(.decimalPad); Picker("每月工作天数", selection: $settings.monthlyDays) { Text("双休 · 21.75").tag(21.75); Text("单休 · 26").tag(26.0); Text("大小周 · 24").tag(24.0); Text("自定义").tag(settings.monthlyDays) }; TextField("午休/休息小时", value: $settings.breakHours, format: .number).keyboardType(.decimalPad) }; Section("隐私") { Toggle("默认隐藏金额", isOn: $settings.isAmountHidden); Text("所有薪资和工时数据仅保存在本机。").font(.footnote).foregroundStyle(.secondary) } }.navigationTitle("设置") } } }

private func formatDuration(_ seconds: TimeInterval) -> String { let total = Int(seconds); return "\(total / 3600)小时\((total % 3600) / 60)分" }
