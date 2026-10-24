import SwiftUI
import UIKit

/// Which set field has the keyboard.
enum SetField: Hashable {
    case weight(UUID)
    case reps(UUID)
}

struct WorkoutView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var rest: RestController
    @State private var showEquipment = false
    @State private var swapIndex: IndexBox?
    @State private var editing: IDBox?
    @State private var expanded: Set<UUID> = []
    @State private var confirmDiscard = false
    @State private var confirmEmptyFinish = false
    @FocusState private var focus: SetField?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let s = store.data.session {
                    let current = s.items.firstIndex { $0.exerciseID != nil && !$0.skipped && !$0.allDone }
                    let currentPartner = current.flatMap { store.partner(of: $0) }
                    let total = s.items.count
                    VStack(alignment: .leading, spacing: 12) {
                        progressBar(s)
                        ForEach(Array(s.items.enumerated()), id: \.element.id) { i, item in
                            let label = s.routine.slots[safe: item.slot]?.label ?? ""
                            if i == current || i == currentPartner || expanded.contains(item.id) {
                                FocusCard(
                                    index: i,
                                    total: total,
                                    item: item,
                                    slotLabel: label,
                                    onSwap: { swapIndex = IndexBox(id: i) },
                                    onEdit: { id in editing = IDBox(id: id) },
                                    onSetDone: { startRest(after: i) },
                                    onCollapse: (i == current || i == currentPartner) ? nil : { _ = withAnimation(.snappy) { expanded.remove(item.id) } },
                                    focus: $focus
                                )
                            } else {
                                CompactRow(
                                    number: i + 1,
                                    item: item,
                                    slotLabel: label,
                                    isNext: current.map { i == nextIndex(after: $0, in: s) } ?? false,
                                    onTap: {
                                        if item.exerciseID == nil {
                                            swapIndex = IndexBox(id: i)
                                        } else {
                                            _ = withAnimation(.snappy) { expanded.insert(item.id) }
                                        }
                                    }
                                )
                            }
                        }
                        Button(role: .destructive) {
                            confirmDiscard = true
                        } label: {
                            Text("Discard workout")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.warn)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background { SkyBackground() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEquipment = true
                    } label: {
                        Image(systemName: "dumbbell")
                    }
                    .accessibilityLabel("What's open")
                }
                ToolbarItem(placement: .principal) {
                    if let s = store.data.session {
                        VStack(spacing: 1) {
                            Text(s.routine.title)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            (Text(s.start, style: .timer) + Text(takenSuffix))
                                .font(.system(size: 12, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.sub)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") { finish() }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if let id = weightFocus {
                        let inc = store.increment(forSet: id)
                        Button("−\(Store.fmt(inc))") { store.adjustWeight(setID: id, by: -inc) }
                        Button("+\(Store.fmt(inc))") { store.adjustWeight(setID: id, by: inc) }
                        Button("Same as last") { store.copyPrevious(setID: id) }
                    }
                    if let id = repsFocus {
                        Button("−1") { store.adjustReps(setID: id, by: -1) }
                        Button("+1") { store.adjustReps(setID: id, by: 1) }
                        Button("Same as last") { store.copyPrevious(setID: id) }
                    }
                    Spacer()
                    Button("Done") { focus = nil; hideKeyboard() }
                        .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if rest.endsAt != nil {
                    RestBar()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: rest.endsAt)
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

    private var weightFocus: UUID? {
        if case .weight(let id) = focus { return id }
        return nil
    }

    private var repsFocus: UUID? {
        if case .reps(let id) = focus { return id }
        return nil
    }

    private var takenSuffix: String {
        let taken = Equipment.allCases.filter { !store.data.open.contains($0) }
        if taken.isEmpty { return "" }
        if taken.count == 1 { return " · \(taken[0].name) taken" }
        return " · \(taken.count) machines taken"
    }

    private func nextIndex(after current: Int, in s: Session) -> Int? {
        s.items.indices.first { $0 > current && s.items[$0].exerciseID != nil && !s.items[$0].skipped && !s.items[$0].allDone }
    }

    private func progressBar(_ s: Session) -> some View {
        HStack(spacing: 5) {
            ForEach(s.items) { item in
                let fraction = item.sets.isEmpty ? 0 : Double(item.doneCount) / Double(item.sets.count)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.faint)
                        Capsule().fill(item.skipped ? Theme.sub.opacity(0.4) : Theme.accent)
                            .frame(width: item.skipped ? geo.size.width : geo.size.width * fraction)
                    }
                }
                .frame(height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(s.items.filter { $0.allDone }.count) of \(s.items.count) exercises done")
    }

    private func startRest(after i: Int) {
        guard let s = store.data.session, let id = s.items[safe: i]?.exerciseID else { return }
        var seconds = store.prescription(id).rest
        if let p = store.partner(of: i), let pid = s.items[p].exerciseID, !s.items[p].skipped, !s.items[p].allDone {
            let partnerName = Library.byID[pid]?.name ?? "the other exercise"
            if p > i {
                // First half of a superset: go straight to the second exercise.
                rest.skip()
                rest.updateProgress(next: partnerName, detail: "Superset, no rest")
                return
            }
            seconds = max(seconds, store.prescription(pid).rest)
            rest.start(seconds: seconds, next: partnerName, detail: "Superset, next round")
            return
        }
        let info = store.progressInfo(after: i)
        rest.start(seconds: seconds, next: info.next, detail: info.detail)
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

// MARK: - Collapsed exercise

private struct CompactRow: View {
    let number: Int
    let item: ItemLog
    let slotLabel: String
    let isNext: Bool
    var onTap: () -> Void

    var body: some View {
        let ex = item.exerciseID.flatMap { Library.byID[$0] }
        Button(action: onTap) {
            HStack(spacing: 12) {
                badge
                VStack(alignment: .leading, spacing: 1) {
                    Text(caption)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(isNext ? Theme.accentText : Theme.sub)
                    Text(ex?.name ?? "Nothing open for \(slotLabel.lowercased())")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ex == nil ? Theme.sub : Theme.ink)
                        .strikethrough(item.skipped)
                }
                Spacer(minLength: 0)
                Image(systemName: ex == nil ? "arrow.left.arrow.right" : "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glacierCard(radius: 20, padding: 14)
        .opacity(item.allDone || item.skipped ? 0.8 : 1)
    }

    private var caption: String {
        if item.skipped { return "SKIPPED" }
        if item.allDone { return "DONE · \(item.doneCount) SETS" }
        if isNext { return "UP NEXT" }
        return slotLabel.uppercased()
    }

    @ViewBuilder
    private var badge: some View {
        if item.allDone {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .frame(width: 28, height: 28)
                .background(Theme.good, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(Theme.goodInk)
        } else if item.skipped {
            Image(systemName: "forward.fill")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Theme.chip, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(Theme.sub)
        } else {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
                .background(isNext ? Theme.accentSoft : Theme.chip, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(isNext ? Theme.accentText : Theme.sub)
        }
    }
}

// MARK: - Focus card

struct FocusCard: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let total: Int
    let item: ItemLog
    let slotLabel: String
    var onSwap: () -> Void
    var onEdit: (String) -> Void
    var onSetDone: () -> Void
    var onCollapse: (() -> Void)?
    var focus: FocusState<SetField?>.Binding
    @State private var editingNote = false

    var body: some View {
        let ex = item.exerciseID.flatMap { Library.byID[$0] }
        let paired = store.partner(of: index) != nil
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(paired ? "SUPERSET · " : "")\(slotLabel.uppercased()) · \(index + 1) OF \(total)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Theme.accentText)
                    Text(ex?.name ?? "Nothing open")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                Spacer(minLength: 0)
                if let onCollapse {
                    Button(action: onCollapse) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Theme.fieldBorder, lineWidth: 1))
                            .foregroundStyle(Theme.sub)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Collapse")
                }
                if let ex {
                    Menu {
                        Button("Sets, reps and rest", systemImage: "slider.horizontal.3") { onEdit(ex.id) }
                        Button("Swap exercise", systemImage: "arrow.left.arrow.right") { onSwap() }
                        Button(paired ? "Undo superset" : "Superset with next", systemImage: "link") {
                            withAnimation(.snappy) { store.toggleSuperset(index) }
                        }
                        Button((store.data.notes[ex.id] ?? "").isEmpty ? "Add a note" : "Edit note", systemImage: "note.text") {
                            editingNote = true
                        }
                        Button(item.skipped ? "Undo skip" : "Skip today", systemImage: "forward") {
                            store.setSkipped(index, !item.skipped)
                        }
                        Button("Remove last set", systemImage: "minus.circle") { store.removeLastSet(index) }
                        Button("Never show this exercise", systemImage: "eye.slash", role: .destructive) {
                            store.hide(index)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Theme.fieldBorder, lineWidth: 1))
                            .foregroundStyle(Theme.sub)
                    }
                    .accessibilityLabel("More options")
                }
            }

            if let ex {
                let note = store.data.notes[ex.id] ?? ""
                if editingNote || !note.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accentText)
                            .padding(.top, 2)
                        TextField("Seat height, pin, grip…", text: store.noteBinding(ex.id), axis: .vertical)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1...4)
                            .onSubmit { editingNote = false }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                ClipBox(exercise: ex)

                let p = store.prescription(ex.id)
                HStack(spacing: 8) {
                    Text("Target " + p.short(for: ex))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Theme.chip, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .foregroundStyle(Theme.sub)
                    if let w = store.nudgeWeight(ex.id) {
                        Label("Try \(Store.fmt(w)) lb today", systemImage: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .foregroundStyle(Theme.accentText)
                    }
                }

                SetTable(index: index, item: item, exercise: ex, onSetDone: onSetDone, focus: focus)

                if !store.isAvailable(ex.id) && !item.allDone {
                    Text("\(store.missingReason(ex.id)). Swap to finish the remaining sets on something else.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.warn)
                }

                HStack(spacing: 8) {
                    Button("Add set") { store.addSet(index) }
                    Button("Swap exercise", action: onSwap)
                }
                .buttonStyle(OutlineButtonStyle())
            } else {
                Button("Choose an exercise", action: onSwap)
                    .buttonStyle(OutlineButtonStyle())
            }
        }
        .glacierCard(radius: 28, padding: 18)
    }
}

// MARK: - Set table

private struct SetTable: View {
    @EnvironmentObject private var store: Store
    let index: Int
    let item: ItemLog
    let exercise: Exercise
    var onSetDone: () -> Void
    var focus: FocusState<SetField?>.Binding

    var body: some View {
        let active = item.sets.firstIndex { !$0.done }
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("SET").frame(width: 30)
                Text("LAST").frame(width: 72, alignment: .leading)
                if !exercise.timed { Text("LB").frame(maxWidth: .infinity) }
                Text(exercise.timed ? "SEC" : "REPS").frame(maxWidth: .infinity)
                Color.clear.frame(width: 48, height: 1)
            }
            .font(.system(size: 11, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Theme.sub)

            ForEach(Array(item.sets.enumerated()), id: \.element.id) { j, set in
                SetRow(i: index, j: j, set: set, exercise: exercise,
                       last: store.lastSet(exercise.id, j),
                       isActive: j == active, onDone: onSetDone, focus: focus)
            }
        }
    }
}

struct SetRow: View {
    @EnvironmentObject private var store: Store
    let i: Int
    let j: Int
    let set: SetLog
    let exercise: Exercise
    let last: String
    let isActive: Bool
    var onDone: () -> Void
    var focus: FocusState<SetField?>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Text("\(j + 1)")
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(isActive ? Theme.accentText : Theme.sub)
                .frame(width: 30)
            Text(last)
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.sub)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 72, alignment: .leading)
            if !exercise.timed {
                field(placeholder: exercise.bodyweight ? "BW" : "lb",
                      text: store.binding(i, j, \.weight), keyboard: .decimalPad,
                      label: "Weight, set \(j + 1)")
                    .focused(focus, equals: .weight(set.id))
            }
            field(placeholder: set.hint.isEmpty ? (exercise.timed ? "sec" : "reps") : set.hint,
                  text: store.binding(i, j, \.reps), keyboard: .numberPad,
                  label: "\(exercise.timed ? "Seconds" : "Reps"), set \(j + 1)")
                .focused(focus, equals: .reps(set.id))
            Button {
                focus.wrappedValue = nil
                hideKeyboard()
                if store.toggleSet(i, j) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDone()
                } else if !set.done {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .heavy))
                    .frame(width: 48, height: 46)
                    .foregroundStyle(set.done ? Theme.goodInk : Theme.sub)
                    .background(set.done ? Theme.good : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(set.done ? Color.clear : Theme.fieldBorder, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.done ? "Set \(j + 1) done" : "Mark set \(j + 1) done")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(set.done ? Theme.goodRow : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func field(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, label: String) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(.system(size: 19, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(set.done ? Color.clear : Theme.field, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(set.done ? Color.clear : (isActive ? Theme.accent : Theme.fieldBorder), lineWidth: isActive ? 2 : 1)
            )
            .accessibilityLabel(label)
    }
}

// MARK: - Rest bar

struct RestBar: View {
    @EnvironmentObject private var rest: RestController

    var body: some View {
        if let end = rest.endsAt, let start = rest.startedAt {
            let range = start...max(start, end)
            HStack(spacing: 14) {
                TimelineView(.periodic(from: .now, by: 0.2)) { context in
                    let total = max(1, end.timeIntervalSince(start))
                    let left = max(0, end.timeIntervalSince(context.date))
                    ZStack {
                        Circle().stroke(Theme.accentInk.opacity(0.25), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: left / total)
                            .stroke(Theme.accentInk, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 48, height: 48)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("REST")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .opacity(0.85)
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 30, weight: .heavy))
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
                Button("+15s") { rest.add(15) }
                    .font(.system(size: 15, weight: .bold))
                    .frame(height: 44)
                    .padding(.horizontal, 14)
                    .background(Theme.accentInk.opacity(0.18), in: Capsule())
                Button("Skip") { rest.skip() }
                    .font(.system(size: 15, weight: .bold))
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .background(Theme.accentInk, in: Capsule())
                    .foregroundStyle(Theme.accent)
            }
            .foregroundStyle(Theme.accentInk)
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Theme.shadow, radius: 18, y: 8)
        }
    }
}
