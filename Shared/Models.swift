import Foundation

// MARK: - Equipment

enum Equipment: String, CaseIterable, Codable, Identifiable, Hashable {
    case dumbbells, smith, bench, cable, lat, legPress, legMachine, abMachine, preacher

    var id: String { rawValue }

    var name: String {
        switch self {
        case .dumbbells: return "Dumbbells"
        case .smith: return "Smith machine"
        case .bench: return "Adjustable bench"
        case .cable: return "Cable machine"
        case .lat: return "Lat pulldown"
        case .legPress: return "Leg press"
        case .legMachine: return "Leg machine"
        case .abMachine: return "Ab machine"
        case .preacher: return "Preacher bench"
        }
    }

    /// IDs the web version used, for importing its backups.
    static func fromWeb(_ id: String) -> Equipment? {
        switch id {
        case "legpress": return .legPress
        case "legmachine": return .legMachine
        case "abmachine": return .abMachine
        default: return Equipment(rawValue: id)
        }
    }
}

// MARK: - Prescriptions

/// Sets, rep range and rest for an exercise. For timed holds, low/high are seconds.
struct Prescription: Codable, Hashable {
    var sets: Int
    var low: Int
    var high: Int
    var rest: Int

    var rangeText: String { "\(low)-\(high)" }
}

/// Defaults based on common hypertrophy guidance:
/// heavy compounds 6-10, most compounds 8-12, isolation 10-15,
/// small muscles and calves 12-20. Rest 90s for compounds, 60s for most, 30s for calves.
enum Preset {
    static let heavy = Prescription(sets: 3, low: 6, high: 10, rest: 90)
    static let compound = Prescription(sets: 3, low: 8, high: 12, rest: 90)
    static let isolation = Prescription(sets: 3, low: 10, high: 15, rest: 60)
    static let small = Prescription(sets: 3, low: 12, high: 20, rest: 60)
    static let lateral = Prescription(sets: 3, low: 12, high: 20, rest: 45)
    static let calf = Prescription(sets: 3, low: 12, high: 20, rest: 30)
    static let abs = Prescription(sets: 3, low: 10, high: 15, rest: 60)
    static let hold = Prescription(sets: 3, low: 30, high: 60, rest: 60)
}

// MARK: - Exercises

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: [Equipment]
    let preset: Prescription
    var bodyweight: Bool = false
    var timed: Bool = false
    var perSide: Bool = false
    /// Weight jump in lb when progressing.
    var increment: Double = 5

    var videoURL: URL? {
        let q = (name + " proper form").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(q)")
    }
}

enum Library {
    private static func ex(_ id: String, _ name: String, _ eq: [Equipment], _ p: Prescription,
                           bw: Bool = false, timed: Bool = false, side: Bool = false,
                           inc: Double = 5) -> Exercise {
        Exercise(id: id, name: name, equipment: eq, preset: p,
                 bodyweight: bw, timed: timed, perSide: side, increment: inc)
    }

    static let all: [Exercise] = [
        // Chest
        ex("db_bench", "Dumbbell bench press", [.dumbbells, .bench], Preset.compound),
        ex("smith_bench", "Smith bench press", [.smith, .bench], Preset.heavy, inc: 10),
        ex("cable_press", "Standing cable chest press", [.cable], Preset.isolation),
        ex("incline_pushup", "Incline push-up (hands on bench)", [.bench], Preset.isolation, bw: true),
        ex("db_incline", "Incline dumbbell press", [.dumbbells, .bench], Preset.compound),
        ex("smith_incline", "Incline Smith press", [.smith, .bench], Preset.compound, inc: 10),
        ex("cable_low_high", "Low-to-high cable fly", [.cable], Preset.isolation),
        ex("db_fly", "Dumbbell fly (flat bench)", [.dumbbells, .bench], Preset.isolation),
        // Back
        ex("lat_wide", "Lat pulldown (wide grip)", [.lat], Preset.compound, inc: 10),
        ex("lat_close", "Lat pulldown (close neutral grip)", [.lat], Preset.compound, inc: 10),
        ex("cable_pulldown", "Cable pulldown (straight bar)", [.cable], Preset.compound, inc: 10),
        ex("straight_arm", "Cable straight-arm pulldown", [.cable], Preset.isolation),
        ex("db_pullover", "Dumbbell pullover (across bench)", [.dumbbells, .bench], Preset.isolation),
        ex("cable_row", "Seated cable row", [.cable], Preset.compound, inc: 10),
        ex("cs_db_row", "Chest-supported dumbbell row", [.dumbbells, .bench], Preset.compound),
        ex("one_arm_row", "One-arm dumbbell row", [.dumbbells, .bench], Preset.compound, side: true),
        ex("smith_row", "Smith bent-over row", [.smith], Preset.compound, inc: 10),
        // Arms
        ex("db_curl", "Dumbbell curl", [.dumbbells], Preset.isolation),
        ex("hammer", "Hammer curl", [.dumbbells], Preset.isolation),
        ex("cable_curl", "Cable curl", [.cable], Preset.isolation),
        ex("incline_curl", "Incline dumbbell curl", [.dumbbells, .bench], Preset.isolation),
        ex("preacher_curl", "Dumbbell preacher curl", [.preacher, .dumbbells], Preset.isolation),
        ex("pushdown", "Cable triceps pushdown", [.cable], Preset.isolation),
        ex("db_skull", "Dumbbell skull crusher", [.dumbbells, .bench], Preset.isolation),
        ex("smith_cgp", "Close-grip Smith bench press", [.smith, .bench], Preset.compound, inc: 10),
        ex("bench_dip", "Bench dips", [.bench], Preset.isolation, bw: true),
        // Delts
        ex("cable_lat_raise", "Cable lateral raise", [.cable], Preset.lateral, side: true),
        ex("db_lat_raise", "Dumbbell lateral raise", [.dumbbells], Preset.lateral),
        ex("face_pull", "Cable face pull", [.cable], Preset.small),
        // Legs
        ex("legpress", "Leg press", [.legPress], Preset.compound, inc: 10),
        ex("legpress_high", "Leg press (feet high and wide)", [.legPress], Preset.compound, inc: 10),
        ex("smith_squat", "Smith squat", [.smith], Preset.heavy, inc: 10),
        ex("goblet", "Goblet squat", [.dumbbells], Preset.compound),
        ex("db_rdl", "Dumbbell Romanian deadlift", [.dumbbells], Preset.compound),
        ex("smith_rdl", "Smith Romanian deadlift", [.smith], Preset.heavy, inc: 10),
        ex("pullthrough", "Cable pull-through", [.cable], Preset.isolation),
        ex("db_bss", "Bulgarian split squat", [.dumbbells, .bench], Preset.compound, side: true),
        ex("db_lunge", "Dumbbell walking lunge", [.dumbbells], Preset.compound, side: true),
        ex("step_up", "Bench step-up", [.bench], Preset.isolation, bw: true, side: true),
        ex("smith_split", "Smith split squat", [.smith], Preset.compound, side: true, inc: 10),
        ex("leg_ext", "Leg extension", [.legMachine], Preset.isolation),
        ex("leg_curl", "Leg curl", [.legMachine], Preset.isolation),
        ex("db_sl_rdl", "Single-leg dumbbell RDL", [.dumbbells], Preset.isolation, side: true),
        ex("smith_thrust", "Smith hip thrust", [.smith, .bench], Preset.compound, inc: 10),
        ex("db_thrust", "Dumbbell hip thrust", [.dumbbells, .bench], Preset.compound),
        ex("kickback", "Cable glute kickback", [.cable], Preset.small, side: true),
        // Calves
        ex("legmachine_calf", "Leg machine calf raise", [.legMachine], Preset.calf),
        ex("smith_calf", "Smith calf raise", [.smith], Preset.calf, inc: 10),
        ex("lp_calf", "Leg press calf raise", [.legPress], Preset.calf, inc: 10),
        ex("db_calf", "Single-leg dumbbell calf raise", [.dumbbells], Preset.calf, side: true),
        ex("bw_calf", "Bodyweight calf raise", [], Preset.calf, bw: true),
        // Abs
        ex("ab_crunch", "Ab machine crunch", [.abMachine], Preset.abs),
        ex("cable_crunch", "Kneeling cable crunch", [.cable], Preset.abs),
        ex("plank", "Plank", [], Preset.hold, bw: true, timed: true),
    ]

    static let byID: [String: Exercise] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}

// MARK: - Routines

struct Slot: Hashable {
    let label: String
    let candidates: [String]
    /// Suggested superset with the next slot.
    var pairNext: Bool = false

    /// The muscle this slot trains, from its label.
    var muscle: Muscle {
        switch label {
        case "Chest press", "Incline press", "Incline chest", "Chest fly": return .chest
        case "Vertical pull", "Row", "Pullover": return .back
        case "Side delts", "Rear delts": return .shoulders
        case "Biceps": return .biceps
        case "Triceps": return .triceps
        case "Squat pattern", "Single leg", "Quads": return .quads
        case "Hinge", "Hamstrings", "Glutes": return .hams
        case "Calves": return .calves
        default: return .abs
        }
    }
}

enum RoutineID: String, CaseIterable, Codable, Identifiable {
    case upperA, upperB, lowerA, lowerB
    case fullA, fullB, fullC
    case pushA, pullA, legsA, pushB, pullB, legsB
    case arms

    var id: String { rawValue }

    /// The original four-day order. Plans have their own rotation (Plan.rotation).
    static let cycle: [RoutineID] = [.upperA, .lowerA, .upperB, .lowerB]

    static func next(after last: RoutineID?) -> RoutineID {
        guard let last, let i = cycle.firstIndex(of: last) else { return cycle[0] }
        return cycle[(i + 1) % cycle.count]
    }

    var title: String {
        switch self {
        case .upperA: return "Upper A"
        case .upperB: return "Upper B"
        case .lowerA: return "Lower A"
        case .lowerB: return "Lower B"
        case .fullA: return "Full Body A"
        case .fullB: return "Full Body B"
        case .fullC: return "Full Body C"
        case .pushA: return "Push A"
        case .pullA: return "Pull A"
        case .legsA: return "Legs A"
        case .pushB: return "Push B"
        case .pullB: return "Pull B"
        case .legsB: return "Legs B"
        case .arms: return "Arms & Shoulders"
        }
    }

    /// Short name for pickers.
    var shortTitle: String {
        switch self {
        case .fullA: return "Full A"
        case .fullB: return "Full B"
        case .fullC: return "Full C"
        case .arms: return "Arms"
        default: return title
        }
    }

    var isUpper: Bool { self == .upperA || self == .upperB }

    /// SF Symbol for the week strip, when the routine has a direction.
    var arrowSymbol: String? {
        switch self {
        case .upperA, .upperB: return "arrow.up"
        case .lowerA, .lowerB: return "arrow.down"
        case .fullA, .fullB, .fullC: return "arrow.up.and.down"
        default: return nil
        }
    }

    /// "A", "B" or "C" where it applies.
    var variant: String {
        switch self {
        case .upperA, .lowerA, .fullA, .pushA, .pullA, .legsA: return "A"
        case .upperB, .lowerB, .fullB, .pushB, .pullB, .legsB: return "B"
        case .fullC: return "C"
        case .arms: return ""
        }
    }

    /// Letters shown next to the arrow, or alone when there's no arrow.
    var badge: String {
        switch self {
        case .pushA, .pushB: return "Pu"
        case .pullA, .pullB: return "Pl"
        case .legsA, .legsB: return "Lg"
        case .arms: return "Ar"
        default: return variant
        }
    }

    /// Plain-text mark for widgets: "↑A", "↕B", "Pu".
    var glyph: String {
        switch self {
        case .upperA, .upperB: return "↑" + variant
        case .lowerA, .lowerB: return "↓" + variant
        case .fullA, .fullB, .fullC: return "↕" + variant
        default: return badge
        }
    }

    var code: String {
        switch self {
        case .upperA: return "UA"
        case .upperB: return "UB"
        case .lowerA: return "LA"
        case .lowerB: return "LB"
        case .fullA: return "FA"
        case .fullB: return "FB"
        case .fullC: return "FC"
        case .pushA: return "PuA"
        case .pullA: return "PlA"
        case .legsA: return "LgA"
        case .pushB: return "PuB"
        case .pullB: return "PlB"
        case .legsB: return "LgB"
        case .arms: return "AR"
        }
    }

    var subtitle: String {
        switch self {
        case .upperA: return "Chest, back, arms"
        case .upperB: return "Back, chest, delts, arms"
        case .lowerA: return "Quads, hinge, calves, abs"
        case .lowerB: return "Hinge, glutes, hams, abs"
        case .fullA: return "Every muscle, squat and press first"
        case .fullB: return "Every muscle, hinge and row first"
        case .fullC: return "Every muscle, glutes and arms"
        case .pushA, .pushB: return "Chest, side delts, triceps"
        case .pullA, .pullB: return "Back, rear delts, biceps"
        case .legsA, .legsB: return "Quads, hams, glutes, calves, abs"
        case .arms: return "Biceps, triceps, delts"
        }
    }

    var slots: [Slot] {
        switch self {
        case .upperA: return [
            Slot(label: "Chest press", candidates: ["db_bench", "smith_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Vertical pull", candidates: ["lat_wide", "cable_pulldown", "db_pullover"]),
            Slot(label: "Incline press", candidates: ["db_incline", "smith_incline", "cable_low_high"]),
            Slot(label: "Row", candidates: ["cable_row", "cs_db_row", "one_arm_row", "smith_row"]),
            Slot(label: "Biceps", candidates: ["preacher_curl", "db_curl", "cable_curl", "incline_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["pushdown", "db_skull", "smith_cgp", "bench_dip"]),
        ]
        case .upperB: return [
            Slot(label: "Vertical pull", candidates: ["lat_close", "cable_pulldown", "straight_arm", "db_pullover"]),
            Slot(label: "Incline chest", candidates: ["smith_incline", "db_incline", "cable_low_high", "db_fly"]),
            Slot(label: "Row", candidates: ["cs_db_row", "cable_row", "one_arm_row", "smith_row"]),
            Slot(label: "Side delts", candidates: ["cable_lat_raise", "db_lat_raise", "face_pull"]),
            Slot(label: "Biceps", candidates: ["hammer", "preacher_curl", "cable_curl", "incline_curl", "db_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["db_skull", "pushdown", "bench_dip", "smith_cgp"]),
        ]
        case .lowerA: return [
            Slot(label: "Squat pattern", candidates: ["legpress", "smith_squat", "goblet"]),
            Slot(label: "Hinge", candidates: ["db_rdl", "smith_rdl", "pullthrough"]),
            Slot(label: "Single leg", candidates: ["db_bss", "db_lunge", "step_up", "smith_split"]),
            Slot(label: "Quads", candidates: ["leg_ext", "goblet", "db_lunge"]),
            Slot(label: "Calves", candidates: ["legmachine_calf", "smith_calf", "lp_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["ab_crunch", "cable_crunch", "plank"]),
        ]
        case .lowerB: return [
            Slot(label: "Hinge", candidates: ["smith_rdl", "db_rdl", "pullthrough"]),
            Slot(label: "Squat pattern", candidates: ["legpress_high", "smith_squat", "goblet"]),
            Slot(label: "Hamstrings", candidates: ["leg_curl", "db_sl_rdl", "pullthrough"]),
            Slot(label: "Glutes", candidates: ["smith_thrust", "db_thrust", "kickback"]),
            Slot(label: "Calves", candidates: ["lp_calf", "legmachine_calf", "smith_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["cable_crunch", "ab_crunch", "plank"]),
        ]
        case .fullA: return [
            Slot(label: "Squat pattern", candidates: ["legpress", "smith_squat", "goblet"]),
            Slot(label: "Chest press", candidates: ["db_bench", "smith_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Vertical pull", candidates: ["lat_wide", "cable_pulldown", "db_pullover"]),
            Slot(label: "Hamstrings", candidates: ["leg_curl", "db_sl_rdl", "pullthrough"]),
            Slot(label: "Side delts", candidates: ["cable_lat_raise", "db_lat_raise", "face_pull"]),
            Slot(label: "Biceps", candidates: ["preacher_curl", "db_curl", "cable_curl", "incline_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["pushdown", "db_skull", "bench_dip", "smith_cgp"]),
        ]
        case .fullB: return [
            Slot(label: "Hinge", candidates: ["db_rdl", "smith_rdl", "pullthrough"]),
            Slot(label: "Incline chest", candidates: ["db_incline", "smith_incline", "cable_low_high", "db_fly"]),
            Slot(label: "Row", candidates: ["cable_row", "cs_db_row", "one_arm_row", "smith_row"]),
            Slot(label: "Single leg", candidates: ["db_bss", "db_lunge", "smith_split", "step_up"]),
            Slot(label: "Side delts", candidates: ["db_lat_raise", "cable_lat_raise", "face_pull"]),
            Slot(label: "Calves", candidates: ["legmachine_calf", "lp_calf", "smith_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["ab_crunch", "cable_crunch", "plank"]),
        ]
        case .fullC: return [
            Slot(label: "Squat pattern", candidates: ["legpress_high", "smith_squat", "goblet"]),
            Slot(label: "Chest press", candidates: ["smith_bench", "db_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Vertical pull", candidates: ["lat_close", "cable_pulldown", "straight_arm", "db_pullover"]),
            Slot(label: "Glutes", candidates: ["smith_thrust", "db_thrust", "kickback"]),
            Slot(label: "Biceps", candidates: ["hammer", "preacher_curl", "cable_curl", "incline_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["db_skull", "pushdown", "bench_dip", "smith_cgp"]),
            Slot(label: "Calves", candidates: ["lp_calf", "legmachine_calf", "smith_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["cable_crunch", "ab_crunch", "plank"]),
        ]
        case .pushA: return [
            Slot(label: "Chest press", candidates: ["db_bench", "smith_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Incline press", candidates: ["db_incline", "smith_incline", "cable_low_high"]),
            Slot(label: "Chest fly", candidates: ["cable_low_high", "db_fly", "cable_press"]),
            Slot(label: "Side delts", candidates: ["cable_lat_raise", "db_lat_raise"]),
            Slot(label: "Triceps", candidates: ["pushdown", "db_skull", "smith_cgp", "bench_dip"]),
            Slot(label: "Triceps", candidates: ["db_skull", "smith_cgp", "bench_dip", "pushdown"]),
        ]
        case .pullA: return [
            Slot(label: "Vertical pull", candidates: ["lat_wide", "cable_pulldown", "db_pullover"]),
            Slot(label: "Row", candidates: ["cable_row", "cs_db_row", "one_arm_row", "smith_row"]),
            Slot(label: "Row", candidates: ["cs_db_row", "one_arm_row", "smith_row", "cable_row"]),
            Slot(label: "Rear delts", candidates: ["face_pull", "cable_lat_raise", "db_lat_raise"]),
            Slot(label: "Biceps", candidates: ["preacher_curl", "db_curl", "cable_curl", "incline_curl"]),
            Slot(label: "Biceps", candidates: ["hammer", "cable_curl", "incline_curl", "db_curl"]),
        ]
        case .legsA: return [
            Slot(label: "Squat pattern", candidates: ["legpress", "smith_squat", "goblet"]),
            Slot(label: "Hinge", candidates: ["db_rdl", "smith_rdl", "pullthrough"]),
            Slot(label: "Single leg", candidates: ["db_bss", "db_lunge", "step_up", "smith_split"]),
            Slot(label: "Hamstrings", candidates: ["leg_curl", "db_sl_rdl", "pullthrough"]),
            Slot(label: "Calves", candidates: ["legmachine_calf", "smith_calf", "lp_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["ab_crunch", "cable_crunch", "plank"]),
        ]
        case .pushB: return [
            Slot(label: "Incline press", candidates: ["smith_incline", "db_incline", "cable_low_high"]),
            Slot(label: "Chest press", candidates: ["smith_bench", "db_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Chest fly", candidates: ["db_fly", "cable_low_high", "cable_press"]),
            Slot(label: "Side delts", candidates: ["db_lat_raise", "cable_lat_raise"]),
            Slot(label: "Triceps", candidates: ["db_skull", "pushdown", "bench_dip", "smith_cgp"]),
            Slot(label: "Triceps", candidates: ["smith_cgp", "pushdown", "bench_dip", "db_skull"]),
        ]
        case .pullB: return [
            Slot(label: "Vertical pull", candidates: ["lat_close", "cable_pulldown", "db_pullover"]),
            Slot(label: "Row", candidates: ["cs_db_row", "cable_row", "one_arm_row", "smith_row"]),
            Slot(label: "Pullover", candidates: ["straight_arm", "db_pullover", "cable_pulldown"]),
            Slot(label: "Rear delts", candidates: ["face_pull", "cable_lat_raise", "db_lat_raise"]),
            Slot(label: "Biceps", candidates: ["hammer", "preacher_curl", "cable_curl", "db_curl"]),
            Slot(label: "Biceps", candidates: ["incline_curl", "db_curl", "cable_curl", "preacher_curl"]),
        ]
        case .legsB: return [
            Slot(label: "Hinge", candidates: ["smith_rdl", "db_rdl", "pullthrough"]),
            Slot(label: "Squat pattern", candidates: ["legpress_high", "smith_squat", "goblet"]),
            Slot(label: "Quads", candidates: ["leg_ext", "goblet", "db_lunge"]),
            Slot(label: "Glutes", candidates: ["smith_thrust", "db_thrust", "kickback"]),
            Slot(label: "Calves", candidates: ["lp_calf", "legmachine_calf", "smith_calf", "db_calf", "bw_calf"], pairNext: true),
            Slot(label: "Abs", candidates: ["cable_crunch", "ab_crunch", "plank"]),
        ]
        case .arms: return [
            Slot(label: "Biceps", candidates: ["preacher_curl", "db_curl", "cable_curl", "incline_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["pushdown", "db_skull", "bench_dip", "smith_cgp"]),
            Slot(label: "Biceps", candidates: ["hammer", "incline_curl", "cable_curl", "db_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["db_skull", "smith_cgp", "bench_dip", "pushdown"]),
            Slot(label: "Side delts", candidates: ["cable_lat_raise", "db_lat_raise"]),
            Slot(label: "Rear delts", candidates: ["face_pull", "db_lat_raise"]),
        ]
        }
    }
}

extension Library {
    /// The main muscle an exercise trains, taken from the first slot that lists it.
    static let muscleByID: [String: Muscle] = {
        var out: [String: Muscle] = [:]
        for r in RoutineID.allCases {
            for slot in r.slots {
                for id in slot.candidates where out[id] == nil { out[id] = slot.muscle }
            }
        }
        return out
    }()
}

// MARK: - Picking exercises from what's open

enum Generator {
    static func isAvailable(_ ex: Exercise, open: Set<Equipment>, hidden: Set<String> = []) -> Bool {
        !hidden.contains(ex.id) && ex.equipment.allSatisfy { open.contains($0) }
    }

    /// One pick per slot; nil when nothing in the slot is usable.
    static func plan(for routine: RoutineID, open: Set<Equipment>, hidden: Set<String> = []) -> [Exercise?] {
        var used = Set<String>()
        return routine.slots.map { slot in
            let pick = slot.candidates
                .compactMap { Library.byID[$0] }
                .first { isAvailable($0, open: open, hidden: hidden) && !used.contains($0.id) }
            if let pick { used.insert(pick.id) }
            return pick
        }
    }
}
