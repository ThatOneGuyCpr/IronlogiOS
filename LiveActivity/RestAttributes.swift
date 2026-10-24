import ActivityKit
import Foundation

/// Lock screen / Dynamic Island / Watch Smart Stack card for an active workout.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the current rest ends. Nil while lifting.
        var restEndsAt: Date?
        var restStartedAt: Date?
        /// Exercise to do next (or the one in progress).
        var exercise: String
        /// For example "Set 2 of 3" or "Last set done".
        var detail: String
    }

    var routine: String
    var startedAt: Date
}
