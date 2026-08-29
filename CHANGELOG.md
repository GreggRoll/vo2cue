# Changelog

All notable VO2Cue changes are documented here.

## 1.0 (2) — 2026-08-28

### Fixed

- Made the Health access action show request progress and a clear success, denial, unavailable, or failure result instead of appearing unresponsive after a previous decision.
- Restored the saved Health authorization state when the app launches or returns from Settings.
- Added a direct route to app Settings when Health workout access has been denied.
- Made custom workout profile sync wait for WatchConnectivity activation instead of dropping early updates.
- Added automatic retry when Apple Watch pairing, installation, or reachability changes.
- Added immediate acknowledged profile delivery when Apple Watch is reachable while retaining durable application-context delivery for disconnected use.
- Preserved profiles received before the Apple Watch model finishes installing its handler.

### Changed

- Added Apple Watch sync status beneath the workout list.
- Centralized and tested the shared WatchConnectivity payload format.
- Bumped the iPhone and Apple Watch build numbers to 2.

### Validation

- Verified the Health authorization sheet on iOS Simulator.
- Passed all nine unit tests and two UI integration tests.
- Archived the iPhone and embedded Apple Watch apps with App Store distribution signing.
- Uploaded version 1.0, build 2 to TestFlight; App Store Connect reported `VALID`.

## 1.0 (1) — 2026-08-24

### Added

- Initial TestFlight release of the SwiftUI iPhone and independent Apple Watch apps.
- Custom 4×4 workout profiles, eyes-free cues, local workout history, and HealthKit workout saving.
- Apple Watch workout controls, haptics, live heart rate, and direct device-to-device profile and history transfer.
