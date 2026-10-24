import Foundation
import SwiftUI
import WidgetKit

// MARK: - Saved data

struct SetLog: Codable, Hashable, Identifiable {
    var id = UUID()
    var weight: String = ""
    var reps: String = ""
    var done = false
    /// Reps from last time, shown as the placeholder.
    var hint: String = ""
}

struct ItemLog: Codable, Hashable, Identifiable {
    var id = UUID()
    var slot: Int
    var exerciseID: String?
    var skipped = false
    var manual = false
    var sets: [SetLog] = []

    var hasDone: Bool { sets.contains { $0.done } }
    var allDone: Bool { !sets.isEmpty && sets.allSatisfy { $0.done } }
    var doneCount: Int { sets.filter { $0.done }.count }
}

struct Session: Codable, Hashable {
    var routine: RoutineID
    var start: Date
    var items: [ItemLog]
}

struct HistorySet: Codable, Hashable {
    var weight: Double
    var reps: Int
}

struct HistoryItem: Codable, Hashable {
    var exerciseID: String
    var name: String
    var sets: [HistorySet]
}

struct HistoryEntry: Codable, Hashable, Identifiable {
    var id: String
    var date: Date
    var routine: RoutineID
    var duration: TimeInterval
    var items: [HistoryItem]

    var setCount: Int {
        items.reduce(0) { total, item in total + item.sets.count }
    }

    var volume: Double {
        items.reduce(0) { total, item in
            total + item.sets.reduce(0) { sum, s in sum + s.weight * Double(s.reps) }
        }
    }

    var minutes: Int { max(1, Int((duration / 60).rounded())) }
}

struct AppData: Codable {
    var open: Set<Equipment> = Set(Equipment.allCases)
    var hidden: Set<String> = []
    var history: [HistoryEntry] = []
    var session: Session? = nil
    var overrides: [String: Prescription] = [:]
    var selectedRoutine: RoutineID? = nil
    var healthViaShortcut = false
    var shortcutName = "Ironlog to Health"

    init() {}

    // Tolerates missing keys so older saves keep loading as fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppData()
        open = try c.decodeIfPresent(Set<Equipment>.self, forKey: .open) ?? d.open
        hidden = try c.decodeIfPresent(Set<String>.self, forKey: .hidden) ?? d.hidden
        history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? d.history
        session = try c.decodeIfPresent(Session.self, forKey: .session)
        overrides = try c.decodeIfPresent([String: Prescription].self, forKey: .overrides) ?? d.overrides
        selectedRoutine = try c.decodeIfPresent(RoutineID.self, forKey: .selectedRoutine)
        healthViaShortcut = try c.decodeIfPresent(Bool.self, forKey: .healthViaShortcut) ?? d.healthViaShortcut
        shortcutName = try c.decodeIfPresent(String.self, forKey: .shortcutName) ?? d.shortcutName
    }
}

struct EquipmentChange: Identifiable {
    let id = UUID()
    let itemID: UUID
    let from: String?
}

struct Suggestion {
    var date: Date
    var sets: [HistorySet]
    var hitTop: Bool
    var nextWeight: Double?
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Store

@MainActor
final class Store: ObservableObject {
    @Published var data: AppData {
        didSet { scheduleSave() }
    }
    /// Swaps made since the equipment sheet was opened.
    @Published var changes: [EquipmentChange] = []
    /// Shown as a summary sheet after finishing.
    @Published var lastFinished: HistoryEntry?

    private var saveTask: Task<Void, Never>?

    init() {
        data = Store.load()
    }

    // MARK: Persistence

    static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.groupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ironlog.json")
    }

    private static func load() -> AppData {
        guard let raw = try? Data(contentsOf: fileURL) else { return AppData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AppData.self, from: raw)) ?? AppData()
    }

    private static func write(_ data: AppData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = data
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            Store.write(snapshot)
        }
    }

    func saveNow() {
        saveTask?.cancel()
        Store.write(data)
    }

    // MARK: Lookups

    func prescription(_ id: String) -> Prescription {
        if let custom = data.overrides[id] { return custom }
        return Library.byID[id]?.preset ?? Preset.isolation
    }

    func isCustom(_ id: String) -> Bool { data.overrides[id] != nil }

    func setPrescription(_ p: Prescription, for id: String) {
        var fixed = p
        if fixed.high < fixed.low { fixed.high = fixed.low }
        if fixed == Library.byID[id]?.preset {
            data.overrides[id] = nil
        } else {
            data.overrides[id] = fixed
        }
        // Rebuild unstarted sets for this exercise in the current workout.
        if var s = data.session {
            for k in s.items.indices where s.items[k].exerciseID == id && !s.items[k].hasDone {
                s.items[k].sets = buildSets(id)
            }
            data.session = s
        }
    }

    func isAvailable(_ id: String) -> Bool {
        guard let ex = Library.byID[id] else { return false }
        return Generator.isAvailable(ex, open: data.open, hidden: data.hidden)
    }

    func missingReason(_ id: String) -> String {
        if data.hidden.contains(id) { return "Hidden" }
        guard let ex = Library.byID[id] else { return "" }
        let missing = ex.equipment.filter { !data.open.contains($0) }.map { $0.name }
        return missing.isEmpty ? "" : "Taken: " + missing.joined(separator: ", ")
    }

    var nextRoutine: RoutineID { RoutineID.next(after: data.history.first?.routine) }
    var todayRoutine: RoutineID { data.selectedRoutine ?? nextRoutine }

    func plan(_ routine: RoutineID) -> [Exercise?] {
        Generator.plan(for: routine, open: data.open, hidden: data.hidden)
    }

    func lastDone(_ routine: RoutineID) -> Date? {
        data.history.first { $0.routine == routine }?.date
    }

    // MARK: Progression

    func lastPerformance(_ id: String) -> (date: Date, sets: [HistorySet])? {
        for entry in data.history {
            if let item = entry.items.first(where: { $0.exerciseID == id }), !item.sets.isEmpty {
                return (entry.date, item.sets)
            }
        }
        return nil
    }

    /// Double progression: once every set reached the top of the range, suggest the next weight.
    func suggestion(_ id: String) -> Suggestion? {
        guard let ex = Library.byID[id], let last = lastPerformance(id) else { return nil }
        let p = prescription(id)
        let top = last.sets.map { $0.weight }.max() ?? 0
        let hit = !ex.timed && top > 0 && last.sets.count >= p.sets && last.sets.allSatisfy { $0.reps >= p.high }
        return Suggestion(date: last.date, sets: last.sets, hitTop: hit, nextWeight: hit ? top + ex.increment : nil)
    }

    func lastLine(_ id: String) -> String {
        guard let ex = Library.byID[id], let s = suggestion(id) else { return "First time logging this one" }
        let sets = s.sets.map { set -> String in
            if ex.timed { return "\(set.reps)s" }
            return set.weight > 0 ? "\(Store.fmt(set.weight))×\(set.reps)" : "\(set.reps)"
        }.joined(separator: ", ")
        var line = "Last \(s.date.formatted(.dateTime.month(.abbreviated).day())): \(sets)"
        if let next = s.nextWeight { line += " · try \(Store.fmt(next))" }
        return line
    }

    static func fmt(_ w: Double) -> String {
        w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }

    func buildSets(_ id: String) -> [SetLog] {
        let p = prescription(id)
        let sug = suggestion(id)
        return (0..<max(1, p.sets)).map { i in
            var s = SetLog()
            if let sug {
                var prev: HistorySet? = nil
                if i < sug.sets.count { prev = sug.sets[i] } else { prev = sug.sets.last }
                if let next = sug.nextWeight {
                    s.weight = Store.fmt(next)
                } else if let prev, prev.weight > 0 {
                    s.weight = Store.fmt(prev.weight)
                }
                if let prev { s.hint = String(prev.reps) }
            }
            return s
        }
    }

    // MARK: Workout

    func startWorkout() {
        let routine = todayRoutine
        let items = plan(routine).enumerated().map { i, ex in
            ItemLog(slot: i, exerciseID: ex?.id, sets: ex.map { buildSets($0.id) } ?? [])
        }
        data.session = Session(routine: routine, start: Date(), items: items)
    }

    private func mutateItem(_ i: Int, _ body: (inout ItemLog) -> Void) {
        guard var s = data.session, s.items.indices.contains(i) else { return }
        body(&s.items[i])
        data.session = s
    }

    func binding(_ i: Int, _ j: Int, _ kp: WritableKeyPath<SetLog, String>) -> Binding<String> {
        Binding(
            get: { self.data.session?.items[safe: i]?.sets[safe: j]?[keyPath: kp] ?? "" },
            set: { value in
                self.mutateItem(i) { item in
                    if item.sets.indices.contains(j) { item.sets[j][keyPath: kp] = value }
                }
            }
        )
    }

    /// Returns true when a set was just completed (start the rest timer).
    @discardableResult
    func toggleSet(_ i: Int, _ j: Int) -> Bool {
        var completed = false
        mutateItem(i) { item in
            guard item.sets.indices.contains(j) else { return }
            if item.sets[j].done {
                item.sets[j].done = false
                return
            }
            if item.sets[j].reps.isEmpty { item.sets[j].reps = item.sets[j].hint }
            guard !item.sets[j].reps.isEmpty else { return }
            item.sets[j].done = true
            completed = true
        }
        return completed
    }

    func addSet(_ i: Int) {
        mutateItem(i) { item in
            let last = item.sets.last
            item.sets.append(SetLog(weight: last?.weight ?? "", hint: last?.hint ?? ""))
        }
    }

    func removeLastSet(_ i: Int) {
        mutateItem(i) { item in
            if item.sets.count > 1, item.sets.last?.done == false { item.sets.removeLast() }
        }
    }

    func setSkipped(_ i: Int, _ skipped: Bool) {
        mutateItem(i) { $0.skipped = skipped }
    }

    /// Swaps the exercise in a slot. If sets were already logged, those stay on the
    /// old exercise and the new one picks up the remaining sets.
    func swap(_ i: Int, to id: String) {
        guard var s = data.session, s.items.indices.contains(i) else { return }
        var item = s.items[i]
        if item.hasDone {
            let done = item.sets.filter { $0.done }
            let remaining = max(1, prescription(id).sets - done.count)
            item.sets = done
            s.items[i] = item
            let fresh = ItemLog(slot: item.slot, exerciseID: id, manual: true,
                                sets: Array(buildSets(id).prefix(remaining)))
            s.items.insert(fresh, at: i + 1)
        } else {
            item.exerciseID = id
            item.manual = true
            item.skipped = false
            item.sets = buildSets(id)
            s.items[i] = item
        }
        data.session = s
        changes.removeAll()
    }

    func hide(_ i: Int) {
        guard let id = data.session?.items[safe: i]?.exerciseID else { return }
        data.hidden.insert(id)
        mutateItem(i) { $0.manual = false }
        reconcile()
    }

    func unhide(_ id: String) {
        data.hidden.remove(id)
    }

    func toggleEquipment(_ eq: Equipment) {
        if data.open.contains(eq) { data.open.remove(eq) } else { data.open.insert(eq) }
        reconcile()
    }

    /// Re-picks anything not yet started after equipment changes.
    func reconcile() {
        guard var s = data.session else { return }
        for idx in s.items.indices {
            let item = s.items[idx]
            if item.hasDone { continue }
            if item.manual, let ex = item.exerciseID, isAvailable(ex) { continue }
            let used = Set(s.items.enumerated().filter { $0.offset != idx }.compactMap { $0.element.exerciseID })
            let slot = s.routine.slots[item.slot]
            let pick = slot.candidates.first { isAvailable($0) && !used.contains($0) }
            if pick != item.exerciseID {
                if !changes.contains(where: { $0.itemID == item.id }) {
                    changes.append(EquipmentChange(itemID: item.id, from: item.exerciseID))
                }
                s.items[idx].exerciseID = pick
                s.items[idx].manual = false
                s.items[idx].skipped = false
                s.items[idx].sets = pick.map { buildSets($0) } ?? []
            }
        }
        data.session = s
    }

    /// What to show on the lock screen after a set in item `i` is done.
    func progressInfo(after i: Int) -> (next: String, detail: String) {
        guard let s = data.session else { return ("", "") }
        if let item = s.items[safe: i], let id = item.exerciseID, let ex = Library.byID[id], !item.allDone {
            return (ex.name, "Set \(item.doneCount + 1) of \(item.sets.count)")
        }
        for item in s.items.dropFirst(i + 1) {
            if let id = item.exerciseID, let ex = Library.byID[id], !item.skipped, !item.allDone {
                return (ex.name, "Up next")
            }
        }
        for item in s.items {
            if let id = item.exerciseID, let ex = Library.byID[id], !item.skipped, !item.allDone {
                return (ex.name, "Still to do")
            }
        }
        return ("All sets done", "Finish when ready")
    }

    func finishWorkout() {
        guard let s = data.session else { return }
        let items: [HistoryItem] = s.items.compactMap { item in
            guard let id = item.exerciseID, !item.skipped, let ex = Library.byID[id] else { return nil }
            let sets = item.sets.filter { $0.done }.map {
                HistorySet(weight: Double($0.weight) ?? 0, reps: Int($0.reps) ?? 0)
            }
            return sets.isEmpty ? nil : HistoryItem(exerciseID: id, name: ex.name, sets: sets)
        }
        data.session = nil
        data.selectedRoutine = nil
        guard !items.isEmpty else { return }
        let entry = HistoryEntry(id: UUID().uuidString, date: s.start, routine: s.routine,
                                 duration: Date().timeIntervalSince(s.start), items: items)
        data.history.insert(entry, at: 0)
        syncWidget()
        saveNow()
        lastFinished = entry
    }

    func discard() {
        data.session = nil
    }

    func deleteHistory(_ id: String) {
        data.history.removeAll { $0.id == id }
        syncWidget()
    }

    func eraseAll() {
        data = AppData()
        syncWidget()
    }

    func syncWidget() {
        if let last = data.history.first {
            SharedStore.defaults.set(last.routine.rawValue, forKey: "lastRoutine")
            SharedStore.defaults.set(last.date, forKey: "lastDate")
        } else {
            SharedStore.defaults.removeObject(forKey: "lastRoutine")
            SharedStore.defaults.removeObject(forKey: "lastDate")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Apple Health through Shortcuts

    func healthShortcutURL(minutes: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "shortcuts"
        c.host = "x-callback-url"
        c.path = "/run-shortcut"
        c.queryItems = [
            URLQueryItem(name: "name", value: data.shortcutName),
            URLQueryItem(name: "input", value: "text"),
            URLQueryItem(name: "text", value: String(minutes)),
            URLQueryItem(name: "x-success", value: "ironlog://health-saved"),
        ]
        return c.url
    }

    // MARK: Backup

    struct ExportFile: Codable {
        var app = "ironlog-ios"
        var exported = Date()
        var history: [HistoryEntry]
        var hidden: Set<String>
        var open: Set<Equipment>
        var overrides: [String: Prescription]
    }

    func exportFileURL() -> URL? {
        let file = ExportFile(history: data.history, hidden: data.hidden, open: data.open, overrides: data.overrides)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? encoder.encode(file) else { return nil }
        let stamp = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Ironlog-backup-\(stamp).json")
        do {
            try raw.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    enum ImportError: LocalizedError {
        case unreadable
        var errorDescription: String? { "That file isn't an Ironlog backup." }
    }

    /// Imports either a backup from this app or one exported from the web version.
    /// Returns how many workouts were added.
    func importBackup(_ raw: Data) throws -> Int {
        let existing = Set(data.history.map { $0.id })
        var added: [HistoryEntry] = []

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let native = try? decoder.decode(ExportFile.self, from: raw), native.app == "ironlog-ios" {
            added = native.history.filter { !existing.contains($0.id) }
            data.hidden.formUnion(native.hidden)
            for (k, v) in native.overrides where data.overrides[k] == nil { data.overrides[k] = v }
        } else {
            guard let obj = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
                  (obj["app"] as? String) == "ironlog",
                  let history = obj["history"] as? [[String: Any]]
            else { throw ImportError.unreadable }

            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let iso = ISO8601DateFormatter()

            for h in history {
                guard let id = h["id"] as? String, !existing.contains(id),
                      let dateText = h["date"] as? String,
                      let date = isoFrac.date(from: dateText) ?? iso.date(from: dateText),
                      let day = h["day"] as? String, let routine = RoutineID(rawValue: day)
                else { continue }
                let duration = ((h["dur"] as? Double) ?? 0) / 1000
                let rawItems = h["items"] as? [[String: Any]] ?? []
                let items: [HistoryItem] = rawItems.compactMap { it in
                    guard let exID = it["ex"] as? String else { return nil }
                    let rawSets = it["sets"] as? [[String: Any]] ?? []
                    let sets: [HistorySet] = rawSets.compactMap { s in
                        guard (s["done"] as? Bool) == true else { return nil }
                        let w = Double("\(s["w"] ?? "")") ?? 0
                        let r = Int("\(s["r"] ?? "")") ?? 0
                        return HistorySet(weight: w, reps: r)
                    }
                    if sets.isEmpty { return nil }
                    let name = (it["name"] as? String) ?? Library.byID[exID]?.name ?? exID
                    return HistoryItem(exerciseID: exID, name: name, sets: sets)
                }
                if !items.isEmpty {
                    added.append(HistoryEntry(id: id, date: date, routine: routine, duration: duration, items: items))
                }
            }
            if let banned = obj["banned"] as? [String] {
                data.hidden.formUnion(banned.filter { Library.byID[$0] != nil })
            }
        }

        data.history = (data.history + added).sorted { $0.date > $1.date }
        syncWidget()
        return added.count
    }
}
