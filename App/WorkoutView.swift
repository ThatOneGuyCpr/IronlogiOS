import SwiftUI
import UIKit

struct WorkoutView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController
    @State private var showEquipment = false
    @State private var swapIndex: IndexBox?
    @State private var editing: IDBox?
    @State private var confirmDiscard = false
    @State private var confirmEmptyFinish = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let s = store.data.session {
                    VStack(alignment: .leading, spacing: 14) {
                        header(s)
                        ForEach(Array(s.items.enumerated()), id: \.element.id) { i, item in
                            ExerciseCard(
                                index: i,
                                item: item,
                                slotLabel: s.routine.slots[safe: item.slot]?.label ?? "",
                                onSwap: { swapIndex = IndexBox(id: i) },
                                onEdit: { id in editing = IDBox(id: id) },
                                onSetDone: { startRest(after: i) }
                            )
                        }
                        Button(role: .destructive) {
                            confirmDiscard = true
                        } label: {
                            Text("Discard workout").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background { SkyBackground() }
            .navigationTitle(store.data.session?.routine.title ?? "Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEquipment = true
                    } label: {
                        Label("Equipment", systemImage: "dumbbell")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") { finish() }
                        .buttonStyle(.glassProminent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if rest.endsAt != nil {
                    RestBar()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $showEquipment) {
                EquipmentSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $swapIndex) { box in
                SwapSheet(index: box.id)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $editing) { box in
                ExerciseSettingsSheet(exerciseID: box.id)
                    .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Discard this workout? Nothing will be saved.", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) {
                    store.discard()
                    rest.endWorkout()
                }
            }
            .confirmationDialog("No sets logged yet. Discard this workout?", isPresented: $confirmEmptyFinish, titleVisibility: .visible) {
                Button("Discard", role: .destructive) {
                    store.discard()
                    rest.endWorkout()
                }
            }
        }
    }

    private func header(_ s: Session) -> some View {
        let taken = Equipment.allCases.filter { !store.data.open.contains($0) }.map { $0.name }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "stopwatch")
                Text(s.start, style: .timer)
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            if !taken.isEmpty {
                Text("Taken: " + taken.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startRest(after i: Int) {
        guard let id = store.data.session?.items[safe: i]?.exerciseID else { return }
        let info = store.progressInfo(after: i)
        rest.start(seconds: store.prescription(id).rest, next: info.next, detail: info.detail)
    }

    private func finish() {
        hideKeyboard()
        let anyDone = store.data.session?.items.contains { $0.hasDone } ?? false
        if !anyDone {
            confirmEmptyFinish = true
            return
        }
        store.finishWorkout()
        rest.endWorkout()
    }
}

// MARK: - Exercise card

struct ExerciseCard: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let item: ItemLog
    let slotLabel: String
    var onSwap: () -> Void
    var onEdit: (String) -> Void
    var onSetDone: () -> Void

    var body: some View {
        let ex = item.exerciseID.flatMap { Library.byID[$0] }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(slotLabel.uppercased() + (item.skipped ? " · SKIPPED" : ""))
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(Theme.accent)
                    Text(ex?.name ?? "Nothing open")
                        .font(.headline)
                    if let ex {
                        Text(store.lastLine(ex.id))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if let ex {
                    if let url = ex.videoURL {
                        Link(destination: url) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityLabel("Watch form video")
                    }
                    Menu {
                        Button("Sets, reps and rest", systemImage: "slider.horizontal.3") { onEdit(ex.id) }
                        Button("Swap exercise", systemImage: "arrow.left.arrow.right") { onSwap() }
                        Button(item.skipped ? "Undo skip" : "Skip today", systemImage: "forward") {
                            store.setSkipped(index, !item.skipped)
                        }
                        Button("Remove last set", systemImage: "minus.circle") { store.removeLastSet(index) }
                        Button("Never show this exercise", systemImage: "eye.slash", role: .destructive) {
                            store.hide(index)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let ex, !item.skipped {
                let p = store.prescription(ex.id)
                Text("Target: " + p.summary(for: ex))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(Array(item.sets.enumerated()), id: \.element.id) { j, set in
                        SetRow(i: index, j: j, set: set, exercise: ex, onDone: onSetDone)
                    }
                }

                if !store.isAvailable(ex.id) && !item.allDone {
                    Text("\(store.missingReason(ex.id)). Swap to finish the remaining sets on something else.")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                HStack {
                    Button {
                        store.addSet(index)
                    } label: {
                        Label("Set", systemImage: "plus").frame(maxWidth: .infinity)
                    }
                    Button {
                        onSwap()
                    } label: {
                        Label("Swap", systemImage: "arrow.left.arrow.right").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.glass)
                .font(.subheadline)
            } else if ex == nil {
                Button("Choose an exercise", action: onSwap)
                    .buttonStyle(.glass)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(item.allDone ? Glass.regular.tint(Color.green.opacity(0.18)) : Glass.regular,
                     in: .rect(cornerRadius: 22))
        .opacity(item.skipped ? 0.6 : 1)
    }
}

// MARK: - Set row

struct SetRow: View {
    @EnvironmentObject private var store: Store
    let i: Int
    let j: Int
    let set: SetLog
    let exercise: Exercise
    var onDone: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(j + 1)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 22)
            if !exercise.timed {
                field(placeholder: exercise.bodyweight ? "BW" : "lb", text: store.binding(i, j, \.weight), keyboard: .decimalPad)
            }
            field(placeholder: set.hint.isEmpty ? (exercise.timed ? "sec" : "reps") : set.hint,
                  text: store.binding(i, j, \.reps), keyboard: .numberPad)
            Button {
                hideKeyboard()
                if store.toggleSet(i, j) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                } else if !set.done {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .frame(width: 46, height: 42)
                    .foregroundStyle(set.done ? Color.white : Color.secondary)
                    .background(set.done ? Color.green : Color.primary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.done ? "Set \(j + 1) done" : "Mark set \(j + 1) done")
        }
        .opacity(set.done ? 0.75 : 1)
    }

    private func field(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(.title3.monospacedDigit())
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Rest bar

struct RestBar: View {
    @EnvironmentObject private var rest: RestController

    var body: some View {
        if let end = rest.endsAt, let start = rest.startedAt {
            let range = start...max(start, end)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("REST")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: range, countsDown: true)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .frame(minWidth: 64, alignment: .leading)
                }
                ProgressView(timerInterval: range, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(Theme.accent)
                Button("+15s") { rest.add(15) }
                    .buttonStyle(.glass)
                Button("Skip") { rest.skip() }
                    .buttonStyle(.glass)
            }
            .padding(12)
            .glassEffect(Glass.regular.tint(Theme.sky.opacity(0.3)), in: .rect(cornerRadius: 22))
        }
    }
}
