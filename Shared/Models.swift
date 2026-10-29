import Foundation

// MARK: - Equipment

enum Equipment: String, CaseIterable, Codable, Identifiable, Hashable {
    case dumbbells, smith, bench, cable, lat, legPress, legMachine, abMachine

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
}

enum RoutineID: String, CaseIterable, Codable, Identifiable {
    case upperA, upperB, lowerA, lowerB

    var id: String { rawValue }

    /// Training order: Upper A, Lower A, Upper B, Lower B.
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
        }
    }

    var code: String {
        switch self {
        case .upperA: return "UA"
        case .upperB: return "UB"
        case .lowerA: return "LA"
        case .lowerB: return "LB"
        }
    }

    var subtitle: String {
        switch self {
        case .upperA: return "Chest, back, arms"
        case .upperB: return "Back, chest, delts, arms"
        case .lowerA: return "Quads, hinge, calves, abs"
        case .lowerB: return "Hinge, glutes, hams, abs"
        }
    }

    var slots: [Slot] {
        switch self {
        case .upperA: return [
            Slot(label: "Chest press", candidates: ["db_bench", "smith_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Vertical pull", candidates: ["lat_wide", "cable_pulldown", "db_pullover"]),
            Slot(label: "Incline press", candidates: ["db_incline", "smith_incline", "cable_low_high"]),
            Slot(label: "Row", candidates: ["cable_row", "cs_db_row", "one_arm_row", "smith_row"]),
            Slot(label: "Biceps", candidates: ["db_curl", "cable_curl", "incline_curl"], pairNext: true),
            Slot(label: "Triceps", candidates: ["pushdown", "db_skull", "smith_cgp", "bench_dip"]),
        ]
        case .upperB: return [
            Slot(label: "Vertical pull", candidates: ["lat_close", "cable_pulldown", "straight_arm", "db_pullover"]),
            Slot(label: "Incline chest", candidates: ["smith_incline", "db_incline", "cable_low_high", "db_fly"]),
            Slot(label: "Row", candidates: ["cs_db_row", "cable_row", "one_arm_row", "smith_row"]),
            Slot(label: "Side delts", candidates: ["cable_lat_raise", "db_lat_raise", "face_pull"]),
            Slot(label: "Biceps", candidates: ["hammer", "cable_curl", "incline_curl", "db_curl"], pairNext: true),
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
        }
    }
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
