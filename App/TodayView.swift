import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    routineGrid
                    equipmentSection
                    planSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background { SkyBackground() }
            .navigationTitle("Train")
            .safeAreaInset(edge: .bottom) {
                Button {
                    start()
                } label: {
                    Text("Start \(store.todayRoutine.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private func start() {
        store.startWorkout()
        rest.requestNotificationPermission()
        guard let s = store.data.session else { return }
        let first = s.items.compactMap { $0.exerciseID }.first.flatMap { Library.byID[$0]?.name } ?? "Workout"
        rest.beginWorkout(routine: s.routine.title, startedAt: s.start, first: first)
    }

    // MARK: Routine

    private var routineGrid: some View {
        let next = store.nextRoutine
        let selected = store.todayRoutine
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Routine")
            GlassEffectContainer(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(RoutineID.allCases) { r in
                        Button {
                            withAnimation(.snappy) { store.data.selectedRoutine = r }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(r.title).font(.headline)
                                    Spacer(minLength: 0)
                                    if r == next {
                                        Text("Up next")
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Theme.accent, in: Capsule())
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                Text(lastText(r))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .glassEffect(
                                r == selected ? Glass.regular.tint(Theme.sky.opacity(0.5)).interactive() : Glass.regular.interactive(),
                                in: .rect(cornerRadius: 20)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func lastText(_ r: RoutineID) -> String {
        if let d = store.lastDone(r) {
            return "Last: " + d.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
        return r.subtitle
    }

    // MARK: Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("What's open")
            EquipmentChips()
            Text("Tap anything that's taken. The workout below rebuilds itself.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Plan

    private var planSection: some View {
        let routine = store.todayRoutine
        let picks = store.plan(routine)
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle("\(routine.title) workout")
            VStack(spacing: 0) {
                ForEach(Array(routine.slots.enumerated()), id: \.offset) { i, slot in
                    if i > 0 { Divider().padding(.leading, 46) }
                    PlanRow(index: i + 1, slot: slot, exercise: picks[i])
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }
}

struct EquipmentChips: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(Equipment.allCases) { eq in
                    let isOpen = store.data.open.contains(eq)
                    Button {
                        withAnimation(.snappy) { store.toggleEquipment(eq) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isOpen ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(isOpen ? Theme.accent : Color.secondary)
                            Text(eq.name)
                                .font(.subheadline.weight(.medium))
                                .strikethrough(!isOpen)
                                .foregroundStyle(isOpen ? Color.primary : Color.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Capsule())
                        .glassEffect(
                            isOpen ? Glass.regular.tint(Theme.sky.opacity(0.35)).interactive() : Glass.regular.interactive(),
                            in: .capsule
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PlanRow: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let slot: Slot
    let exercise: Exercise?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(index)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise?.name ?? "Nothing open for \(slot.label.lowercased())")
                    .font(.body.weight(.medium))
                    .foregroundStyle(exercise == nil ? Color.secondary : Color.primary)
                if let ex = exercise {
                    Text("\(slot.label) · \(store.prescription(ex.id).summary(for: ex))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let url = exercise?.videoURL {
                Link(destination: url) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Watch form video")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
