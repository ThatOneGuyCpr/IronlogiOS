import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        NavigationStack {
            Group {
                if store.data.history.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "dumbbell",
                        description: Text("Finished workouts show up here. You can also import your history from the web version in Settings.")
                    )
                } else {
                    List {
                        ForEach(store.data.history) { entry in
                            NavigationLink {
                                HistoryDetail(entry: entry)
                            } label: {
                                HistoryRow(entry: entry, records: store.records(for: entry).count)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { store.data.history[$0].id }
                            ids.forEach { store.deleteHistory($0) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background { SkyBackground() }
            .navigationTitle("History")
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let records: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.routine.title).font(.headline)
                    if records > 0 {
                        Label("\(records)", systemImage: "trophy.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accentText)
                            .accessibilityLabel("\(records) records")
                    }
                }
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · \(entry.minutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(entry.setCount) sets").font(.subheadline)
                Text(entry.volume.formatted(.number.precision(.fractionLength(0))) + " lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryDetail: View {
    @EnvironmentObject private var store: Store
    let entry: HistoryEntry

    var body: some View {
        let records = store.records(for: entry)
        List {
            if !records.isEmpty {
                Section {
                    ForEach(records) { r in
                        Label {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(r.name)
                                Text(r.text).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "trophy.fill").foregroundStyle(Theme.accent)
                        }
                    }
                } header: {
                    Text("Records")
                }
            }
            ForEach(Array(entry.items.enumerated()), id: \.offset) { _, item in
                Section(item.name) {
                    ForEach(Array(item.sets.enumerated()), id: \.offset) { k, s in
                        HStack {
                            Text("Set \(k + 1)").foregroundStyle(.secondary)
                            Spacer()
                            Text(line(item, s)).monospacedDigit()
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { SkyBackground() }
        .navigationTitle(entry.routine.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func line(_ item: HistoryItem, _ s: HistorySet) -> String {
        if Library.byID[item.exerciseID]?.timed == true { return "\(s.reps)s" }
        return s.weight > 0 ? "\(Store.fmt(s.weight)) lb × \(s.reps)" : "\(s.reps) reps"
    }
}
