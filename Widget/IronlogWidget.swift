import SwiftUI
import UIKit
import WidgetKit

// MARK: - Palette (matches the app's Glacier colors)

extension UIColor {
    convenience init(widgetHex hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

enum WP {
    static func dyn(_ light: UInt32, _ dark: UInt32, la: CGFloat = 1, da: CGFloat = 1) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(widgetHex: dark, alpha: da) : UIColor(widgetHex: light, alpha: la)
        })
    }

    static let ink = dyn(0x0B1B2E, 0xF2F6FB)
    static let sub = dyn(0x4A5D73, 0xA9B8CA)
    static let accent = dyn(0x1F6FEB, 0x4C9BFF)
    static let accentInk = dyn(0xFFFFFF, 0x05101F)
    static let faint = dyn(0xDCE6F1, 0xFFFFFF, da: 0.12)
    static let inner = dyn(0xEEF4FB, 0xFFFFFF, da: 0.07)
    static let rule = dyn(0xDCE6F1, 0xFFFFFF, da: 0.10)
    static let good = dyn(0x15803D, 0x5BD68A)
    static let outline = dyn(0xCCDAEA, 0xFFFFFF, da: 0.2)
    static let top = dyn(0xFFFFFF, 0x0F2342)
    static let bottom = dyn(0xE6F0FC, 0x0A1830)
}

struct WidgetSky: View {
    var body: some View {
        LinearGradient(colors: [WP.top, WP.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct Caption: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(WP.sub)
            .lineLimit(1)
    }
}

private struct StartPill: View {
    var title = "Start"
    var height: CGFloat = 34
    var filled = true

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: height)
            .background(filled ? WP.accent : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(filled ? Color.clear : WP.outline, lineWidth: 1))
            .foregroundStyle(filled ? WP.accentInk : WP.ink)
    }
}

enum Links {
    static let start = URL(string: "ironlog://start")!
    static func moveUp(_ id: String) -> URL { URL(string: "ironlog://moveup/\(id)")! }
}

// MARK: - Timeline

struct SnapEntry: TimelineEntry {
    let date: Date
    let snap: WidgetSnapshot
}

struct SnapProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapEntry {
        SnapEntry(date: Date(), snap: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapEntry) -> Void) {
        let snap = WidgetSnapshot.load()
        completion(SnapEntry(date: Date(), snap: context.isPreview && snap.workouts.isEmpty ? Self.sample : snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapEntry>) -> Void) {
        let snap = WidgetSnapshot.load()
        let now = Date()
        var entries = [SnapEntry(date: now, snap: snap)]
        // Refresh just after midnight so "Yesterday" and the week count roll over.
        if let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime) {
            entries.append(SnapEntry(date: midnight, snap: snap))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    static var sample: WidgetSnapshot {
        var s = WidgetSnapshot()
        let day: TimeInterval = 86_400
        s.workouts = [
            .init(date: Date().addingTimeInterval(-day), routine: .upperB, minutes: 47, sets: 18, volume: 9120),
            .init(date: Date().addingTimeInterval(-2 * day), routine: .lowerA, minutes: 44, sets: 18, volume: 14860),
        ]
        s.next = .lowerB
        s.nextFirst = "Smith Romanian deadlift"
        s.record = .init(name: "Dumbbell bench press", text: "Heaviest yet: 55 lb", date: Date())
        s.trend = .init(name: "Dumbbell bench press", weights: [40, 40, 45, 45, 45, 50, 50, 55])
        s.moveUp = .init(id: "db_curl", name: "Dumbbell curl", weight: 20, sessions: 8, next: 25)
        return s
    }
}

// MARK: - This week (medium, large, lock screen)

struct WeekWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapEntry

    var body: some View {
        let snap = entry.snap
        let count = snap.weekCount(entry.date)
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(min(count, snap.weeklyTarget)), in: 0...Double(max(1, snap.weeklyTarget))) {
                Image(systemName: "dumbbell.fill")
            } currentValueLabel: {
                Text("\(count)/\(snap.weeklyTarget)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        case .accessoryInline:
            Text("\(count) of \(snap.weeklyTarget) this week · \(snap.next.title) next")
        case .systemLarge:
            LargeOverview(entry: entry)
        default:
            MediumWeek(entry: entry)
        }
    }
}

private struct MediumWeek: View {
    let entry: SnapEntry

    var body: some View {
        let snap = entry.snap
        let count = snap.weekCount(entry.date)
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Caption("THIS WEEK")
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundStyle(WP.accent)
                        .minimumScaleFactor(0.6)
                    Text("/ \(snap.weeklyTarget)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(WP.sub)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    ForEach(snap.days(entry.date)) { d in
                        Circle()
                            .fill(d.code != nil ? WP.accent : WP.faint)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(d.isToday && d.code == nil ? WP.accent : Color.clear, lineWidth: 1.5))
                    }
                }
            }
            .frame(width: 118, alignment: .leading)

            Rectangle().fill(WP.rule).frame(width: 1)

            VStack(alignment: .leading, spacing: 0) {
                Caption("LAST WORKOUT")
                Spacer(minLength: 0)
                if let last = snap.last {
                    Text(last.routine.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(WP.ink)
                    Text(last.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " · " + WidgetSnapshot.relativeDay(last.date, now: entry.date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WP.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text("\(last.minutes) min · \(last.sets) sets · \(last.volume.formatted(.number.precision(.fractionLength(0)))) lb")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WP.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("No workouts yet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(WP.ink)
                    Spacer(minLength: 0)
                    Text("\(snap.next.title) is up first")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WP.sub)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct WeekRing: View {
    let count: Int
    let target: Int

    var body: some View {
        let fraction = min(1, Double(count) / Double(max(1, target)))
        ZStack {
            Circle().stroke(WP.faint, lineWidth: 9)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(WP.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(count)/\(target)")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(WP.ink)
        }
        .frame(width: 74, height: 74)
    }
}

private struct LargeOverview: View {
    let entry: SnapEntry

    var body: some View {
        let snap = entry.snap
        let count = snap.weekCount(entry.date)
        let left = max(0, snap.weeklyTarget - count)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                WeekRing(count: count, target: snap.weeklyTarget)
                VStack(alignment: .leading, spacing: 2) {
                    Caption("THIS WEEK")
                    Text(left == 0 ? "Week done" : left == 1 ? "One to go" : "\(left) to go")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(WP.ink)
                    Text("\(snap.streak(entry.date))-week streak")
                        .font(.system(size: 13))
                        .foregroundStyle(WP.sub)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Caption("LAST WORKOUT")
                if let last = snap.last {
                    Text("\(last.routine.title) · \(WidgetSnapshot.relativeDay(last.date, now: entry.date))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(WP.ink)
                    Text("\(last.minutes) min · \(last.sets) sets")
                        .font(.system(size: 12))
                        .foregroundStyle(WP.sub)
                } else {
                    Text("No workouts yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(WP.ink)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WP.inner, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let r = snap.record {
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(WP.accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("New record: \(r.name)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WP.ink)
                            .lineLimit(1)
                        Text(r.text)
                            .font(.system(size: 12))
                            .foregroundStyle(WP.sub)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WP.inner, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Caption("UP NEXT")
                    Text(snap.next.title)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(WP.ink)
                }
                Spacer()
                Link(destination: Links.start) {
                    StartPill(height: 40)
                        .frame(width: 96)
                }
            }
        }
    }
}

struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Week", provider: SnapProvider()) { entry in
            WeekWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("This week")
        .description("Workouts this week and your last session.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Up next (small, lock screen)

struct NextWorkoutView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapEntry

    var body: some View {
        let snap = entry.snap
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Up next").font(.caption2)
                Text(snap.next.title).font(.headline).widgetAccentable()
                Text(snap.nextFirst.map { "\($0) first" } ?? "\(snap.nextCount) exercises")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 0) {
                Caption("UP NEXT")
                Spacer(minLength: 0)
                Text(snap.next.title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(WP.ink)
                Text("\(snap.nextCount) exercises")
                    .font(.system(size: 12))
                    .foregroundStyle(WP.sub)
                Spacer(minLength: 0)
                StartPill()
            }
            .widgetURL(Links.start)
        }
    }
}

struct NextWorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextWorkout", provider: SnapProvider()) { entry in
            NextWorkoutView(entry: entry)
                .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("Up next")
        .description("Your next routine, one tap to start.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// MARK: - Last workout (lock screen)

struct LastWorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LastWorkout", provider: SnapProvider()) { entry in
            VStack(alignment: .leading, spacing: 1) {
                Text("Last workout").font(.caption2)
                if let last = entry.snap.last {
                    Text(WidgetSnapshot.relativeDay(last.date, now: entry.date))
                        .font(.headline)
                        .widgetAccentable()
                    Text("\(last.routine.title) · \(last.minutes) min")
                        .font(.caption2)
                } else {
                    Text("None yet").font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Last workout")
        .description("How long since you last trained.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Streak (small)

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Streak", provider: SnapProvider()) { entry in
            let snap = entry.snap
            let left = max(0, snap.weeklyTarget - snap.weekCount(entry.date))
            VStack(alignment: .leading, spacing: 0) {
                Caption("STREAK")
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(snap.streak(entry.date))")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(WP.accent)
                    Text("weeks")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(WP.sub)
                }
                Spacer(minLength: 0)
                Text(left == 0 ? "This week's done" : "\(left) more this week")
                    .font(.system(size: 12))
                    .foregroundStyle(WP.sub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("Streak")
        .description("Weeks in a row with at least one workout.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Lift trend (small)

private struct Sparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let lo = values.min() ?? 0
            let hi = values.max() ?? 1
            let span = max(1, hi - lo)
            Path { p in
                for (i, v) in values.enumerated() {
                    let x = values.count > 1 ? geo.size.width * CGFloat(i) / CGFloat(values.count - 1) : 0
                    let y = geo.size.height * (1 - CGFloat((v - lo) / span))
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(WP.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

struct TrendWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Trend", provider: SnapProvider()) { entry in
            VStack(alignment: .leading, spacing: 6) {
                if let t = entry.snap.trend, let last = t.weights.last, let first = t.weights.first {
                    Caption(t.name.uppercased())
                    Sparkline(values: t.weights)
                        .padding(.vertical, 4)
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(WidgetSnapshot.fmt(last)) lb")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WP.ink)
                        Spacer()
                        Text((last - first >= 0 ? "+" : "") + WidgetSnapshot.fmt(last - first))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(last > first ? WP.good : WP.sub)
                    }
                } else {
                    Caption("LIFT TREND")
                    Spacer(minLength: 0)
                    Text("Log an exercise twice to see its trend.")
                        .font(.system(size: 12))
                        .foregroundStyle(WP.sub)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("Lift trend")
        .description("Top-set weight for your most recent lift.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Move up (small)

struct MoveUpWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MoveUp", provider: SnapProvider()) { entry in
            Group {
                if let m = entry.snap.moveUp {
                    VStack(alignment: .leading, spacing: 0) {
                        Caption("MOVE UP?")
                        Spacer(minLength: 0)
                        Text(m.name)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(WP.ink)
                            .lineLimit(2)
                        Text("\(m.sessions) sessions at \(WidgetSnapshot.fmt(m.weight)) lb. Try \(WidgetSnapshot.fmt(m.next)).")
                            .font(.system(size: 12))
                            .foregroundStyle(WP.sub)
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                        StartPill(title: "Load \(WidgetSnapshot.fmt(m.next)) lb", filled: false)
                    }
                    .widgetURL(Links.moveUp(m.id))
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Caption("MOVE UP?")
                        Spacer(minLength: 0)
                        Text("Nothing stuck")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(WP.ink)
                        Text("You'll get a nudge here after 6 sessions at the same weight.")
                            .font(.system(size: 12))
                            .foregroundStyle(WP.sub)
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("Move up")
        .description("Suggests a heavier weight when you've stalled.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Bundle

@main
struct IronlogWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekWidget()
        NextWorkoutWidget()
        LastWorkoutWidget()
        StreakWidget()
        TrendWidget()
        MoveUpWidget()
        WorkoutLiveActivity()
    }
}
