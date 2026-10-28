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
    }

    func days(_ now: Date) -> [Day] {
        let cal = Self.calendar
        guard let start = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i in
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { return nil }
            let w = workouts.first { cal.isDate($0.date, inSameDayAs: day) }
            return Day(id: i, letter: letters[i], code: w?.routine.code, isToday: cal.isDate(day, inSameDayAs: now))
        }
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
