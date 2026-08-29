import Foundation
import HealthKit
import Observation

enum HealthAuthorizationState: Equatable {
    case notDetermined
    case available
    case denied
    case unavailable

    var title: String {
        switch self {
        case .notDetermined: "Not requested"
        case .available: "Ready"
        case .denied: "Not allowed"
        case .unavailable: "Unavailable"
        }
    }
}

@MainActor
@Observable
final class HealthStore {
    private(set) var authorizationState: HealthAuthorizationState
    private(set) var isRequestingAuthorization = false
    private(set) var lastErrorMessage: String?

    @ObservationIgnored private let healthStore = HKHealthStore()

    init() {
        authorizationState = .notDetermined
        refreshAuthorizationState()
    }

    func refreshAuthorizationState() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return
        }

        switch healthStore.authorizationStatus(for: HKObjectType.workoutType()) {
        case .notDetermined:
            authorizationState = .notDetermined
        case .sharingAuthorized:
            authorizationState = .available
        case .sharingDenied:
            authorizationState = .denied
        @unknown default:
            authorizationState = .notDetermined
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .unavailable
            return false
        }
        guard !isRequestingAuthorization else {
            return authorizationState == .available
        }

        isRequestingAuthorization = true
        lastErrorMessage = nil
        defer { isRequestingAuthorization = false }

        do {
            let workoutType = HKObjectType.workoutType()
            try await healthStore.requestAuthorization(toShare: [workoutType], read: [workoutType])
            refreshAuthorizationState()
            return authorizationState == .available
        } catch {
            refreshAuthorizationState()
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func save(_ record: WorkoutRecord) async {
        if authorizationState != .available {
            guard await requestAuthorization() else { return }
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = record.activity.healthKitType
        configuration.locationType = record.activity.locationType

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: .local()
        )

        do {
            try await builder.beginCollection(at: record.startedAt)
            try await builder.endCollection(at: record.endedAt)
            _ = try await builder.finishWorkout()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }
}
