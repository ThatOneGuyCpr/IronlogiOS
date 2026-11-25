import SwiftUI

// MARK: - Library

/// The plan sheet: library of programs plus build-your-own.
struct ProgramsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var filter = "All"

    private let filters = ["All", "Balanced", "Muscle focus", "Strength", "Short on time"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pick a starting point. You can change days and focus after.")
                        .font(Theme.font(size: 14))
                        .foregroundStyle(Theme.sub)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(filters, id: \.self) { f in
                                Button(f) { withAnimation(.snappy) { filter = f } }
                                    .font(Theme.font(size: 13, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(filter == f ? Theme.ink : Theme.card, in: Capsule())
                                    .foregroundStyle(filter == f ? Theme.bg : Theme.ink)
                                    .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                                    .buttonStyle(.plain)
                                    .accessibilityAddTraits(filter == f ? .isSelected : [])
                            }
                        }
                    }

                    NavigationLink {
                        PlanBuilderView(start: builderStart, allowedDays: Array(2...6), onDone: { dismiss() })
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(Theme.font(size: 18, weight: .semibold))
                                .frame(width: 40, height: 40)
                                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.radius(13), style: .continuous))
                                .foregroundStyle(Theme.accentText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Build your own").font(Theme.font(size: 16, weight: .bold)).foregroundStyle(Theme.ink)
                                Text("Set days per week and which muscles to grow")
                                    .font(Theme.font(size: 13))
                                    .foregroundStyle(Theme.sub)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(Theme.font(size: 13, weight: .bold)).foregroundStyle(Theme.sub)
                        }
                        .padding(14)
                        .background(Theme.card.opacity(0.6), in: RoundedRectangle(cornerRadius: Theme.radius(20), style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius(20), style: .continuous).strokeBorder(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                    }
                    .buttonStyle(.plain)

                    ForEach(ProgramID.library.filter { filter == "All" || $0.tags.contains(filter) }) { p in
                        NavigationLink {
                            ProgramDetailView(program: p, onDone: { dismiss() })
                        } label: {
                            ProgramCard(program: p, current: store.data.plan.program == p)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background { SkyBackground() }
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var builderStart: Plan {
        var p = store.data.plan
        p.program = .custom
        return p
    }
}

private struct ProgramCard: View {
    let program: ProgramID
    let current: Bool

    var body: some View {
        let plan = Plan.standard(program)
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(program.name).font(Theme.font(size: 16, weight: .bold)).foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                if current {
                    Text("CURRENT")
                        .font(Theme.font(size: 10, weight: .heavy)).tracking(0.8)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(Theme.accentInk)
                }
                Text(program.daysLabel)
                    .font(Theme.font(size: 12, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.accentSoft, in: Capsule())
                    .foregroundStyle(Theme.accentText)
            }
            Text(program.blurb)
                .font(Theme.font(size: 13))
                .foregroundStyle(Theme.sub)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            WeekPattern(plan: plan, compact: true)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(20), style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius(20), style: .continuous).stroke(current ? Theme.accent : Theme.cardBorder, lineWidth: current ? 1.5 : 1))
        .accessibilityElement(children: .combine)
    }
}

/// Monday-to-Sunday cells with the plan's workouts on its days.
struct WeekPattern: View {
    let plan: Plan
    var compact = false

    private let order = [2, 3, 4, 5, 6, 7, 1]
    private let letters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let cells = assignments
        HStack(spacing: compact ? 4 : 5) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    if !compact {
                        Text(letters[i]).font(Theme.font(size: 11, weight: .semibold)).foregroundStyle(Theme.sub)
                    }
                    Text(cells[i]?.glyph ?? "")
                        .font(Theme.font(size: compact ? 10 : 11, weight: .heavy))
                        .frame(maxWidth: .infinity, minHeight: compact ? 22 : 30)
                        .background(cells[i] == nil ? Theme.faint : Theme.accent, in: RoundedRectangle(cornerRadius: compact ? 7 : 10, style: .continuous))
                        .foregroundStyle(Theme.accentInk)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(plan.weekdayText)
    }

    private var assignments: [RoutineID?] {
        let days = plan.weekdays ?? Plan.defaultWeekdays(plan.days)
        let rotation = plan.rotation
        var out: [RoutineID?] = Array(repeating: nil, count: 7)
        var k = 0
        for (i, wd) in order.enumerated() where days.contains(wd) && !rotation.isEmpty {
            out[i] = rotation[k % rotation.count]
            k += 1
        }
        return out
    }
}

// MARK: - Program preview

struct ProgramDetailView: View {
    @EnvironmentObject private var store: Store
    let program: ProgramID
    var onDone: () -> Void
    @State private var days: Int
    @State private var intensity: Intensity = .normal
    @State private var seeded = false

    init(program: ProgramID, onDone: @escaping () -> Void) {
        self.program = program
        self.onDone = onDone
        _days = State(initialValue: program.defaultDays)
    }

    var body: some View {
        let plan = Plan.standard(program, days: days, weekdays: .some(store.data.plan.weekdays == nil ? nil : Plan.defaultWeekdays(days)))
            .with(intensity)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(program.blurb)
                    .font(Theme.font(size: 15))
                    .foregroundStyle(Theme.sub)

                if program.dayOptions.count > 1 {
                    Picker("Days per week", selection: $days) {
                        ForEach(program.dayOptions, id: \.self) { Text("\($0) days").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                IntensityPicker(plan: plan, selection: $intensity)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionTitle("Your week")
                        Spacer()
                        Text(plan.isFixed ? plan.weekdayText : "Any \(plan.days) days")
                            .font(Theme.font(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accentText)
                    }
                    WeekPattern(plan: plan)
                    Text(sessionLine(plan))
                        .font(Theme.font(size: 12))
                        .foregroundStyle(Theme.sub)
                }
                .glacierCard(padding: 14)

                SetsCard(plan: plan)

                if let note = program.note ?? warning(plan) {
                    Label(note, systemImage: "info.circle")
                        .font(Theme.font(size: 13))
                        .foregroundStyle(Theme.ink)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.promptBg, in: RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous))
                }

                HStack(spacing: 10) {
                    Button("Use \(program.name), \(days) days") {
                        store.applyPlan(plan)
                        onDone()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    NavigationLink("Tune") {
                        PlanBuilderView(start: plan, allowedDays: program.dayOptions, onDone: onDone)
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .frame(width: 96)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
        .background { SkyBackground() }
        .onAppear {
            // Keep the intensity you already train at when browsing programs.
            guard !seeded else { return }
            seeded = true
            intensity = store.data.plan.intensity
        }
        .navigationTitle(program.name)
    }

    private func sessionLine(_ plan: Plan) -> String {
        let counts = plan.rotation.map { store.plan($0).compactMap { $0 }.count }
        let avg = counts.isEmpty ? 0 : counts.reduce(0, +) / counts.count
        return "\(plan.days.counted("workout")) a week, about \(avg) exercises and \(minutes(plan)) min each."
    }

    private func minutes(_ plan: Plan) -> Int {
        PlanMath.minutes(plan, store: store)
    }

    private func warning(_ plan: Plan) -> String? {
        let sets = store.weeklySets(for: plan)
        let low = Muscle.allCases.filter { (sets[$0] ?? 0) < 6 && $0 != .abs }
        if low.count >= 4 { return "Several muscles land under 6 sets a week. Fine for holding steady; add a day to keep building." }
        return nil
    }
}

/// Normal, High or Max, each with the session length it works out to.
struct IntensityPicker: View {
    @EnvironmentObject private var store: Store
    let plan: Plan
    @Binding var selection: Intensity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INTENSITY")
                .font(Theme.font(size: 12, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.sub)
            HStack(spacing: 6) {
                ForEach(Intensity.allCases) { level in
                    let on = selection == level
                    Button {
                        withAnimation(.snappy) { selection = level }
                    } label: {
                        VStack(spacing: 2) {
                            Text(level.name)
                                .font(Theme.font(size: 15, weight: .bold))
                            Text("~\(PlanMath.minutes(plan.with(level), store: store)) min")
                                .font(Theme.font(size: 12, weight: .semibold))
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(on ? Theme.accent : Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous))
                        .foregroundStyle(on ? Theme.accentInk : Theme.ink)
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level.name), about \(PlanMath.minutes(plan.with(level), store: store)) minutes")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            Text(selection.blurb)
                .font(Theme.font(size: 13))
                .foregroundStyle(Theme.sub)
                .fixedSize(horizontal: false, vertical: true)
            if selection == .max {
                Text("Your first three lifts each day and any muscle you're growing keep every set.")
                    .font(Theme.font(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accentText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum PlanMath {
    @MainActor
    static func minutes(_ plan: Plan, store: Store) -> Int {
        let per = plan.rotation.map { store.estimatedMinutes($0, plan: plan) }
        guard !per.isEmpty else { return 0 }
        let avg = Double(per.reduce(0, +)) / Double(per.count)
        return max(5, Int((avg / 5).rounded()) * 5)
    }
}

/// Weekly sets per muscle, compared with the current plan. 10-20 is shaded as the growth range.
struct SetsCard: View {
    @EnvironmentObject private var store: Store
    let plan: Plan

    var body: some View {
        let sets = store.weeklySets(for: plan)
        let now = store.weeklySets(for: store.data.plan)
        let same = plan == store.data.plan
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Sets per muscle, per week")
                Spacer()
                Text("shaded: 10–20 to grow")
                    .font(Theme.font(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }
            ForEach(Muscle.allCases) { m in
                let v = sets[m] ?? 0
                let diff = v - (now[m] ?? 0)
                HStack(spacing: 8) {
                    Text(m.name)
                        .font(Theme.font(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 92, alignment: .leading)
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.faint)
                            Rectangle().fill(Theme.accentSoft)
                                .frame(width: w * 10 / 24)
                                .offset(x: w * 10 / 24)
                            Capsule().fill(v >= 10 ? Theme.accent : Theme.accent.opacity(0.55))
                                .frame(width: max(4, w * min(1, CGFloat(v) / 24)))
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 10)
                    Text("\(v)")
                        .font(Theme.num(12, .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 22, alignment: .trailing)
                    Text(same ? "" : diff == 0 ? "same" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                        .font(Theme.font(size: 11, weight: .bold))
                        .foregroundStyle(diff < 0 ? Theme.warn : Theme.sub)
                        .frame(width: 36, alignment: .leading)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(m.name), \(v) sets a week" + (same || diff == 0 ? "" : ", \(diff > 0 ? "up" : "down") \(abs(diff)) from now"))
            }
            if !same {
                Text("Compared with your current plan.")
                    .font(Theme.font(size: 11))
                    .foregroundStyle(Theme.sub)
            }
        }
        .glacierCard(padding: 14)
    }
}

// MARK: - Builder

struct PlanBuilderView: View {
    @EnvironmentObject private var store: Store
    let allowedDays: [Int]
    var onDone: () -> Void
    @State private var plan: Plan

    init(start: Plan, allowedDays: [Int], onDone: @escaping () -> Void) {
        var p = start
        if !allowedDays.contains(p.days) { p.days = allowedDays.contains(3) ? 3 : (allowedDays.first ?? 4) }
        if let wd = p.weekdays, wd.count != p.days { p.weekdays = Plan.defaultWeekdays(p.days) }
        self.allowedDays = allowedDays
        self.onDone = onDone
        _plan = State(initialValue: p)
    }

    private let order = [2, 3, 4, 5, 6, 7, 1]
    private let letters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                daysSection
                IntensityPicker(plan: plan, selection: $plan.intensity)
                whenSection
                focusSection
                SetsCard(plan: plan)
                Button("Save plan") {
                    store.applyPlan(plan)
                    onDone()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!valid)
                .opacity(valid ? 1 : 0.5)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
        .background { SkyBackground() }
        .navigationTitle(plan.program == .custom ? "Your plan" : plan.program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var valid: Bool {
        guard let wd = plan.weekdays else { return true }
        return wd.count == plan.days
    }

    // MARK: Days

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DAYS PER WEEK")
                .font(Theme.font(size: 12, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.sub)
            HStack(spacing: 6) {
                ForEach(allowedDays, id: \.self) { n in
                    Button {
                        withAnimation(.snappy) {
                            plan.days = n
                            if plan.weekdays != nil { plan.weekdays = Plan.defaultWeekdays(n) }
                        }
                    } label: {
                        Text("\(n)")
                            .font(Theme.num(18))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(plan.days == n ? Theme.accent : Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous))
                            .foregroundStyle(plan.days == n ? Theme.accentInk : Theme.ink)
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius(14), style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(n) days")
                    .accessibilityAddTraits(plan.days == n ? .isSelected : [])
                }
            }
            Text("\(plan.splitName) · about \(PlanMath.minutes(plan, store: store)) min a session")
                .font(Theme.font(size: 13, weight: .semibold))
                .foregroundStyle(Theme.sub)
        }
    }

    // MARK: When

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("When", selection: Binding(
                get: { plan.weekdays != nil },
                set: { fixed in withAnimation(.snappy) { plan.weekdays = fixed ? Plan.defaultWeekdays(plan.days) : nil } }
            )) {
                Text("Set days").tag(true)
                Text("Whenever I can").tag(false)
            }
            .pickerStyle(.segmented)

            if let wd = plan.weekdays {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let day = order[i]
                        let on = wd.contains(day)
                        Button {
                            toggle(day)
                        } label: {
                            Text(letters[i])
                                .font(Theme.font(size: 14, weight: .heavy))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(on ? Theme.accent : Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius(12), style: .continuous))
                                .foregroundStyle(on ? Theme.accentInk : Theme.sub)
                                .overlay(RoundedRectangle(cornerRadius: Theme.radius(12), style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Plan.weekdayNames[day])
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                Text(wd.count == plan.days ? "Other days show as rest days." : "Pick \(plan.days) days (\(wd.count) picked).")
                    .font(Theme.font(size: 12))
                    .foregroundStyle(wd.count == plan.days ? Theme.sub : Theme.warn)
            } else {
                Text("No set days. The week counts up to \(plan.days) and the next workout waits for you.")
                    .font(Theme.font(size: 12))
                    .foregroundStyle(Theme.sub)
            }
        }
    }

    private func toggle(_ day: Int) {
        guard var wd = plan.weekdays else { return }
        if let i = wd.firstIndex(of: day) { wd.remove(at: i) } else { wd.append(day) }
        // In your own plan, picking days sets the count too.
        if plan.program == .custom, allowedDays.contains(wd.count) { plan.days = wd.count }
        plan.weekdays = wd
    }

    // MARK: Focus

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("Focus")
                Spacer()
                Text(plan.growCount >= 3 ? "Grow up to 3 at once" : "Grow adds a set · Light takes one off")
                    .font(Theme.font(size: 12, weight: .semibold))
                    .foregroundStyle(plan.growCount >= 3 ? Theme.warn : Theme.sub)
            }
            .padding(.bottom, 6)
            ForEach(Muscle.allCases) { m in
                HStack(spacing: 8) {
                    Text(m.name)
                        .font(Theme.font(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 4)
                    HStack(spacing: 2) {
                        ForEach(Focus.allCases) { f in
                            let on = plan.focus(for: m) == f
                            let blocked = f == .grow && !on && plan.growCount >= 3
                            Button {
                                withAnimation(.snappy) { plan.focus[m.rawValue] = f == .keep ? nil : f }
                            } label: {
                                Text(f.label)
                                    .font(Theme.font(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 30)
                                    .background(on ? (f == .grow ? Theme.accent : Theme.card) : Color.clear, in: RoundedRectangle(cornerRadius: Theme.radius(8), style: .continuous))
                                    .foregroundStyle(on ? (f == .grow ? Theme.accentInk : Theme.ink) : (blocked ? Theme.sub.opacity(0.4) : Theme.sub))
                            }
                            .buttonStyle(.plain)
                            .disabled(blocked)
                            .accessibilityLabel("\(m.name): \(f.label)")
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    .padding(2)
                    .background(Theme.chip, in: RoundedRectangle(cornerRadius: Theme.radius(10), style: .continuous))
                }
                .padding(.vertical, 5)
                .overlay(alignment: .top) { Rectangle().fill(Theme.faint).frame(height: 1) }
            }
        }
        .glacierCard(padding: 14)
    }
}
