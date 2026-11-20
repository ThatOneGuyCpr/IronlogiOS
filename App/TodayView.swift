import SwiftUI

/// Starts today's routine and the lock screen activity. Used by the Start button and the widgets.
@MainActor
func beginWorkout(store: Store, rest: RestController) {
    store.startWorkout()
    rest.requestNotificationPermission()
    guard let s = store.data.session else { return }
    let first = s.items.compactMap { $0.exerciseID }.first.flatMap { Library.byID[$0]?.name } ?? "Workout"
    rest.beginWorkout(routine: s.routine.title, startedAt: s.start, first: first)
}

struct TodayView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController
    @State private var showEquipment = false
    @State private var showPlans = false
    @State private var trainAnyway = false

    private var resting: Bool { store.isRestDay && !trainAnyway }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if resting {
                    restCard
                    weekCard
                    weekSoFar
                } else {
                    heroCard
                    weekCard
                    routinePicker
                    lineupCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background { SkyBackground() }
        .sheet(isPresented: $showEquipment) {
            EquipmentSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPlans) {
            ProgramsView()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                Text("Train")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Button {
                showPlans = true
            } label: {
                HStack(spacing: 5) {
                    Text(store.data.plan.name)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.sub)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .frame(height: 36)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Plan: \(store.data.plan.name). Change plan")
            Button {
                showEquipment = true
            } label: {
                Image(systemName: "dumbbell")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("What's open")
        }
    }

    // MARK: Up next

    private var heroCard: some View {
        let routine = store.todayRoutine
        let picks = store.plan(routine)
        let taken = Equipment.allCases.filter { !store.data.open.contains($0) }
        let lastText: String = {
            if let d = store.lastDone(routine) {
                return "Last done " + d.formatted(.dateTime.weekday(.abbreviated))
            }
            return "Not done yet"
        }()
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Pill(text: routine == store.nextRoutine ? "UP NEXT" : "PICKED")
                Spacer()
                Text(lastText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.sub)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.title)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(routine.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.sub)
            }
            HStack(spacing: 16) {
                meta("list.bullet", picks.compactMap { $0 }.count.counted("exercise"))
                meta("clock", "About \(store.estimatedMinutes(routine)) min")
                Button {
                    showEquipment = true
                } label: {
                    meta(taken.isEmpty ? "checkmark" : "exclamationmark.circle",
                         taken.isEmpty ? "All gear open" : "\(taken.count) taken")
                }
                .buttonStyle(.plain)
            }
            Button {
                start()
            } label: {
                Label("Start workout", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .glacierCard(radius: 28, padding: 20)
    }

    // MARK: Rest day

    private var restCard: some View {
        let next = store.nextRoutine
        let day = store.nextPlannedDate().map { $0.formatted(.dateTime.weekday(.wide)) } ?? "next time"
        return VStack(alignment: .leading, spacing: 14) {
            Pill(text: "REST DAY", fill: Theme.chip, ink: Theme.sub)
            VStack(alignment: .leading, spacing: 4) {
                Text("Recover today")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                (Text("Next up is ") + Text("\(next.title) on \(day)").bold().foregroundStyle(Theme.ink) + Text("."))
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.sub)
            }
            HStack(spacing: 12) {
                Text(next.glyph)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.sub)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Theme.sub.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
                VStack(alignment: .leading, spacing: 2) {
                    Text(next.title).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(store.plan(next).compactMap { $0 }.count.counted("exercise") + " · about \(store.estimatedMinutes(next)) min")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Theme.field, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Button("Train anyway") {
                withAnimation(.snappy) { trainAnyway = true }
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .glacierCard(radius: 28, padding: 20)
    }

    private var weekSoFar: some View {
        let planned = store.weeklySets(for: store.data.plan)
        let done = store.setsThisWeek()
        let muscles = Muscle.allCases.filter { (planned[$0] ?? 0) > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("This week so far")
                Spacer()
                Text("sets done / planned")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(muscles) { m in
                    let d = done[m] ?? 0
                    let p = max(1, planned[m] ?? 1)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(m.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        (Text("\(d)").font(Theme.num(15)) + Text(" / \(p)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.sub))
                            .foregroundStyle(Theme.ink)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.faint)
                                Capsule().fill(Theme.accent).frame(width: geo.size.width * min(1, CGFloat(d) / CGFloat(p)))
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(10)
                    .background(Theme.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .glacierCard(padding: 16)
    }

    private func meta(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Theme.sub)
        .lineLimit(1)
    }

    private func start() {
        beginWorkout(store: store, rest: rest)
    }

    // MARK: Week

    private var weekCard: some View {
        let done = store.entriesThisWeek().count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("This week")
                Spacer()
                Text("\(done) of \(store.data.plan.days) done")
                    .contentTransition(.numericText(value: Double(done)))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }
            HStack(spacing: 0) {
                ForEach(store.weekDays()) { day in
                    VStack(spacing: 6) {
                        Text(day.letter)
                            .font(.system(size: 12, weight: day.planned || day.done ? .semibold : .medium))
                            .foregroundStyle(day.planned || day.done ? Theme.sub : Theme.sub.opacity(0.6))
                        dayDot(day)
                            .frame(height: 32)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glacierCard(padding: 16)
    }

    @ViewBuilder
    private func dayDot(_ day: Store.DayDot) -> some View {
        if let routine = day.routine {
            Circle()
                .fill(Theme.accent)
                .frame(width: 32, height: 32)
                .overlay(RoutineBadge(routine: routine).foregroundStyle(Theme.accentInk))
                .accessibilityElement()
                .accessibilityLabel(routine.title)
        } else if !day.planned {
            // Off day in a plan with set days.
            Circle()
                .strokeBorder(day.isToday ? Theme.accent : Color.clear, lineWidth: 2)
                .background(Circle().fill(day.isToday ? Color.clear : Theme.faint))
                .frame(width: day.isToday ? 12 : 7, height: day.isToday ? 12 : 7)
                .accessibilityLabel(day.isToday ? "Today, rest day" : "Rest day")
        } else if day.isToday {
            Circle()
                .strokeBorder(Theme.accent, lineWidth: 2)
                .frame(width: 32, height: 32)
        } else if day.isFuture && store.data.plan.isFixed {
            Circle()
                .strokeBorder(Theme.sub.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 32, height: 32)
                .accessibilityLabel("Planned")
        } else {
            Circle()
                .fill(Theme.faint)
                .frame(width: 32, height: 32)
        }
    }

    // MARK: Routine picker

    private var routinePicker: some View {
        let selected = store.todayRoutine
        var seen = Set<RoutineID>()
        let options = store.data.plan.rotation.filter { seen.insert($0).inserted }
        return Group {
            if options.count > 4 {
                ScrollView(.horizontal, showsIndicators: false) {
                    pickerRow(options, selected: selected, fixedWidth: true)
                }
            } else {
                pickerRow(options, selected: selected, fixedWidth: false)
            }
        }
        .padding(5)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
    }

    private func pickerRow(_ options: [RoutineID], selected: RoutineID, fixedWidth: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(options) { r in
                Button {
                    withAnimation(.snappy) { store.data.selectedRoutine = r }
                } label: {
                    Text(r.shortTitle)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, fixedWidth ? 14 : 0)
                        .frame(maxWidth: fixedWidth ? nil : .infinity, minHeight: 40)
                        .background(r == selected ? Theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(r == selected ? Theme.accentInk : Theme.sub)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(r == selected ? .isSelected : [])
            }
        }
    }

    // MARK: Lineup

    private var lineupCard: some View {
        let routine = store.todayRoutine
        let picks = store.plan(routine)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle("Today's lineup")
                Spacer()
                Button("What's open") { showEquipment = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accentText)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 6)
            ForEach(Array(routine.slots.enumerated()), id: \.offset) { i, slot in
                LineupRow(index: i + 1, slot: slot, exercise: picks[i], routine: routine)
            }
        }
        .glacierCard(padding: 0)
    }
}

private struct LineupRow: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let slot: Slot
    let exercise: Exercise?
    let routine: RoutineID
    @State private var showClip = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(Theme.accentText)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(exercise?.name ?? "Nothing open for \(slot.label.lowercased())")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(exercise == nil ? Theme.sub : Theme.ink)
                    if let ex = exercise, store.isFocus(ex.id) {
                        Text("FOCUS")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.6)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .foregroundStyle(Theme.accentInk)
                    }
                }
                if let ex = exercise {
                    Text(store.prescription(ex.id, routine: routine).short(for: ex) + " rest")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.sub)
                }
            }
            Spacer(minLength: 0)
            if let ex = exercise {
                Button {
                    showClip = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Theme.accentInk, Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Form video for \(ex.name)")
                .sheet(isPresented: $showClip) {
                    ClipPlayerSheet(exercise: ex)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.faint).frame(height: 1)
        }
    }
}

/// Equipment toggles as chips (used in Settings).
struct EquipmentChips: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            ForEach(Equipment.allCases) { eq in
                let isOpen = store.data.open.contains(eq)
                Button {
                    withAnimation(.snappy) { store.toggleEquipment(eq) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isOpen ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(isOpen ? Theme.accent : Theme.sub)
                        Text(eq.name)
                            .font(.system(size: 14, weight: .semibold))
                            .strikethrough(!isOpen)
                            .foregroundStyle(isOpen ? Theme.ink : Theme.sub)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(isOpen ? Theme.accentSoft : Theme.chip, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Arrow plus letter (↑A, ↕B) or a short tag (Pu, Pl, Lg, Ar) for a routine.
struct RoutineBadge: View {
    let routine: RoutineID

    var body: some View {
        HStack(spacing: 0) {
            if let arrow = routine.arrowSymbol {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .black))
            }
            Text(routine.badge)
                .font(.system(size: routine.arrowSymbol == nil ? 11 : 12, weight: .heavy))
        }
    }
}
