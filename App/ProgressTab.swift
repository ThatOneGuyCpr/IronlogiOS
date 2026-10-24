import Charts
import SwiftUI

struct ProgressTab: View {
    @EnvironmentObject private var store: Store
    @State private var chosen: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your training")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                        Text("Progress")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                    }
                    stats
                    ForEach(store.stallPrompts()) { prompt in
                        StallCard(prompt: prompt)
                    }
                    trendCard
                    recentCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background { SkyBackground() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Stats

    private var stats: some View {
        let week = store.entriesThisWeek()
        let volume = week.reduce(0) { $0 + $1.volume }
        return HStack(spacing: 10) {
            tile("\(week.count)/\(store.data.weeklyTarget)", "This week")
            tile(compact(volume), "lb this week")
            tile("\(store.weekStreak()) wk", "Streak")
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.sub)
        }
        .glacierCard(radius: 20, padding: 14)
    }

    private func compact(_ v: Double) -> String {
        if v >= 10_000 { return String(format: "%.1fk", v / 1000) }
        return v.formatted(.number.precision(.fractionLength(0)))
    }

    // MARK: Trend

    @ViewBuilder
    private var trendCard: some View {
        let options = store.trendExercises()
        if let selected = chosen.flatMap({ Library.byID[$0] }) ?? options.first {
            let points = store.trend(selected.id)
            let change = (points.last?.weight ?? 0) - (points.first?.weight ?? 0)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Menu {
                        ForEach(options) { ex in
                            Button(ex.name) { chosen = ex.id }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selected.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.sub)
                        }
                    }
                    Spacer()
                    Text(change >= 0 ? "+\(Store.fmt(change)) lb" : "\(Store.fmt(change)) lb")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(change > 0 ? Theme.goodText : Theme.sub)
                }
                Text("Top set weight per session")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
                Chart(points) { p in
                    LineMark(x: .value("Session", p.id), y: .value("Weight", p.weight))
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(Theme.accent)
                    PointMark(x: .value("Session", p.id), y: .value("Weight", p.weight))
                        .symbolSize(p.id == points.count - 1 ? 70 : 24)
                        .foregroundStyle(Theme.accent)
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine().foregroundStyle(Theme.faint)
                        AxisValueLabel().foregroundStyle(Theme.sub)
                    }
                }
                .frame(height: 140)
                .padding(.top, 10)
                .accessibilityLabel("\(selected.name) top set, \(Store.fmt(points.first?.weight ?? 0)) to \(Store.fmt(points.last?.weight ?? 0)) pounds")
            }
            .glacierCard()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                SectionTitle("Trends")
                Text("Log the same exercise twice and its weight trend shows up here.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.sub)
            }
            .glacierCard()
        }
    }

    // MARK: Recent

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle("Recent")
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 6)
            if store.data.history.isEmpty {
                Text("No workouts yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            }
            ForEach(store.data.history.prefix(5)) { entry in
                NavigationLink {
                    HistoryDetail(entry: entry)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.routine.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(entry.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · \(entry.minutes) min · \(entry.setCount) sets")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.sub)
                        }
                        Spacer()
                        Text(entry.volume.formatted(.number.precision(.fractionLength(0))) + " lb")
                            .font(.system(size: 14, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.sub)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { Rectangle().fill(Theme.faint).frame(height: 1) }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .glacierCard(padding: 0)
    }
}

// MARK: - Move-up prompt

struct StallCard: View {
    @EnvironmentObject private var store: Store
    let prompt: Store.StallPrompt

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 36, height: 36)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Theme.accentInk)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready to move up on \(prompt.name.lowercased())?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("You've been at \(Store.fmt(prompt.weight)) lb for \(prompt.sessions) sessions in a row. Try \(Store.fmt(prompt.next)) lb next time, even if the reps dip at first.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 8) {
                Button("Move to \(Store.fmt(prompt.next)) lb") {
                    withAnimation { store.acceptStall(prompt) }
                }
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Theme.accentInk)
                .buttonStyle(.plain)
                Button("Not yet") {
                    withAnimation { store.snoozeStall(prompt) }
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .padding(18)
        .background(Theme.promptBg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.promptBorder, lineWidth: 1))
    }
}
