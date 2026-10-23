import SwiftUI
import WidgetKit

struct NextEntry: TimelineEntry {
    let date: Date
    let next: String
    let last: String
    let shared: Bool

    static func current() -> NextEntry {
        let last: String
        if let d = SharedStore.lastDate() {
            last = "Last: " + d.formatted(.relative(presentation: .named))
        } else {
            last = "No workouts yet"
        }
        return NextEntry(date: Date(), next: SharedStore.nextRoutine().title, last: last, shared: SharedStore.groupWorks)
    }
}

struct NextProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEntry {
        NextEntry(date: Date(), next: "Upper A", last: "Last: yesterday", shared: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextEntry) -> Void) {
        completion(NextEntry.current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEntry>) -> Void) {
        let entry = NextEntry.current()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
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
                    .foregroundStyle(Color(red: 0.09, green: 0.36, blue: 0.78))
                Spacer(minLength: 0)
                Text("UP NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(entry.next)
                    .font(.title2.weight(.bold))
                Text(entry.last)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.shared {
                    Text("No shared data")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
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
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.88, green: 0.95, blue: 1.0), Color(red: 0.66, green: 0.84, blue: 0.99)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Up next")
        .description("Your next routine and when you last trained.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

@main
struct IronlogWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextWorkoutWidget()
    }
}
