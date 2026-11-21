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
                            .listRowBackground(Theme.row ?? Color.clear)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { store.data.history[$0].id }
                            ids.forEach { store.deleteHistory($0) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .tabBarClearance()
            .background { SkyBackground() }
            .navigationTitle(Theme.skin.isGlacier ? "History" : Theme.words.tabs[2])
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
                    Text(entry.routine.title).font(Theme.style(.headline)).foregroundStyle(Theme.ink)
                    if records > 0 {
                        Label("\(records)", systemImage: "trophy.fill")
                            .font(Theme.font(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accentText)
                            .accessibilityLabel(records.counted("record"))
                    }
                }
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · \(entry.minutes) min")
                    .font(Theme.style(.caption))
                    .foregroundStyle(Theme.sub)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.setCount.counted("set")).font(Theme.style(.subheadline)).foregroundStyle(Theme.ink)
                Text(entry.volume.formatted(.number.precision(.fractionLength(0))) + " lb")
                    .font(Theme.style(.caption))
                    .foregroundStyle(Theme.sub)
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
            Group {
                Section {
                    HStack(spacing: 0) {
                        summary("\(entry.setCount)", entry.setCount == 1 ? "set" : "sets")
                        summary(entry.volume.formatted(.number.precision(.fractionLength(0))), "lb moved")
                        summary("\(entry.minutes)", "min")
                    }
                    .padding(.vertical, 4)
                } header: {
                    FormHeader(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                }
                if !records.isEmpty {
                    Section {
                        ForEach(records) { r in
                            Label {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.name).font(Theme.font(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                                    Text(r.text).font(Theme.style(.caption)).foregroundStyle(Theme.sub)
                                }
                            } icon: {
                                Image(systemName: "trophy.fill").foregroundStyle(Theme.accentText)
                            }
                        }
                    } header: {
                        FormHeader("Records")
                    }
                }
                ForEach(Array(entry.items.enumerated()), id: \.offset) { _, item in
                    Section(header: FormHeader(item.name)) {
                        ForEach(Array(item.sets.enumerated()), id: \.offset) { k, s in
                            HStack {
                                Text("Set \(k + 1)").font(Theme.font(size: 16)).foregroundStyle(Theme.sub)
                                Spacer()
                                Text(line(item, s)).font(Theme.num(16, .semibold)).foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.row)
        }
        .scrollContentBackground(.hidden)
        .tabBarClearance()
        .background { SkyBackground(calm: true) }
        .navigationTitle(entry.routine.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summary(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.num(22)).foregroundStyle(Theme.ink)
            Text(label.uppercased()).font(Theme.label(11, .bold)).tracking(0.6).foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity)
    }

    private func line(_ item: HistoryItem, _ s: HistorySet) -> String {
        if Library.byID[item.exerciseID]?.timed == true { return "\(s.reps)s" }
        return s.weight > 0 ? "\(Store.fmt(s.weight)) lb × \(s.reps)" : "\(s.reps) reps"
    }
}
