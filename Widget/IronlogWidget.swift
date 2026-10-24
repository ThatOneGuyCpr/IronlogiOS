import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Up next widget

struct NextEntry: TimelineEntry {
    let date: Date
    let next: String
    let last: String

    static func current() -> NextEntry {
        let last: String
        if let d = SharedStore.lastDate() {
            last = "Last: " + d.formatted(.relative(presentation: .named))
        } else {
            last = "No workouts yet"
        }
        return NextEntry(date: Date(), next: SharedStore.nextRoutine().title, last: last)
    }
}

struct NextProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEntry {
        NextEntry(date: Date(), next: "Upper A", last: "Last: yesterday")
    }

    func getSnapshot(in context: Context, completion: @escaping (NextEntry) -> Void) {
        completion(NextEntry.current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEntry>) -> Void) {
        completion(Timeline(entries: [NextEntry.current()], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct WidgetSky: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.04, green: 0.10, blue: 0.21), Color(red: 0.07, green: 0.22, blue: 0.43)]
                : [Color(red: 0.89, green: 0.95, blue: 1.0), Color(red: 0.66, green: 0.84, blue: 0.99)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct NextWorkoutView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Up next").font(.caption2)
                Text(entry.next).font(.headline)
                Text(entry.last).font(.caption2)
            }
        default:
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.16, green: 0.47, blue: 0.93))
                Spacer(minLength: 0)
                Text("UP NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(entry.next)
                    .font(.title2.weight(.bold))
                Text(entry.last)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NextWorkoutWidget: Widget {
    let kind = "NextWorkout"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextProvider()) { entry in
            NextWorkoutView(entry: entry)
                .containerBackground(for: .widget) { WidgetSky() }
        }
        .configurationDisplayName("Up next")
        .description("Your next routine and when you last trained.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// MARK: - Live Activity (lock screen, Dynamic Island, Watch Smart Stack)

struct RestTimerText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if let end = state.restEndsAt, end > Date() {
            let start = min(state.restStartedAt ?? Date(), end)
            Text(timerInterval: start...end, countsDown: true)
        } else {
            Text("Lift")
        }
    }
}

struct WorkoutLockView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    @Environment(\.activityFamily) private var family

    private var small: Bool { family == .small }
    private var resting: Bool { (context.state.restEndsAt ?? .distantPast) > Date() }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.routine.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(context.state.exercise)
                    .font(small ? .caption.weight(.semibold) : .headline)
                    .foregroundStyle(Color.white)
                    .lineLimit(small ? 2 : 1)
                Text(context.state.detail)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                if resting {
                    Text("REST")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                RestTimerText(state: context.state)
                    .font(small ? .title3.weight(.semibold) : .system(size: 36, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: small ? 70 : 110, alignment: .trailing)
            }
        }
        .padding(small ? 8 : 16)
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockView(context: context)
                .activityBackgroundTint(Color(red: 0.07, green: 0.22, blue: 0.45).opacity(0.9))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.routine, systemImage: "dumbbell.fill")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RestTimerText(state: context.state)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exercise).font(.headline)
                        Text(context.state.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                RestTimerText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer")
            }
        }
        .supplementalActivityFamilies([.small])
    }
}

@main
struct IronlogWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextWorkoutWidget()
        WorkoutLiveActivity()
    }
}
