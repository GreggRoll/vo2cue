import XCTest

final class WorkoutTimelineTests: XCTestCase {
    func testCustomProfilesRoundTripThroughWatchConnectivityPayload() throws {
        var customProfile = WorkoutProfile.norwegian4x4
        customProfile.name = "Pool intervals"
        customProfile.activity = .swimming
        customProfile.repeatCount = 6

        let payload = try WatchConnectivityPayload.encodeProfiles([customProfile])
        let decoded = try XCTUnwrap(WatchConnectivityPayload.decodeProfiles(from: payload))

        XCTAssertEqual(decoded, [customProfile])
    }

    func testDefaultWorkoutMatchesClassicFourByFour() {
        let profile = WorkoutProfile.norwegian4x4
        let timeline = WorkoutTimeline(profile: profile)

        XCTAssertEqual(timeline.phases.count, 8)
        XCTAssertEqual(timeline.totalDurationSeconds, 35 * 60)
        XCTAssertEqual(timeline.phases.map(\.kind), [
            .warmup,
            .work, .recovery,
            .work, .recovery,
            .work, .recovery,
            .work
        ])
        XCTAssertEqual(timeline.phases.filter { $0.kind == .work }.map(\.round), [1, 2, 3, 4])
        XCTAssertEqual(timeline.phases.last?.kind, .work)
    }

    func testCooldownAndNoWarmupProduceExpectedSchedule() {
        var profile = WorkoutProfile.norwegian4x4
        profile.warmupSeconds = 0
        profile.repeatCount = 2
        profile.cooldownSeconds = 300

        let timeline = WorkoutTimeline(profile: profile)

        XCTAssertEqual(timeline.phases.map(\.kind), [.work, .recovery, .work, .cooldown])
        XCTAssertEqual(timeline.totalDurationSeconds, 240 + 180 + 240 + 300)
    }

    func testSnapshotChangesPhaseAtExactBoundary() throws {
        let timeline = WorkoutTimeline(profile: .norwegian4x4)

        let warmup = try XCTUnwrap(timeline.snapshot(at: 599.2))
        XCTAssertEqual(warmup.phase.kind, .warmup)
        XCTAssertEqual(warmup.remainingSeconds, 1)

        let work = try XCTUnwrap(timeline.snapshot(at: 600))
        XCTAssertEqual(work.phase.kind, .work)
        XCTAssertEqual(work.phase.round, 1)
        XCTAssertEqual(work.remainingSeconds, 240)
        XCTAssertEqual(work.progress, 0)
    }

    func testSnapshotClampsBeforeAndAfterTimeline() throws {
        let timeline = WorkoutTimeline(profile: .norwegian4x4)

        XCTAssertEqual(try XCTUnwrap(timeline.snapshot(at: -10)).elapsedSeconds, 0)
        let end = try XCTUnwrap(timeline.snapshot(at: 10_000))
        XCTAssertEqual(end.elapsedSeconds, TimeInterval(timeline.totalDurationSeconds))
        XCTAssertEqual(end.remainingSeconds, 0)
        XCTAssertEqual(end.totalRemainingSeconds, 0)
        XCTAssertEqual(end.progress, 1)
    }

    func testProfileSanitizationProtectsRuntimeBounds() {
        let profile = WorkoutProfile(
            name: "   ",
            warmupSeconds: -1,
            workSeconds: 0,
            recoverySeconds: 0,
            repeatCount: 100,
            cooldownSeconds: -20,
            countdownSeconds: 99,
            hardCueLabel: " ",
            recoveryCueLabel: " ",
            cues: CueSettings()
        ).sanitized

        XCTAssertEqual(profile.name, "Untitled workout")
        XCTAssertEqual(profile.warmupSeconds, 0)
        XCTAssertEqual(profile.workSeconds, 5)
        XCTAssertEqual(profile.recoverySeconds, 5)
        XCTAssertEqual(profile.repeatCount, 20)
        XCTAssertEqual(profile.cooldownSeconds, 0)
        XCTAssertEqual(profile.countdownSeconds, 10)
        XCTAssertEqual(profile.hardCueLabel, "Hard")
        XCTAssertEqual(profile.recoveryCueLabel, "Recover")
    }

    @MainActor
    func testRuntimePauseResumeUsesActiveTimeOnly() {
        var profile = WorkoutProfile.norwegian4x4
        profile.warmupSeconds = 10
        profile.repeatCount = 1
        profile.workSeconds = 10
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let runtime = WorkoutRuntime(profile: profile)

        runtime.start(at: start)
        runtime.update(at: start.addingTimeInterval(4))
        runtime.pause(at: start.addingTimeInterval(4))
        runtime.update(at: start.addingTimeInterval(100))
        XCTAssertEqual(runtime.elapsedSeconds, 4)

        runtime.resume(at: start.addingTimeInterval(100))
        runtime.update(at: start.addingTimeInterval(103))
        XCTAssertEqual(runtime.elapsedSeconds, 7)
        runtime.end(at: start.addingTimeInterval(103))
    }

    @MainActor
    func testRuntimeEmitsCountdownTransitionHalfwayAndCompletion() {
        let profile = WorkoutProfile(
            name: "Test",
            warmupSeconds: 0,
            workSeconds: 6,
            recoverySeconds: 5,
            repeatCount: 1,
            cooldownSeconds: 0,
            countdownSeconds: 3,
            hardCueLabel: "Go",
            recoveryCueLabel: "Easy",
            cues: CueSettings(halfwayCueEnabled: true)
        )
        var events: [WorkoutRuntimeEvent] = []
        let start = Date(timeIntervalSinceReferenceDate: 2_000)
        let runtime = WorkoutRuntime(profile: profile) { events.append($0) }

        runtime.start(at: start)
        runtime.update(at: start.addingTimeInterval(3.1))
        runtime.update(at: start.addingTimeInterval(4.1))
        runtime.update(at: start.addingTimeInterval(5.1))
        runtime.update(at: start.addingTimeInterval(6))

        XCTAssertTrue(events.contains { if case .phaseChanged = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .halfway = $0 { true } else { false } })
        XCTAssertTrue(events.contains(.countdown(3)))
        XCTAssertTrue(events.contains(.countdown(2)))
        XCTAssertTrue(events.contains(.countdown(1)))
        XCTAssertTrue(events.contains(.finished(completed: true)))
        XCTAssertEqual(runtime.status, .completed)
    }

    @MainActor
    func testSkipMovesToNextPhase() {
        var profile = WorkoutProfile.norwegian4x4
        profile.warmupSeconds = 60
        let start = Date(timeIntervalSinceReferenceDate: 3_000)
        let runtime = WorkoutRuntime(profile: profile)

        runtime.start(at: start)
        runtime.skip(at: start.addingTimeInterval(1))

        XCTAssertEqual(runtime.snapshot.phase.kind, .work)
        XCTAssertEqual(runtime.snapshot.phase.round, 1)
        runtime.end(at: start.addingTimeInterval(1))
    }
}
