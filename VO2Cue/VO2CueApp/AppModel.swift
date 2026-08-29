import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var profiles: [WorkoutProfile]
    private(set) var history: [WorkoutRecord]
    private(set) var watchSyncStatus: WatchProfileSyncStatus = .activating
    var activeRuntime: WorkoutRuntime?
    var healthSavingEnabled: Bool {
        didSet { UserDefaults.standard.set(healthSavingEnabled, forKey: Self.healthSavingKey) }
    }

    let healthStore: HealthStore

    @ObservationIgnored private let cueCoordinator = CueCoordinator()
    @ObservationIgnored private let connectivity = PhoneWatchConnectivity()
    @ObservationIgnored private static let healthSavingKey = "healthSavingEnabled"

    init() {
        let savedProfiles = Persistence.load([WorkoutProfile].self, fileName: "profiles.json") ?? []
        profiles = savedProfiles.isEmpty ? [.norwegian4x4] : savedProfiles
        history = Persistence.load([WorkoutRecord].self, fileName: "history.json") ?? []
        healthSavingEnabled = UserDefaults.standard.object(forKey: Self.healthSavingKey) as? Bool ?? true
        healthStore = HealthStore()

        connectivity.setRecordHandler { [weak self] record in
            self?.storeWatchRecord(record)
        }
        connectivity.setStatusHandler { [weak self] status in
            self?.watchSyncStatus = status
        }
        persistProfiles()
    }

    var completedSessions: Int {
        history.count(where: \.completed)
    }

    var totalActiveSeconds: Int {
        history.reduce(0) { $0 + $1.activeSeconds }
    }

    func profile(id: UUID) -> WorkoutProfile? {
        profiles.first { $0.id == id }
    }

    func upsert(_ profile: WorkoutProfile) {
        let profile = profile.sanitized
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        profiles.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persistProfiles()
    }

    func duplicate(_ profile: WorkoutProfile) {
        var copy = WorkoutProfile(
            name: "\(profile.name) Copy",
            activity: profile.activity,
            warmupSeconds: profile.warmupSeconds,
            workSeconds: profile.workSeconds,
            recoverySeconds: profile.recoverySeconds,
            repeatCount: profile.repeatCount,
            cooldownSeconds: profile.cooldownSeconds,
            countdownSeconds: profile.countdownSeconds,
            hardCueLabel: profile.hardCueLabel,
            recoveryCueLabel: profile.recoveryCueLabel,
            cues: profile.cues
        )
        copy = copy.sanitized
        profiles.append(copy)
        persistProfiles()
    }

    func deleteProfiles(ids: Set<UUID>) {
        profiles.removeAll { ids.contains($0.id) }
        if profiles.isEmpty { profiles = [.norwegian4x4] }
        persistProfiles()
    }

    func start(_ profile: WorkoutProfile) {
        let runtime = WorkoutRuntime(profile: profile) { [weak self] event in
            guard let self else { return }
            self.cueCoordinator.handle(event, profile: profile)
            if case .finished(let completed) = event {
                self.storeFinished(runtime: self.activeRuntime, completed: completed)
            }
        }
        activeRuntime = runtime
        runtime.start()
    }

    func dismissRuntime() {
        activeRuntime = nil
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        persistHistory()
    }

    func clearHistory() {
        history.removeAll()
        persistHistory()
    }

    private func storeFinished(runtime: WorkoutRuntime?, completed: Bool) {
        guard let runtime,
              let startedAt = runtime.startedAt,
              let endedAt = runtime.endedAt else { return }
        let record = WorkoutRecord(
            profileID: runtime.profile.id,
            profileName: runtime.profile.name,
            activity: runtime.profile.activity,
            startedAt: startedAt,
            endedAt: endedAt,
            activeSeconds: runtime.elapsedSeconds,
            completed: completed
        )
        appendRecordIfNeeded(record)
        if healthSavingEnabled {
            Task { await healthStore.save(record) }
        }
    }

    private func storeWatchRecord(_ record: WorkoutRecord) {
        appendRecordIfNeeded(record)
    }

    private func appendRecordIfNeeded(_ record: WorkoutRecord) {
        guard !history.contains(where: { $0.id == record.id }) else { return }
        history.append(record)
        history.sort { $0.startedAt > $1.startedAt }
        persistHistory()
    }

    private func persistProfiles() {
        try? Persistence.save(profiles, fileName: "profiles.json")
        connectivity.sync(profiles: profiles)
    }

    private func persistHistory() {
        try? Persistence.save(history, fileName: "history.json")
    }
}
