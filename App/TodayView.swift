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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                heroCard
                weekCard
                routinePicker
                lineupCard
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
                meta("list.bullet", "\(picks.compactMap { $0 }.count) exercises")
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
                Text("\(done) of \(store.data.weeklyTarget) done")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }
            HStack(spacing: 0) {
                ForEach(store.weekDays()) { day in
                    VStack(spacing: 6) {
                        Text(day.letter)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                        dayDot(day)
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
                .overlay(
                    HStack(spacing: 0) {
                        Image(systemName: routine.isUpper ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .black))
                        Text(routine.variant)
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .foregroundStyle(Theme.accentInk)
                )
                .accessibilityElement()
                .accessibilityLabel(routine.title)
        } else if day.isToday {
            Circle()
                .strokeBorder(Theme.accent, lineWidth: 2)
                .frame(width: 32, height: 32)
        } else {
            Circle()
                .fill(Theme.faint)
                .frame(width: 32, height: 32)
        }
    }

    // MARK: Routine picker

    private var routinePicker: some View {
        let selected = store.todayRoutine
        return HStack(spacing: 6) {
            ForEach(RoutineID.cycle) { r in
                Button {
                    withAnimation(.snappy) { store.data.selectedRoutine = r }
                } label: {
                    Text(r.title)
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(r == selected ? Theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(r == selected ? Theme.accentInk : Theme.sub)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(r == selected ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.cardBorder, lineWidth: 1))
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
                LineupRow(index: i + 1, slot: slot, exercise: picks[i])
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
    @State private var showClip = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(Theme.accentText)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? "Nothing open for \(slot.label.lowercased())")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(exercise == nil ? Theme.sub : Theme.ink)
                if let ex = exercise {
                    Text(store.prescription(ex.id).short(for: ex) + " rest")
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
