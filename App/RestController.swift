import ActivityKit
import Foundation
import UIKit
import UserNotifications

/// Rest timer: in-app countdown, a notification when rest ends (buzzes the watch
/// when the phone is locked), and the Live Activity on the lock screen.
@MainActor
final class RestController: ObservableObject {
    typealias State = WorkoutActivityAttributes.ContentState

    @Published private(set) var endsAt: Date?
    @Published private(set) var startedAt: Date?

    private var endTask: Task<Void, Never>?
    private var activity: Activity<WorkoutActivityAttributes>?
    private var lastState: State?

    init() {
        activity = Activity<WorkoutActivityAttributes>.activities.first
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Rest

    func start(seconds: Int, next: String, detail: String) {
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(seconds))
        startedAt = now
        endsAt = end
        scheduleNotification(end: end, next: next)
        update(State(restEndsAt: end, restStartedAt: now, exercise: next, detail: detail))
        armEnd(end)
    }

    func add(_ seconds: Int) {
        guard let end = endsAt, var state = lastState else { return }
        let newEnd = end.addingTimeInterval(TimeInterval(seconds))
        endsAt = newEnd
        state.restEndsAt = newEnd
        scheduleNotification(end: newEnd, next: state.exercise)
        update(state)
        armEnd(newEnd)
    }

    func skip() {
        cancelRest()
        if var state = lastState {
            state.restEndsAt = nil
            state.restStartedAt = nil
            update(state)
        }
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
            if var state = self.lastState {
                state.restEndsAt = nil
                state.restStartedAt = nil
                self.update(state)
            }
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

    func beginWorkout(routine: String, startedAt: Date, first: String) {
        let state = State(restEndsAt: nil, restStartedAt: nil, exercise: first, detail: "Set 1")
        lastState = state
        endAllActivities()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: WorkoutActivityAttributes(routine: routine, startedAt: startedAt),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func updateProgress(next: String, detail: String) {
        var state = lastState ?? State(restEndsAt: nil, restStartedAt: nil, exercise: next, detail: detail)
        state.exercise = next
        state.detail = detail
        update(state)
    }

    private func update(_ state: State) {
        lastState = state
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func endWorkout() {
        cancelRest()
        activity = nil
        lastState = nil
        endAllActivities()
    }

    private func endAllActivities() {
        for a in Activity<WorkoutActivityAttributes>.activities {
            Task { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
