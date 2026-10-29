import SwiftUI

// MARK: - Equipment (mid-workout)

struct EquipmentSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var swapIndex: IndexBox?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Equipment.allCases) { eq in
                        Toggle(eq.name, isOn: Binding(
                            get: { store.data.open.contains(eq) },
                            set: { _ in withAnimation { store.toggleEquipment(eq) } }
                        ))
                    }
                } footer: {
                    Text("Exercises you haven't started swap automatically.")
                }

                let swapped = swappedRows
                if !swapped.isEmpty {
                    Section("Swapped for you") {
                        ForEach(swapped, id: \.index) { row in
                            changeRow(title: "\(row.from) → \(row.to)", detail: nil, index: row.index)
                        }
                    }
                }

                let stuck = stuckRows
                if !stuck.isEmpty {
                    Section("Started, but the gear is now taken") {
                        ForEach(stuck, id: \.index) { row in
                            changeRow(title: row.name, detail: row.reason, index: row.index)
                        }
                    }
                }
            }
            .navigationTitle("What's open")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $swapIndex) { box in
                SwapSheet(index: box.id)
                    .presentationDetents([.medium, .large])
            }
            .onAppear { store.changes.removeAll() }
        }
    }

    private func changeRow(title: String, detail: String?, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Options") { swapIndex = IndexBox(id: index) }
                .buttonStyle(.glass)
                .font(.caption)
        }
    }

    private struct SwappedRow { let index: Int; let from: String; let to: String }
    private struct StuckRow { let index: Int; let name: String; let reason: String }

    private var swappedRows: [SwappedRow] {
        guard let s = store.data.session else { return [] }
        return store.changes.compactMap { change in
            guard let idx = s.items.firstIndex(where: { $0.id == change.itemID }) else { return nil }
            let now = s.items[idx].exerciseID
            guard now != change.from else { return nil }
            return SwappedRow(index: idx, from: name(change.from), to: name(now))
        }
    }

    private var stuckRows: [StuckRow] {
        guard let s = store.data.session else { return [] }
        return s.items.enumerated().compactMap { idx, item in
            guard let id = item.exerciseID, !item.skipped, !item.allDone, item.hasDone, !store.isAvailable(id) else { return nil }
            return StuckRow(index: idx, name: name(id), reason: store.missingReason(id))
        }
    }

    private func name(_ id: String?) -> String {
        id.flatMap { Library.byID[$0]?.name } ?? "Nothing open"
    }
}

// MARK: - Swap

struct SwapSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let index: Int

    var body: some View {
        NavigationStack {
            List {
                if let s = store.data.session, let item = s.items[safe: index], let slot = s.routine.slots[safe: item.slot] {
                    let others = Set(s.items.enumerated().filter { $0.offset != index }.compactMap { $0.element.exerciseID })
                    Section {
                        ForEach(slot.candidates, id: \.self) { id in
                            if let ex = Library.byID[id] {
                                let current = id == item.exerciseID
                                let inWorkout = others.contains(id)
                                let ok = store.isAvailable(id) && !inWorkout && !current
                                Button {
                                    store.swap(index, to: id)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ex.name)
                                                .foregroundStyle(ok ? Color.primary : Color.secondary)
                                            Text(store.prescription(id).summary(for: ex))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(current ? "Current" : inWorkout ? "In workout" : store.missingReason(id))
                                            .font(.caption)
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                .disabled(!ok)
                            }
                        }
                    } footer: {
                        if item.hasDone {
                            Text("Sets you've logged stay on \(item.exerciseID.flatMap { Library.byID[$0]?.name } ?? "this exercise"). The new one gets the remaining sets.")
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var title: String {
        guard let s = store.data.session, let item = s.items[safe: index] else { return "Swap" }
        return s.routine.slots[safe: item.slot]?.label ?? "Swap"
    }
}

// MARK: - Sets, reps and rest

struct ExerciseSettingsSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let exerciseID: String
    @State private var p = Preset.isolation
    @State private var loaded = false

    var body: some View {
        let ex = Library.byID[exerciseID]
        let unit = (ex?.timed ?? false) ? "Seconds" : "Reps"
        NavigationStack {
            Form {
                Section {
                    Stepper("Sets: \(p.sets)", value: $p.sets, in: 1...8)
                    Stepper("\(unit), low end: \(p.low)", value: $p.low, in: 1...300, step: (ex?.timed ?? false) ? 5 : 1)
                    Stepper("\(unit), high end: \(p.high)", value: $p.high, in: max(1, p.low)...300, step: (ex?.timed ?? false) ? 5 : 1)
                    Stepper("Rest: \(p.rest)s", value: $p.rest, in: 15...300, step: 15)
                } footer: {
                    if let ex {
                        Text("Default: \(ex.preset.summary(for: ex)). When every set hits the top of the range, Ironlog suggests going up in weight next time.")
                    }
                }
                if let ex, p != ex.preset {
                    Section {
                        Button("Reset to default") { p = ex.preset }
                    }
                }
            }
            .navigationTitle(ex?.name ?? "Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setPrescription(p, for: exerciseID)
                        dismiss()
                    }
                }
            }
            .onChange(of: p.low) { _, low in
                if p.high < low { p.high = low }
            }
            .onAppear {
                if !loaded {
                    p = store.prescription(exerciseID)
                    loaded = true
                }
            }
        }
    }
}

// MARK: - Finished

struct FinishSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    let entry: HistoryEntry
    @State private var appeared = false

    var body: some View {
        let records = store.records(for: entry)
        let party = store.data.celebrations
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: records.isEmpty ? "checkmark.circle.fill" : "trophy.circle.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.bounce, value: appeared)
                    Text("Workout saved")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 24)
                HStack(spacing: 28) {
                    stat(Double(entry.setCount), "sets", delay: 0.1)
                    stat(entry.volume, "lb moved", delay: 0.2)
                    stat(Double(entry.minutes), "min", delay: 0.3)
                }
                if !records.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(records.count == 1 ? "New record" : "\(records.count) new records", systemImage: "trophy.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.accentText)
                        ForEach(records) { r in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(r.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(r.text)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.sub)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.promptBg, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.promptBorder, lineWidth: 1))
                    .padding(.horizontal, 24)
                    .scaleEffect(appeared || !party ? 1 : 0.92)
                    .opacity(appeared || !party ? 1 : 0)
                }
                if store.data.healthViaShortcut, let url = store.healthShortcutURL(minutes: entry.minutes) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Save to Apple Health", systemImage: "heart.fill")
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .padding(.horizontal, 24)
                }
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .background { SkyBackground() }
        .overlay {
            if party && !records.isEmpty {
                ConfettiView(count: 120, duration: 3.5).ignoresSafeArea()
            }
        }
        .sensoryFeedback(.success, trigger: appeared) { _, new in new && party && !records.isEmpty }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.35)) { appeared = true }
        }
    }

    private func stat(_ value: Double, _ label: String, delay: Double) -> some View {
        VStack(spacing: 2) {
            Group {
                if store.data.celebrations {
                    CountUpText(value: value, delay: delay)
                } else {
                    Text(value.formatted(.number.precision(.fractionLength(0))))
                }
            }
                .font(Theme.num(28))
                .foregroundStyle(Theme.ink)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.sub)
        }
    }
}
