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
    /// Paired with the next item as a superset.
    var superset = false

    enum CodingKeys: String, CodingKey {
        case id, slot, exerciseID, skipped, manual, sets, superset
    }

    var hasDone: Bool { sets.contains { $0.done } }
    var allDone: Bool { !sets.isEmpty && sets.allSatisfy { $0.done } }
    var doneCount: Int { sets.filter { $0.done }.count }
}

extension ItemLog {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        slot = try c.decodeIfPresent(Int.self, forKey: .slot) ?? 0
        exerciseID = try c.decodeIfPresent(String.self, forKey: .exerciseID)
        skipped = try c.decodeIfPresent(Bool.self, forKey: .skipped) ?? false
        manual = try c.decodeIfPresent(Bool.self, forKey: .manual) ?? false
        sets = try c.decodeIfPresent([SetLog].self, forKey: .sets) ?? []
        superset = try c.decodeIfPresent(Bool.self, forKey: .superset) ?? false
    }
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
    /// Weight to load next time, set when you accept a move-up prompt.
    var pendingWeight: [String: Double] = [:]
    /// Move-up prompts dismissed until the exercise reaches this many sessions.
    var snoozed: [String: Int] = [:]
    var appearance: String = "system"
    var weeklyTarget: Int = 4
    /// Per-exercise notes (seat height, pin, grip).
    var notes: [String: String] = [:]
    var supersetsByDefault = true

    init() {}

    // Tolerates missing keys so older saves keep loading as fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppData()
        open = try c.decodeIfPresent(Set<Equipment>.self, forKey: .open) ?? d.open
        hidden = try c.decodeIfPresent(Set<String>.self, forKey: .hidden) ?? d.hidden
        history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? d.history
        session = try? c.decodeIfPresent(Session.self, forKey: .session)
        overrides = try c.decodeIfPresent([String: Prescription].self, forKey: .overrides) ?? d.overrides
        selectedRoutine = try c.decodeIfPresent(RoutineID.self, forKey: .selectedRoutine)
        healthViaShortcut = try c.decodeIfPresent(Bool.self, forKey: .healthViaShortcut) ?? d.healthViaShortcut
        shortcutName = try c.decodeIfPresent(String.self, forKey: .shortcutName) ?? d.shortcutName
        pendingWeight = try c.decodeIfPresent([String: Double].self, forKey: .pendingWeight) ?? d.pendingWeight
        snoozed = try c.decodeIfPresent([String: Int].self, forKey: .snoozed) ?? d.snoozed
        appearance = try c.decodeIfPresent(String.self, forKey: .appearance) ?? d.appearance
        weeklyTarget = try c.decodeIfPresent(Int.self, forKey: .weeklyTarget) ?? d.weeklyTarget
        notes = try c.decodeIfPresent([String: String].self, forKey: .notes) ?? d.notes
        supersetsByDefault = try c.decodeIfPresent(Bool.self, forKey: .supersetsByDefault) ?? d.supersetsByDefault
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
        syncWidget()
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
        if let data = try? decoder.decode(AppData.self, from: raw) { return data }
        // Never overwrite data we couldn't read: set it aside so it can be recovered.
        let stamp = Int(Date().timeIntervalSince1970)
        let aside = fileURL.deletingLastPathComponent().appendingPathComponent("ironlog-unreadable-\(stamp).json")
        try? FileManager.default.copyItem(at: fileURL, to: aside)
        return AppData()
    }

    /// Backup JSON built straight from disk, for the Shortcuts action.
    static func backupData() -> Data? {
        let data = load()
        let file = ExportFile(history: data.history, hidden: data.hidden, open: data.open,
                              overrides: data.overrides, notes: data.notes)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(file)
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
            if sug == nil, let pending = data.pendingWeight[id] {
                s.weight = Store.fmt(pending)
            }
            if let sug {
                var prev: HistorySet? = nil
                if i < sug.sets.count { prev = sug.sets[i] } else { prev = sug.sets.last }
                if let pending = data.pendingWeight[id] {
                    s.weight = Store.fmt(pending)
                } else if let next = sug.nextWeight {
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
        let slots = routine.slots
        let items = plan(routine).enumerated().map { i, ex in
            ItemLog(slot: i, exerciseID: ex?.id, sets: ex.map { buildSets($0.id) } ?? [],
                    superset: data.supersetsByDefault && slots[i].pairNext && i + 1 < slots.count)
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
        for item in items { data.pendingWeight[item.exerciseID] = nil }
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

        var snap = WidgetSnapshot()
        let cutoff = Date().addingTimeInterval(-200 * 86_400)
        snap.workouts = data.history.filter { $0.date > cutoff }.map {
            WidgetSnapshot.Workout(date: $0.date, routine: $0.routine, minutes: $0.minutes,
                                   sets: $0.setCount, volume: $0.volume)
        }
        snap.weeklyTarget = data.weeklyTarget
        snap.next = nextRoutine
        let picks = plan(nextRoutine).compactMap { $0 }
        snap.nextFirst = picks.first?.name
        snap.nextCount = picks.count
        for entry in data.history.prefix(30) {
            if let r = records(for: entry).first {
                snap.record = WidgetSnapshot.Record(name: r.name, text: r.text, date: entry.date)
                break
            }
        }
        if let ex = trendExercises().first {
            snap.trend = WidgetSnapshot.Trend(name: ex.name, weights: trend(ex.id).map { $0.weight })
        }
        if let p = stallPrompts().first {
            snap.moveUp = WidgetSnapshot.MoveUp(id: p.id, name: p.name, weight: p.weight, sessions: p.sessions, next: p.next)
        }
        snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Last time's sets for the LAST column.
    func lastSet(_ id: String, _ j: Int) -> String {
        guard let ex = Library.byID[id], let last = lastPerformance(id) else { return "–" }
        guard let s = last.sets[safe: j] ?? last.sets.last else { return "–" }
        if ex.timed { return "\(s.reps)s" }
        return s.weight > 0 ? "\(Store.fmt(s.weight)) × \(s.reps)" : "\(s.reps)"
    }

    /// Weight to suggest in the nudge chip, if any.
    func nudgeWeight(_ id: String) -> Double? {
        data.pendingWeight[id] ?? suggestion(id)?.nextWeight
    }

    // MARK: Week and progress

    var weekCalendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    func entriesThisWeek() -> [HistoryEntry] {
        guard let week = weekCalendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return data.history.filter { week.contains($0.date) }
    }

    func weekStreak() -> Int {
        let cal = weekCalendar
        guard var start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let starts = Set(data.history.compactMap { cal.dateInterval(of: .weekOfYear, for: $0.date)?.start })
        if !starts.contains(start), let prev = cal.date(byAdding: .weekOfYear, value: -1, to: start) { start = prev }
        var streak = 0
        while starts.contains(start) {
            streak += 1
            guard let prev = cal.date(byAdding: .weekOfYear, value: -1, to: start) else { break }
            start = prev
        }
        return streak
    }

    struct DayDot: Identifiable {
        let id: Int
        let letter: String
        let done: Bool
        let isToday: Bool
        let isFuture: Bool
    }

    func weekDays() -> [DayDot] {
        let cal = weekCalendar
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i in
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { return nil }
            let done = data.history.contains { cal.isDate($0.date, inSameDayAs: day) }
            let today = cal.isDateInToday(day)
            return DayDot(id: i, letter: letters[i], done: done, isToday: today, isFuture: !today && day > Date())
        }
    }

    func estimatedMinutes(_ routine: RoutineID) -> Int {
        let seconds = plan(routine).compactMap { $0 }.reduce(0) { total, ex in
            let p = prescription(ex.id)
            return total + p.sets * (45 + p.rest)
        }
        return max(5, Int((Double(seconds) / 300).rounded()) * 5)
    }

    struct StallPrompt: Identifiable {
        let id: String
        let name: String
        let weight: Double
        let sessions: Int
        let next: Double
    }

    /// Exercises stuck at the same top weight for `threshold` sessions in a row.
    func stallPrompts(threshold: Int = 6) -> [StallPrompt] {
        var seen = Set<String>()
        var out: [StallPrompt] = []
        for entry in data.history {
            for item in entry.items {
                if seen.contains(item.exerciseID) { continue }
                seen.insert(item.exerciseID)
                guard let ex = Library.byID[item.exerciseID], !ex.timed, data.pendingWeight[ex.id] == nil else { continue }
                let tops: [Double] = data.history.compactMap { e in
                    guard let it = e.items.first(where: { $0.exerciseID == ex.id }) else { return nil }
                    return it.sets.map { $0.weight }.max() ?? 0
                }
                guard let w = tops.first, w > 0 else { continue }
                let run = tops.prefix { $0 == w }.count
                if run >= threshold && tops.count >= (data.snoozed[ex.id] ?? 0) {
                    out.append(StallPrompt(id: ex.id, name: ex.name, weight: w, sessions: run, next: w + ex.increment))
                }
            }
        }
        return out
    }

    func acceptStall(_ p: StallPrompt) {
        data.pendingWeight[p.id] = p.next
        syncWidget()
    }

    func snoozeStall(_ p: StallPrompt) {
        let count = data.history.filter { $0.items.contains { $0.exerciseID == p.id } }.count
        data.snoozed[p.id] = count + 3
        syncWidget()
    }

    struct TrendPoint: Identifiable {
        let id: Int
        let date: Date
        let weight: Double
    }

    func trend(_ id: String, limit: Int = 12) -> [TrendPoint] {
        let points: [(Date, Double)] = data.history.compactMap { e in
            guard let it = e.items.first(where: { $0.exerciseID == id }) else { return nil }
            let w = it.sets.map { $0.weight }.max() ?? 0
            return w > 0 ? (e.date, w) : nil
        }
        return Array(points.prefix(limit).reversed()).enumerated().map {
            TrendPoint(id: $0.offset, date: $0.element.0, weight: $0.element.1)
        }
    }

    /// Exercises with at least two weighted sessions, most recent first.
    func trendExercises() -> [Exercise] {
        var seen = Set<String>()
        var out: [Exercise] = []
        for entry in data.history {
            for item in entry.items where !seen.contains(item.exerciseID) {
                seen.insert(item.exerciseID)
                if let ex = Library.byID[item.exerciseID], trend(ex.id).count >= 2 { out.append(ex) }
            }
        }
        return out
    }

    // MARK: Supersets

    /// The other half of item i's superset, if it has one.
    func partner(of i: Int) -> Int? {
        guard let s = data.session, s.items.indices.contains(i) else { return nil }
        if s.items[i].superset, s.items.indices.contains(i + 1) { return i + 1 }
        if i > 0, s.items[i - 1].superset { return i - 1 }
        return nil
    }

    func toggleSuperset(_ i: Int) {
        guard var s = data.session, s.items.indices.contains(i) else { return }
        if i > 0, s.items[i - 1].superset {
            s.items[i - 1].superset = false
        } else if s.items.indices.contains(i + 1) {
            s.items[i].superset.toggle()
            if s.items[i].superset, s.items.indices.contains(i + 2) { s.items[i + 1].superset = false }
        }
        data.session = s
    }

    // MARK: Quick edits from the keyboard bar

    private func locate(_ setID: UUID) -> (Int, Int)? {
        guard let s = data.session else { return nil }
        for (i, item) in s.items.enumerated() {
            if let j = item.sets.firstIndex(where: { $0.id == setID }) { return (i, j) }
        }
        return nil
    }

    func increment(forSet setID: UUID) -> Double {
        guard let loc = locate(setID), let id = data.session?.items[loc.0].exerciseID,
              let ex = Library.byID[id] else { return 5 }
        return ex.increment
    }

    func adjustWeight(setID: UUID, by delta: Double) {
        guard let loc = locate(setID) else { return }
        mutateItem(loc.0) { item in
            let current = Double(item.sets[loc.1].weight) ?? 0
            item.sets[loc.1].weight = Store.fmt(max(0, current + delta))
        }
    }

    func adjustReps(setID: UUID, by delta: Int) {
        guard let loc = locate(setID) else { return }
        mutateItem(loc.0) { item in
            let base = Int(item.sets[loc.1].reps) ?? Int(item.sets[loc.1].hint) ?? 0
            item.sets[loc.1].reps = String(max(0, base + delta))
        }
    }

    /// Copies the previous set's weight and reps (or last session's, for set 1).
    func copyPrevious(setID: UUID) {
        guard let loc = locate(setID) else { return }
        let (i, j) = loc
        mutateItem(i) { item in
            if j > 0 {
                item.sets[j].weight = item.sets[j - 1].weight
                item.sets[j].reps = item.sets[j - 1].reps
            } else if let id = item.exerciseID, let last = lastPerformance(id)?.sets.first {
                item.sets[j].weight = last.weight > 0 ? Store.fmt(last.weight) : ""
                item.sets[j].reps = String(last.reps)
            }
        }
    }

    // MARK: Notes

    func noteBinding(_ id: String) -> Binding<String> {
        Binding(
            get: { self.data.notes[id] ?? "" },
            set: { value in
                self.data.notes[id] = value.isEmpty ? nil : value
            }
        )
    }

    // MARK: Personal records

    struct Record: Identifiable, Hashable {
        let id: String
        let exerciseID: String
        let name: String
        let text: String
    }

    /// Records set in `entry`, compared with everything logged before it.
    func records(for entry: HistoryEntry) -> [Record] {
        let older = data.history.filter { $0.date < entry.date && $0.id != entry.id }
        var out: [Record] = []
        for item in entry.items {
            guard let ex = Library.byID[item.exerciseID], !ex.timed else { continue }
            let previous = older.flatMap { e in e.items.filter { $0.exerciseID == item.exerciseID }.flatMap { $0.sets } }
            if previous.isEmpty { continue }
            let top = item.sets.map { $0.weight }.max() ?? 0
            let prevTop = previous.map { $0.weight }.max() ?? 0
            if top > 0 && top > prevTop {
                out.append(Record(id: item.exerciseID + "-w", exerciseID: item.exerciseID, name: ex.name,
                                  text: "Heaviest yet: \(Store.fmt(top)) lb"))
                continue
            }
            let reps = item.sets.filter { $0.weight >= top }.map { $0.reps }.max() ?? 0
            let prevReps = previous.filter { $0.weight >= top }.map { $0.reps }.max() ?? 0
            if reps > prevReps {
                let text = top > 0 ? "Most reps at \(Store.fmt(top)) lb: \(reps)" : "Most reps: \(reps)"
                out.append(Record(id: item.exerciseID + "-r", exerciseID: item.exerciseID, name: ex.name, text: text))
            }
        }
        return out
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
        var notes: [String: String]? = nil
    }

    func exportFileURL() -> URL? {
        let file = ExportFile(history: data.history, hidden: data.hidden, open: data.open, overrides: data.overrides, notes: data.notes)
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
            for (k, v) in native.notes ?? [:] where data.notes[k] == nil { data.notes[k] = v }
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
