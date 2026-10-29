import ActivityKit
import Foundation
import UIKit
import UserNotifications

/// Rest timer: in-app countdown, a notification when rest ends (buzzes the watch
/// when the phone is locked), and a lock screen Live Activity that shows only
/// while resting and removes itself the moment the countdown hits zero.
@MainActor
final class RestController: ObservableObject {
    typealias State = WorkoutActivityAttributes.ContentState

    @Published private(set) var endsAt: Date?
    @Published private(set) var startedAt: Date?

    private var endTask: Task<Void, Never>?
    private var lastState: State?
    private var routineName = "Workout"
    private var workoutStart = Date()

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Workout

    func beginWorkout(routine: String, startedAt: Date, first: String) {
        routineName = routine
        workoutStart = startedAt
        lastState = State(restEndsAt: nil, restStartedAt: nil, exercise: first, detail: "Set 1")
        endAllActivities()
    }

    func endWorkout() {
        cancelRest()
        lastState = nil
        endAllActivities()
    }

    /// Superset hand-off: no rest, so clear any countdown that's showing.
    func updateProgress(next: String, detail: String) {
        cancelRest()
        lastState = State(restEndsAt: nil, restStartedAt: nil, exercise: next, detail: detail)
        endAllActivities()
    }

    // MARK: Rest

    func start(seconds: Int, next: String, detail: String) {
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(seconds))
        startedAt = now
        endsAt = end
        let state = State(restEndsAt: end, restStartedAt: now, exercise: next, detail: detail)
        lastState = state
        scheduleNotification(end: end, next: next)
        showRestActivity(state, until: end)
        armEnd(end)
    }

    func add(_ seconds: Int) {
        guard let end = endsAt, var state = lastState else { return }
        let newEnd = end.addingTimeInterval(TimeInterval(seconds))
        endsAt = newEnd
        state.restEndsAt = newEnd
        lastState = state
        scheduleNotification(end: newEnd, next: state.exercise)
        showRestActivity(state, until: newEnd)
        armEnd(newEnd)
    }

    func skip() {
        cancelRest()
        endAllActivities()
    }

    private func cancelRest() {
        endsAt = nil
        startedAt = nil
        endTask?.cancel()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest"])
    }

    private func armEnd(_ end: Date) {
        endTask?.cancel()
        endTask = Task { [weak self] in
            let delay = end.timeIntervalSinceNow
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled, let self, self.endsAt == end else { return }
            self.endsAt = nil
            self.startedAt = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func scheduleNotification(end: Date, next: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["rest"])
        let content = UNMutableNotificationContent()
        content.title = "Rest's up"
        content.body = "Next: \(next)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: "rest", content: content, trigger: trigger))
    }

    // MARK: Live Activity

    /// Shows the countdown on the lock screen, then ends it right away with a
    /// dismissal time of `end`. iOS keeps it visible until then and removes it
    /// on its own, so it disappears at zero even if Ironlog is suspended.
    private func showRestActivity(_ state: State, until end: Date) {
        endAllActivities()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: state, staleDate: end)
        do {
            let activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: WorkoutActivityAttributes(routine: routineName, startedAt: workoutStart),
                content: content,
                pushType: nil
            )
            Task {
                await activity.end(content, dismissalPolicy: .after(end))
            }
        } catch {
            // Live Activities turned off; the notification still covers it.
        }
    }

    private func endAllActivities() {
        for a in Activity<WorkoutActivityAttributes>.activities {
            Task { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
