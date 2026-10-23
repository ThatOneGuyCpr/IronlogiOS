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

    var symbol: String {
        switch self {
        case .dumbbells: return "dumbbell.fill"
        case .smith: return "figure.strengthtraining.traditional"
        case .bench: return "rectangle.portrait.fill"
        case .cable: return "cable.connector"
        case .lat: return "arrow.down.to.line"
        case .legPress: return "figure.step.training"
        case .legMachine: return "figure.walk"
        case .abMachine: return "figure.core.training"
        }
    }
}

// MARK: - Exercises

/// Rest defaults: heavy compounds 90s, most work 60s, calves 30s.
enum Rest {
    static let heavy = 90
    static let general = 60
    static let short = 30
}

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: [Equipment]
    var rest: Int = Rest.general
    var bodyweight: Bool = false
    var timed: Bool = false
    var increment: Double = 5

    /// Placeholder until curated videos land: a YouTube search that never goes dead.
    var videoURL: URL? {
        let q = (name + " proper form").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(q)")
    }
}

enum Library {
    private static func ex(_ id: String, _ name: String, _ eq: [Equipment],
                           rest: Int = Rest.general, bw: Bool = false,
                           timed: Bool = false, inc: Double = 5) -> Exercise {
        Exercise(id: id, name: name, equipment: eq, rest: rest, bodyweight: bw, timed: timed, increment: inc)
    }

    static let all: [Exercise] = [
        // Chest
        ex("db_bench", "Dumbbell bench press", [.dumbbells, .bench], rest: Rest.heavy),
        ex("smith_bench", "Smith bench press", [.smith, .bench], rest: Rest.heavy, inc: 10),
        ex("cable_press", "Standing cable chest press", [.cable]),
        ex("incline_pushup", "Incline push-up (hands on bench)", [.bench], bw: true),
        ex("db_incline", "Incline dumbbell press", [.dumbbells, .bench], rest: Rest.heavy),
        ex("smith_incline", "Incline Smith press", [.smith, .bench], rest: Rest.heavy, inc: 10),
        ex("cable_low_high", "Low-to-high cable fly", [.cable]),
        ex("db_fly", "Dumbbell fly (flat bench)", [.dumbbells, .bench]),
        // Back
        ex("lat_wide", "Lat pulldown (wide grip)", [.lat], rest: Rest.heavy, inc: 10),
        ex("lat_close", "Lat pulldown (close neutral grip)", [.lat], rest: Rest.heavy, inc: 10),
        ex("cable_pulldown", "Cable pulldown (straight bar)", [.cable]),
        ex("straight_arm", "Cable straight-arm pulldown", [.cable]),
        ex("db_pullover", "Dumbbell pullover (across bench)", [.dumbbells, .bench]),
        ex("cable_row", "Seated cable row", [.cable], rest: Rest.heavy, inc: 10),
        ex("cs_db_row", "Chest-supported dumbbell row", [.dumbbells, .bench], rest: Rest.heavy),
        ex("one_arm_row", "One-arm dumbbell row", [.dumbbells, .bench], rest: Rest.heavy),
        ex("smith_row", "Smith bent-over row", [.smith], rest: Rest.heavy, inc: 10),
        // Arms
        ex("db_curl", "Dumbbell curl", [.dumbbells]),
        ex("hammer", "Hammer curl", [.dumbbells]),
        ex("cable_curl", "Cable curl", [.cable]),
        ex("incline_curl", "Incline dumbbell curl", [.dumbbells, .bench]),
        ex("pushdown", "Cable triceps pushdown", [.cable]),
        ex("db_skull", "Dumbbell skull crusher", [.dumbbells, .bench]),
        ex("smith_cgp", "Close-grip Smith bench press", [.smith, .bench], rest: Rest.heavy, inc: 10),
        ex("bench_dip", "Bench dips", [.bench], bw: true),
        // Delts
        ex("cable_lat_raise", "Cable lateral raise", [.cable]),
        ex("db_lat_raise", "Dumbbell lateral raise", [.dumbbells]),
        ex("face_pull", "Cable face pull", [.cable]),
        // Legs
        ex("legpress", "Leg press", [.legPress], rest: Rest.heavy, inc: 10),
        ex("legpress_high", "Leg press (feet high and wide)", [.legPress], rest: Rest.heavy, inc: 10),
        ex("smith_squat", "Smith squat", [.smith], rest: Rest.heavy, inc: 10),
        ex("goblet", "Goblet squat", [.dumbbells], rest: Rest.heavy),
        ex("db_rdl", "Dumbbell Romanian deadlift", [.dumbbells], rest: Rest.heavy),
        ex("smith_rdl", "Smith Romanian deadlift", [.smith], rest: Rest.heavy, inc: 10),
        ex("pullthrough", "Cable pull-through", [.cable]),
        ex("db_bss", "Bulgarian split squat", [.dumbbells, .bench], rest: Rest.heavy),
        ex("db_lunge", "Dumbbell walking lunge", [.dumbbells], rest: Rest.heavy),
        ex("step_up", "Bench step-up", [.bench], bw: true),
        ex("smith_split", "Smith split squat", [.smith], rest: Rest.heavy),
        ex("leg_ext", "Leg extension", [.legMachine]),
        ex("leg_curl", "Leg curl", [.legMachine]),
        ex("db_sl_rdl", "Single-leg dumbbell RDL", [.dumbbells]),
        ex("smith_thrust", "Smith hip thrust", [.smith, .bench], rest: Rest.heavy, inc: 10),
        ex("db_thrust", "Dumbbell hip thrust", [.dumbbells, .bench], rest: Rest.heavy),
        ex("kickback", "Cable glute kickback", [.cable]),
        // Calves
        ex("legmachine_calf", "Leg machine calf raise", [.legMachine], rest: Rest.short),
        ex("smith_calf", "Smith calf raise", [.smith], rest: Rest.short, inc: 10),
        ex("lp_calf", "Leg press calf raise", [.legPress], rest: Rest.short, inc: 10),
        ex("db_calf", "Single-leg dumbbell calf raise", [.dumbbells], rest: Rest.short),
        ex("bw_calf", "Bodyweight calf raise", [], rest: Rest.short, bw: true),
        // Abs
        ex("ab_crunch", "Ab machine crunch", [.abMachine]),
        ex("cable_crunch", "Kneeling cable crunch", [.cable]),
        ex("plank", "Plank", [], bw: true, timed: true),
    ]

    static let byID: [String: Exercise] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}

// MARK: - Routines

struct Slot: Hashable {
    let label: String
    let sets: Int
    let reps: String
    let candidates: [String]
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
            Slot(label: "Chest press", sets: 3, reps: "8-12", candidates: ["db_bench", "smith_bench", "cable_press", "incline_pushup"]),
            Slot(label: "Vertical pull", sets: 3, reps: "8-12", candidates: ["lat_wide", "cable_pulldown", "db_pullover"]),
            Slot(label: "Incline press", sets: 3, reps: "8-12", candidates: ["db_incline", "smith_incline", "cable_low_high"]),
            Slot(label: "Row", sets: 3, reps: "8-12", candidates: ["cable_row", "cs_db_row", "one_arm_row", "smith_row"]),
            Slot(label: "Biceps", sets: 3, reps: "10-15", candidates: ["db_curl", "cable_curl", "incline_curl"]),
            Slot(label: "Triceps", sets: 3, reps: "10-15", candidates: ["pushdown", "db_skull", "smith_cgp", "bench_dip"]),
        ]
        case .upperB: return [
            Slot(label: "Vertical pull", sets: 3, reps: "8-12", candidates: ["lat_close", "cable_pulldown", "straight_arm", "db_pullover"]),
            Slot(label: "Incline chest", sets: 3, reps: "8-12", candidates: ["smith_incline", "db_incline", "cable_low_high", "db_fly"]),
            Slot(label: "Row", sets: 3, reps: "8-12", candidates: ["cs_db_row", "cable_row", "one_arm_row", "smith_row"]),
            Slot(label: "Side delts", sets: 3, reps: "12-15", candidates: ["cable_lat_raise", "db_lat_raise", "face_pull"]),
            Slot(label: "Biceps", sets: 3, reps: "10-15", candidates: ["hammer", "cable_curl", "incline_curl", "db_curl"]),
            Slot(label: "Triceps", sets: 3, reps: "10-15", candidates: ["db_skull", "pushdown", "bench_dip", "smith_cgp"]),
        ]
        case .lowerA: return [
            Slot(label: "Squat pattern", sets: 3, reps: "8-12", candidates: ["legpress", "smith_squat", "goblet"]),
            Slot(label: "Hinge", sets: 3, reps: "8-12", candidates: ["db_rdl", "smith_rdl", "pullthrough"]),
            Slot(label: "Single leg", sets: 3, reps: "8-12", candidates: ["db_bss", "db_lunge", "step_up", "smith_split"]),
            Slot(label: "Quads", sets: 3, reps: "10-15", candidates: ["leg_ext", "goblet", "db_lunge"]),
            Slot(label: "Calves", sets: 3, reps: "12-20", candidates: ["legmachine_calf", "smith_calf", "lp_calf", "db_calf", "bw_calf"]),
            Slot(label: "Abs", sets: 3, reps: "10-15", candidates: ["ab_crunch", "cable_crunch", "plank"]),
        ]
        case .lowerB: return [
            Slot(label: "Hinge", sets: 3, reps: "8-12", candidates: ["smith_rdl", "db_rdl", "pullthrough"]),
            Slot(label: "Squat pattern", sets: 3, reps: "8-12", candidates: ["legpress_high", "smith_squat", "goblet"]),
            Slot(label: "Hamstrings", sets: 3, reps: "10-15", candidates: ["leg_curl", "db_sl_rdl", "pullthrough"]),
            Slot(label: "Glutes", sets: 3, reps: "8-12", candidates: ["smith_thrust", "db_thrust", "kickback"]),
            Slot(label: "Calves", sets: 3, reps: "12-20", candidates: ["lp_calf", "legmachine_calf", "smith_calf", "db_calf", "bw_calf"]),
            Slot(label: "Abs", sets: 3, reps: "10-15", candidates: ["cable_crunch", "ab_crunch", "plank"]),
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
