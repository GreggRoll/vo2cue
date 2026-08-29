import Foundation
import Observation

enum WorkoutRuntimeStatus: Equatable, Sendable {
    case idle
    case running
    case paused
    case completed
    case ended
}

enum WorkoutRuntimeEvent: Equatable, Sendable {
    case phaseChanged(WorkoutPhase)
    case countdown(Int)
    case halfway(WorkoutPhase)
    case finished(completed: Bool)
}

@MainActor
@Observable
final class WorkoutRuntime: Identifiable {
    let id = UUID()
    let profile: WorkoutProfile
    let timeline: WorkoutTimeline

    private(set) var status: WorkoutRuntimeStatus = .idle
    private(set) var snapshot: WorkoutSnapshot
    private(set) var startedAt: Date?
    private(set) var endedAt: Date?

    @ObservationIgnored private var accumulatedElapsed: TimeInterval = 0
    @ObservationIgnored private var resumeAnchor: Date?
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var lastCountdownValue: Int?
    @ObservationIgnored private var halfwayPhaseIDs: Set<UUID> = []
    @ObservationIgnored private let eventHandler: (WorkoutRuntimeEvent) -> Void

    init(
        profile: WorkoutProfile,
        eventHandler: @escaping (WorkoutRuntimeEvent) -> Void = { _ in }
    ) {
        let cleanProfile = profile.sanitized
        let timeline = WorkoutTimeline(profile: cleanProfile)
        self.profile = cleanProfile
        self.timeline = timeline
        self.eventHandler = eventHandler
        self.snapshot = timeline.snapshot(at: 0)!
    }

    var elapsedSeconds: Int {
        Int(snapshot.elapsedSeconds.rounded(.down))
    }

    var nextPhase: WorkoutPhase? {
        timeline.nextPhase(after: snapshot.phaseIndex)
    }

    func start(at date: Date = Date()) {
        guard status == .idle else { return }
        startedAt = date
        resumeAnchor = date
        status = .running
        eventHandler(.phaseChanged(snapshot.phase))
        startTicker()
    }

    func pause(at date: Date = Date()) {
        guard status == .running, let resumeAnchor else { return }
        accumulatedElapsed += max(0, date.timeIntervalSince(resumeAnchor))
        self.resumeAnchor = nil
        status = .paused
        update(at: date)
    }

    func resume(at date: Date = Date()) {
        guard status == .paused else { return }
        resumeAnchor = date
        status = .running
        startTicker()
    }

    func skip(at date: Date = Date()) {
        guard status == .running || status == .paused else { return }
        let nextElapsed = TimeInterval(timeline.phaseEndSeconds(at: snapshot.phaseIndex))
        accumulatedElapsed = nextElapsed
        resumeAnchor = status == .running ? date : nil
        lastCountdownValue = nil
        update(at: date)
    }

    func end(at date: Date = Date()) {
        guard status == .running || status == .paused else { return }
        if status == .running, let resumeAnchor {
            accumulatedElapsed += max(0, date.timeIntervalSince(resumeAnchor))
        }
        self.resumeAnchor = nil
        endedAt = date
        status = .ended
        ticker?.cancel()
        updateSnapshot(elapsed: min(accumulatedElapsed, TimeInterval(timeline.totalDurationSeconds)))
        eventHandler(.finished(completed: false))
    }

    func update(at date: Date = Date()) {
        guard status == .running || status == .paused else { return }
        var elapsed = accumulatedElapsed
        if status == .running, let resumeAnchor {
            elapsed += max(0, date.timeIntervalSince(resumeAnchor))
        }

        if elapsed >= TimeInterval(timeline.totalDurationSeconds) {
            accumulatedElapsed = TimeInterval(timeline.totalDurationSeconds)
            resumeAnchor = nil
            updateSnapshot(elapsed: accumulatedElapsed)
            endedAt = date
            status = .completed
            ticker?.cancel()
            eventHandler(.finished(completed: true))
            return
        }

        updateSnapshot(elapsed: elapsed)
    }

    private func updateSnapshot(elapsed: TimeInterval) {
        guard let newSnapshot = timeline.snapshot(at: elapsed) else { return }
        let previous = snapshot
        snapshot = newSnapshot

        if newSnapshot.phaseIndex != previous.phaseIndex {
            lastCountdownValue = nil
            eventHandler(.phaseChanged(newSnapshot.phase))
        }

        let countdown = newSnapshot.remainingSeconds
        if profile.countdownSeconds > 0,
           countdown > 0,
           countdown <= profile.countdownSeconds,
           countdown != lastCountdownValue {
            lastCountdownValue = countdown
            eventHandler(.countdown(countdown))
        }

        let halfway = Double(newSnapshot.phase.durationSeconds) / 2
        if profile.cues.halfwayCueEnabled,
           newSnapshot.phaseElapsedSeconds >= halfway,
           !halfwayPhaseIDs.contains(newSnapshot.phase.id) {
            halfwayPhaseIDs.insert(newSnapshot.phase.id)
            eventHandler(.halfway(newSnapshot.phase))
        }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled, let self else { return }
                self.update()
            }
        }
    }
}
