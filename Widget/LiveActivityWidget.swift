import ActivityKit
import SwiftUI
import WidgetKit

// Lock screen, Dynamic Island and Watch Smart Stack card for an active workout.

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
                .activityBackgroundTint(Palette.stored.deepColor.opacity(0.9))
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
                    .foregroundStyle(Palette.stored.swatchDark)
            } minimal: {
                Image(systemName: "timer")
            }
            .keylineTint(Palette.stored.swatchDark)
        }
        .supplementalActivityFamilies([.small])
    }
}
