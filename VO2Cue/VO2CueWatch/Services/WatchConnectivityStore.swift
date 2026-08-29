import Foundation
import OSLog
import WatchConnectivity

@MainActor
final class WatchConnectivityStore: NSObject, WCSessionDelegate {
    private var profilesHandler: (([WorkoutProfile]) -> Void)?
    private var pendingProfiles: [WorkoutProfile]?
    private let logger = Logger(subsystem: "com.gregadams.vo2cue.watchkitapp", category: "WatchConnectivity")

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func setProfilesHandler(_ handler: @escaping ([WorkoutProfile]) -> Void) {
        profilesHandler = handler

        if let pendingProfiles {
            deliver(pendingProfiles)
        } else if WCSession.isSupported() {
            receive(payload: WCSession.default.receivedApplicationContext)
        }
    }

    func send(record: WorkoutRecord) {
        guard WCSession.isSupported() else { return }

        do {
            let payload = try WatchConnectivityPayload.encodeRecord(record)
            WCSession.default.transferUserInfo(payload)
        } catch {
            logger.error("Could not encode workout record: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deliver(_ profiles: [WorkoutProfile]) {
        guard !profiles.isEmpty else { return }
        pendingProfiles = nil
        profilesHandler?(profiles)
    }

    @discardableResult
    nonisolated private func receive(payload: [String: Any]) -> Bool {
        guard let profiles = WatchConnectivityPayload.decodeProfiles(from: payload),
              !profiles.isEmpty else { return false }
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.profilesHandler == nil {
                self.pendingProfiles = profiles
            } else {
                self.deliver(profiles)
            }
        }
        return true
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            logger.error("Watch session activation failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard activationState == .activated else { return }
        receive(payload: session.receivedApplicationContext)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        receive(payload: applicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(payload: message)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        replyHandler(["received": receive(payload: message)])
    }
}
