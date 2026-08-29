import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class WatchHealthSession: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private(set) var isActive = false
    private(set) var heartRate: Double?
    private(set) var lastErrorMessage: String?

    @ObservationIgnored private let healthStore = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?

    func start(profile: WorkoutProfile, at date: Date) async {
        guard await requestAuthorization() else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = profile.activity.healthKitType
        configuration.locationType = profile.activity.locationType

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            session.startActivity(with: date)
            try await builder.beginCollection(at: date)
            isActive = true
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            isActive = false
        }
    }

    func finish(at date: Date) async {
        guard let session, let builder else { return }
        session.end()
        do {
            try await builder.endCollection(at: date)
            _ = try await builder.finishWorkout()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        self.session = nil
        self.builder = nil
        isActive = false
        heartRate = nil
    }

    private func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let workoutType = HKObjectType.workoutType()
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        do {
            try await healthStore.requestAuthorization(
                toShare: [workoutType],
                read: [workoutType, heartRateType]
            )
            return healthStore.authorizationStatus(for: workoutType) != .sharingDenied
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            self?.isActive = toState == .running || toState == .paused
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        Task { @MainActor [weak self] in
            self?.lastErrorMessage = error.localizedDescription
            self?.isActive = false
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(type),
              let statistics = workoutBuilder.statistics(for: type),
              let quantity = statistics.mostRecentQuantity() else { return }
        let value = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        Task { @MainActor [weak self] in
            self?.heartRate = value
        }
    }
}
