import Foundation

/// Everything the widgets show, written by the app into the shared App Group.
/// Week counts and streaks are computed from the dates at render time, so they
/// stay right across midnight and Monday without the app running.
struct WidgetSnapshot: Codable {
    struct Workout: Codable {
        var date: Date
        var routine: RoutineID
        var minutes: Int
        var sets: Int
        var volume: Double
    }

    struct Record: Codable {
        var name: String
        var text: String
        var date: Date
    }

    struct Trend: Codable {
        var name: String
        var weights: [Double]
    }

    struct MoveUp: Codable {
        var id: String
        var name: String
        var weight: Double
        var sessions: Int
        var next: Double
    }

    var workouts: [Workout] = []
    var weeklyTarget: Int = 4
    var next: RoutineID = .upperA
    var nextFirst: String? = nil
    var nextCount: Int = 6
    var record: Record? = nil
    var trend: Trend? = nil
    var moveUp: MoveUp? = nil
    /// Calendar weekdays the plan trains on (1 = Sunday). nil means whenever.
    var plannedWeekdays: [Int]? = nil
    /// The next few workouts in plan order, starting with `next`.
    var upcoming: [RoutineID]? = nil
    var planName: String? = nil

    static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot {
        guard let raw = SharedStore.defaults.data(forKey: key) else {
            var s = WidgetSnapshot()
            s.next = SharedStore.nextRoutine()
            return s
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(WidgetSnapshot.self, from: raw)) ?? WidgetSnapshot()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let raw = try? encoder.encode(self) {
            SharedStore.defaults.set(raw, forKey: Self.key)
        }
    }

    // MARK: Week math

    static var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    var last: Workout? { workouts.first }

    func weekCount(_ now: Date) -> Int {
        guard let week = Self.calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return workouts.filter { week.contains($0.date) }.count
    }

    struct Day: Identifiable {
        let id: Int
        let letter: String
        let code: String?
        let isToday: Bool
        var planned: Bool = true
    }

    func days(_ now: Date) -> [Day] {
        let cal = Self.calendar
        guard let start = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i in
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { return nil }
            let w = workouts.first { cal.isDate($0.date, inSameDayAs: day) }
            let planned = plannedWeekdays?.contains(cal.component(.weekday, from: day)) ?? true
            return Day(id: i, letter: letters[i], code: w?.routine.code, isToday: cal.isDate(day, inSameDayAs: now), planned: planned)
        }
    }

    // MARK: Plan

    func trainedToday(_ now: Date) -> Bool {
        workouts.contains { Self.calendar.isDate($0.date, inSameDayAs: now) }
    }

    /// An off day in a plan with set days, with nothing logged today.
    func isRestDay(_ now: Date) -> Bool {
        guard let wd = plannedWeekdays, !trainedToday(now) else { return false }
        return !wd.contains(Self.calendar.component(.weekday, from: now))
    }

    func nextPlannedDate(after now: Date) -> Date? {
        let cal = Self.calendar
        for k in 1...7 {
            guard let d = cal.date(byAdding: .day, value: k, to: now) else { continue }
            if plannedWeekdays?.contains(cal.component(.weekday, from: d)) ?? true { return d }
        }
        return nil
    }

    enum SlotState { case done, today, upcoming }

    struct PlanSlot: Identifiable {
        let id: Int
        let label: String
        let glyph: String
        let state: SlotState
    }

    /// One slot per planned workout this week: done ones first, then what's coming.
    func planSlots(_ now: Date) -> [PlanSlot] {
        let cal = Self.calendar
        guard let week = cal.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let short: (Date) -> String = { $0.formatted(.dateTime.weekday(.abbreviated)) }
        let done = workouts.filter { week.contains($0.date) }.sorted { $0.date < $1.date }
        let target = max(1, weeklyTarget)
        var out: [PlanSlot] = []
        for (i, w) in done.prefix(target).enumerated() {
            out.append(PlanSlot(id: i, label: short(w.date), glyph: w.routine.glyph, state: .done))
        }
        let remaining = target - out.count
        guard remaining > 0 else { return out }
        var dates: [Date] = []
        if let wd = plannedWeekdays {
            let todayStart = cal.startOfDay(for: now)
            dates = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: week.start) }
                .filter { d in
                    wd.contains(cal.component(.weekday, from: d)) && d >= todayStart &&
                        !done.contains { cal.isDate($0.date, inSameDayAs: d) }
                }
        }
        let up = upcoming ?? [next]
        for k in 0..<remaining {
            let d: Date? = k < dates.count ? dates[k] : nil
            let glyph = up.isEmpty ? "" : up[k % up.count].glyph
            let isToday = d.map { cal.isDate($0, inSameDayAs: now) } ?? false
            out.append(PlanSlot(id: out.count, label: d.map(short) ?? "", glyph: glyph, state: isToday ? .today : .upcoming))
        }
        return out
    }

    func streak(_ now: Date) -> Int {
        let cal = Self.calendar
        guard var start = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        let starts = Set(workouts.compactMap { cal.dateInterval(of: .weekOfYear, for: $0.date)?.start })
        if !starts.contains(start), let prev = cal.date(byAdding: .weekOfYear, value: -1, to: start) { start = prev }
        var count = 0
        while starts.contains(start) {
            count += 1
            guard let prev = cal.date(byAdding: .weekOfYear, value: -1, to: start) else { break }
            start = prev
        }
        return count
    }

    static func relativeDay(_ date: Date, now: Date) -> String {
        let cal = calendar
        if cal.isDate(date, inSameDayAs: now) { return "Today" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func fmt(_ w: Double) -> String {
        w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }
}
