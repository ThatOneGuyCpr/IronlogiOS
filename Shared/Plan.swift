import Foundation

// MARK: - Muscles and focus

enum Muscle: String, CaseIterable, Codable, Identifiable {
    case chest, back, shoulders, biceps, triceps, quads, hams, calves, abs

    var id: String { rawValue }

    var name: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quads"
        case .hams: return "Hams & glutes"
        case .calves: return "Calves"
        case .abs: return "Abs"
        }
    }
}

/// Grow adds a set to every exercise for that muscle, Light takes one away.
enum Focus: String, Codable, CaseIterable, Identifiable {
    case grow, keep, light

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grow: return "Grow"
        case .keep: return "Keep"
        case .light: return "Light"
        }
    }
}

// MARK: - Programs

/// Starting points in the library. Each maps to a split by days per week plus default focus.
/// Based on common templates: full body for 2-3 days, upper/lower for 4, push/pull/legs for 3 or 6,
/// power + hypertrophy upper/lower (PHUL-style), and specialization blocks that add volume to
/// two or three muscles while the rest hold steady.
enum ProgramID: String, CaseIterable, Codable, Identifiable {
    case upperLower, fullBody, ppl, powerSize, armFocus, lowerFocus, backShoulders, minimal, custom

    var id: String { rawValue }

    var name: String {
        switch self {
        case .upperLower: return "Upper / Lower"
        case .fullBody: return "Full Body"
        case .ppl: return "Push / Pull / Legs"
        case .powerSize: return "Power + Size"
        case .armFocus: return "Arm focus"
        case .lowerFocus: return "Lower body focus"
        case .backShoulders: return "Back and shoulders"
        case .minimal: return "Minimal"
        case .custom: return "Custom"
        }
    }

    var blurb: String {
        switch self {
        case .upperLower: return "Each muscle twice a week across two upper and two lower days."
        case .fullBody: return "Every muscle, every session. The pick when you can only make two or three days."
        case .ppl: return "Chest, shoulders and triceps; back and biceps; then legs. Six days hits each twice."
        case .powerSize: return "Two heavy days at 4–6 reps on the big lifts, two size days at the usual ranges."
        case .armFocus: return "Upper/lower plus an arms and shoulders day. Biceps and triceps get the extra sets."
        case .lowerFocus: return "Quads, hamstrings, glutes and calves get the extra sets. Upper body at maintenance."
        case .backShoulders: return "Width from rows, pulldowns and lateral raises. No overhead pressing."
        case .minimal: return "Two sets per exercise, every muscle twice a week. Holds what you have."
        case .custom: return "Your own days and focus."
        }
    }

    var tags: [String] {
        switch self {
        case .upperLower, .ppl: return ["Balanced"]
        case .fullBody: return ["Balanced", "Short on time"]
        case .powerSize: return ["Strength"]
        case .armFocus, .lowerFocus, .backShoulders: return ["Muscle focus"]
        case .minimal: return ["Short on time"]
        case .custom: return []
        }
    }

    var dayOptions: [Int] {
        switch self {
        case .upperLower, .powerSize, .backShoulders: return [4]
        case .fullBody: return [2, 3]
        case .ppl: return [3, 6]
        case .armFocus: return [5]
        case .lowerFocus: return [3, 4]
        case .minimal: return [2]
        case .custom: return [2, 3, 4, 5, 6]
        }
    }

    var defaultDays: Int {
        switch self {
        case .fullBody, .ppl, .lowerFocus: return dayOptions.contains(3) && self != .lowerFocus ? 3 : 4
        default: return dayOptions.first ?? 4
        }
    }

    var daysLabel: String {
        switch self {
        case .fullBody: return "2–3 days"
        case .ppl: return "3 or 6 days"
        case .lowerFocus: return "3–4 days"
        case .armFocus: return "5 days · 6–8 wks"
        case .minimal: return "2 days"
        case .custom: return "2–6 days"
        default: return "\(defaultDays) days"
        }
    }

    var defaultFocus: [Muscle: Focus] {
        switch self {
        case .armFocus: return [.biceps: .grow, .triceps: .grow]
        case .lowerFocus: return [.quads: .grow, .hams: .grow, .calves: .grow, .chest: .light, .back: .light, .shoulders: .light]
        case .backShoulders: return [.back: .grow, .shoulders: .grow]
        default: return [:]
        }
    }

    /// Added to every exercise's sets before focus.
    var setDelta: Int { self == .minimal ? -1 : 0 }

    /// Heavy reps on the main lifts on A days.
    var powerDays: Bool { self == .powerSize }

    /// A caution shown on the preview, when one applies.
    var note: String? {
        switch self {
        case .armFocus, .lowerFocus, .backShoulders:
            return "Focus programs work best as a 6 to 8 week block, and while you're not cutting. Then switch back to a balanced plan."
        case .powerSize:
            return "On A days the first two lifts drop to 4–6 reps with longer rest. B days stay as usual."
        case .minimal:
            return "Most muscles land under 10 sets a week. Good for holding what you have during a busy stretch."
        default:
            return nil
        }
    }

    /// The library, in display order.
    static let library: [ProgramID] = [.upperLower, .fullBody, .ppl, .powerSize, .armFocus, .lowerFocus, .backShoulders, .minimal]
}

// MARK: - Plan

/// How hard and how dense each session is. Trades rest and accessory sets for time,
/// and asks for more effort on the sets that are left.
enum Intensity: String, Codable, CaseIterable, Identifiable {
    case normal, high, max

    var id: String { rawValue }

    var name: String {
        switch self {
        case .normal: return "Normal"
        case .high: return "High"
        case .max: return "Max"
        }
    }

    var blurb: String {
        switch self {
        case .normal: return "Full rest. Stop about 2 reps short of failure."
        case .high: return "Rest cut by a quarter. Stop 1 rep short of failure."
        case .max: return "Shortest rest, and one less set after the first three lifts. Take the last set of each exercise to failure."
        }
    }

    /// Shown on the workout screen.
    var effort: String {
        switch self {
        case .normal: return "Stop about 2 reps short of failure"
        case .high: return "Stop 1 rep short of failure"
        case .max: return "Last set of each exercise to failure"
        }
    }

    private var restScale: Double {
        switch self {
        case .normal: return 1
        case .high: return 0.75
        case .max: return 0.6
        }
    }

    /// Shorter rest, but never below a floor that keeps the next set useful.
    func rest(_ seconds: Int, compound: Bool) -> Int {
        guard self != .normal else { return seconds }
        let floor = compound ? 60 : 30
        if seconds <= floor { return seconds }
        let scaled = Int((Double(seconds) * restScale / 5).rounded()) * 5
        return max(floor, scaled)
    }
}

struct Plan: Codable, Equatable {
    var program: ProgramID = .upperLower
    var days: Int = 4
    /// Calendar weekdays you train (1 = Sunday). nil means whenever you can.
    var weekdays: [Int]? = nil
    /// Muscle raw value → focus. Missing means keep.
    var focus: [String: Focus] = [:]
    var intensity: Intensity = .normal

    init(program: ProgramID = .upperLower, days: Int = 4, weekdays: [Int]? = nil, focus: [String: Focus] = [:], intensity: Intensity = .normal) {
        self.program = program
        self.days = days
        self.weekdays = weekdays
        self.focus = focus
        self.intensity = intensity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        program = (try? c.decodeIfPresent(ProgramID.self, forKey: .program)) ?? .upperLower
        days = (try? c.decodeIfPresent(Int.self, forKey: .days)) ?? 4
        weekdays = try? c.decodeIfPresent([Int].self, forKey: .weekdays)
        focus = (try? c.decodeIfPresent([String: Focus].self, forKey: .focus)) ?? [:]
        intensity = (try? c.decodeIfPresent(Intensity.self, forKey: .intensity)) ?? .normal
    }

    /// A library program at its default (or given) days, with its default focus.
    static func standard(_ program: ProgramID, days: Int? = nil, weekdays: [Int]?? = nil) -> Plan {
        let d = days ?? program.defaultDays
        var focus: [String: Focus] = [:]
        for (m, f) in program.defaultFocus { focus[m.rawValue] = f }
        let wd: [Int]? = weekdays ?? defaultWeekdays(d)
        return Plan(program: program, days: d, weekdays: wd, focus: focus)
    }

    /// Mon/Wed/Fri style spreads by days per week, as Calendar weekdays.
    static func defaultWeekdays(_ days: Int) -> [Int] {
        switch days {
        case 2: return [3, 6]
        case 3: return [2, 4, 6]
        case 4: return [2, 3, 5, 6]
        case 5: return [2, 3, 4, 5, 6]
        default: return [2, 3, 4, 5, 6, 7]
        }
    }

    func focus(for m: Muscle) -> Focus { focus[m.rawValue] ?? .keep }

    func with(_ intensity: Intensity) -> Plan {
        var p = self
        p.intensity = intensity
        return p
    }

    var growCount: Int { focus.values.filter { $0 == .grow }.count }

    /// Workouts in order. One pass is one week.
    var rotation: [RoutineID] { Plan.rotation(program, days) }

    static func rotation(_ program: ProgramID, _ days: Int) -> [RoutineID] {
        let ul: [RoutineID] = [.upperA, .lowerA, .upperB, .lowerB]
        let fb2: [RoutineID] = [.fullA, .fullC]
        let fb3: [RoutineID] = [.fullA, .fullB, .fullC]
        let ppl3: [RoutineID] = [.pushA, .pullA, .legsA]
        let ppl6: [RoutineID] = [.pushA, .pullA, .legsA, .pushB, .pullB, .legsB]
        switch program {
        case .upperLower, .powerSize, .backShoulders: return ul
        case .fullBody, .minimal: return days <= 2 ? fb2 : fb3
        case .ppl: return days >= 6 ? ppl6 : ppl3
        case .armFocus: return ul + [.arms]
        case .lowerFocus: return days <= 3 ? fb3 : ul
        case .custom:
            switch days {
            case ...2: return fb2
            case 3: return fb3
            case 4: return ul
            case 5: return ul + [.arms]
            default: return ppl6
            }
        }
    }

    func next(after last: RoutineID?) -> RoutineID {
        let r = rotation
        guard let last, let i = r.firstIndex(of: last) else { return r.first ?? .upperA }
        return r[(i + 1) % r.count]
    }

    /// The next `count` workouts starting at `first`.
    func upcoming(from first: RoutineID, count: Int) -> [RoutineID] {
        let r = rotation
        guard let start = r.firstIndex(of: first) else { return Array(r.prefix(count)) }
        return (0..<max(0, count)).map { r[(start + $0) % r.count] }
    }

    /// Sets for one exercise after program and focus adjustments.
    /// `accessory` is any slot after the first three, which hold each day's main squat or hinge,
    /// push and pull. Max drops a set there, except on muscles you're growing.
    func sets(_ base: Int, for muscle: Muscle?, accessory: Bool = false) -> Int {
        var delta = program.setDelta
        if let muscle {
            switch focus(for: muscle) {
            case .grow: delta += 1
            case .light: delta -= 1
            case .keep: break
            }
        }
        if intensity == .max, accessory, muscle.map({ focus(for: $0) != .grow }) ?? true {
            delta -= 1
        }
        return max(2, min(6, base + delta))
    }

    func isPlanned(weekday: Int) -> Bool { weekdays?.contains(weekday) ?? true }

    var isFixed: Bool { weekdays != nil }

    var name: String {
        let base = "\(program.name) · \(days.counted("day"))"
        return intensity == .normal ? base : base + " · " + intensity.name
    }

    /// The split, described for the builder.
    var splitName: String {
        switch rotation.count {
        case 2 where rotation.first == .fullA: return "Full Body A / C"
        default: break
        }
        if rotation.contains(.fullB) { return "Full Body A / B / C" }
        if rotation.contains(.pushB) { return "Push / Pull / Legs ×2" }
        if rotation.contains(.pushA) { return "Push / Pull / Legs" }
        if rotation.contains(.arms) { return "Upper / Lower + Arms" }
        return "Upper / Lower"
    }

    static let weekdayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var weekdayText: String {
        guard let weekdays else { return "Whenever you can" }
        let order = [2, 3, 4, 5, 6, 7, 1]
        return order.filter { weekdays.contains($0) }.map { Plan.weekdayNames[$0] }.joined(separator: ", ")
    }
}
