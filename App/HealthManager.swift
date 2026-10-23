import Foundation
import HealthKit

@MainActor
final class HealthManager: ObservableObject {
    private let store = HKHealthStore()
    @Published var status = "Not asked yet"

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = "Health isn't available on this device"
            return
        }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            status = "Asked. Check Settings > Health > Data Access."
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }

    /// Writes a one-minute strength workout so we can confirm saving works.
    func saveTestWorkout() async {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        let end = Date()
        let start = end.addingTimeInterval(-60)
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
            status = "Saved a 1-minute test workout. Delete it in Health whenever."
        } catch {
            status = "Save failed: \(error.localizedDescription)"
        }
    }
}
