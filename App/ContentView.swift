import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var routine: RoutineID = SharedStore.nextRoutine()
    @State private var open: Set<Equipment> = SharedStore.openEquipment()
    @StateObject private var health = HealthManager()
    @StateObject private var watch = WatchLink()

    private var plan: [Exercise?] { Generator.plan(for: routine, open: open) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    routineGrid
                    equipmentSection
                    planSection
                    finishButton
                    checksSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background { Theme.background }
            .navigationTitle("Today")
        }
        .tint(Theme.deep)
        .onChange(of: open) { _, newValue in
            SharedStore.saveOpen(newValue)
        }
    }

    // MARK: Routine

    private var routineGrid: some View {
        let next = SharedStore.nextRoutine()
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Routine")
            GlassEffectContainer(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(RoutineID.allCases) { r in
                        Button {
                            withAnimation(.snappy) { routine = r }
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
                                            .background(Theme.deep, in: Capsule())
                                            .foregroundStyle(.white)
                                    }
                                }
                                Text(r.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Theme.ink)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(
                                r == routine ? Glass.regular.tint(Theme.sky.opacity(0.5)).interactive() : Glass.regular.interactive(),
                                in: .rect(cornerRadius: 20)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("What's open")
            GlassEffectContainer(spacing: 8) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(Equipment.allCases) { eq in
                        let isOpen = open.contains(eq)
                        Button {
                            withAnimation(.snappy) {
                                if isOpen { open.remove(eq) } else { open.insert(eq) }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isOpen ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(isOpen ? Theme.deep : Color.secondary)
                                Text(eq.name)
                                    .font(.subheadline.weight(.medium))
                                    .strikethrough(!isOpen)
                                    .foregroundStyle(isOpen ? Theme.ink : Color.secondary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
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

    // MARK: Plan

    private var planSection: some View {
        let slots = routine.slots
        let picks = plan
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("\(routine.title) workout")
            VStack(spacing: 0) {
                ForEach(Array(slots.enumerated()), id: \.offset) { i, slot in
                    if i > 0 { Divider().padding(.leading, 16) }
                    PlanRow(index: i + 1, slot: slot, exercise: picks[i])
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    private var finishButton: some View {
        Button {
            SharedStore.complete(routine)
            routine = SharedStore.nextRoutine()
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text("Mark \(routine.title) done")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
    }

    // MARK: Test build checks

    private var checksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Test build checks")
            VStack(alignment: .leading, spacing: 12) {
                CheckRow(title: "Widget data", detail: SharedStore.groupWorks
                         ? "Shared container OK (\(SharedStore.groupID))"
                         : "No shared container for \(SharedStore.groupID)",
                         ok: SharedStore.groupWorks)
                CheckRow(title: "Apple Watch", detail: watch.status,
                         ok: watch.status == "Watch app installed")
                CheckRow(title: "Apple Health", detail: health.status,
                         ok: health.status.hasPrefix("Asked") || health.status.hasPrefix("Saved"))
                HStack {
                    Button("Ask for Health access") { Task { await health.requestAccess() } }
                    Button("Save test workout") { Task { await health.saveTestWorkout() } }
                }
                .buttonStyle(.glass)
                .font(.subheadline)
                Text("Bundle: \(Bundle.main.bundleIdentifier ?? "?")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.ink.opacity(0.6))
    }
}

private struct PlanRow: View {
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
                    .foregroundStyle(exercise == nil ? Color.secondary : Theme.ink)
                if let ex = exercise {
                    Text("\(slot.label) · \(slot.sets) × \(ex.timed ? "30-60s" : slot.reps) · \(ex.rest)s rest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let url = exercise?.videoURL {
                Link(destination: url) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.deep)
                }
                .accessibilityLabel("Watch form video")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct CheckRow: View {
    let title: String
    let detail: String
    let ok: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: ok ? "checkmark.seal.fill" : "questionmark.circle")
                .foregroundStyle(ok ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
