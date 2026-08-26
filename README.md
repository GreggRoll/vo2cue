# VO2Cue: 4x4 Timer

VO2Cue is a VO2-focused 4x4 interval coach for Apple Watch, swimming, and eyes-free training.

V1.0 is implemented and running in TestFlight for iOS 17+ and watchOS 10+. Read the [VO2Cue Privacy Policy](https://greggroll.github.io/vo2cue/).

## Product Positioning

VO2Cue helps athletes complete Norwegian-style 4x4 sessions without staring at a clock. The app is designed around Apple Watch haptics first, with optional tones and voice cues for people who train in the pool, on a treadmill, on a bike, or anywhere a visual timer gets in the way.

The launch version is designed as a complete paid iOS app with an independent Apple Watch companion.

## V1 Features

- Run a default 4x4 VO2 session: warmup, four hard intervals, active recovery periods, and optional cooldown.
- Let users customize work duration, rest duration, loop count, countdown length, cue labels, warmup, and cooldown.
- Provide eyes-free guidance with Watch haptics, tones, and optional spoken cues.
- Support swimming as a primary use case while keeping the app useful for running, cycling, rowing, and gym cardio.
- Save completed workouts to Apple Health when the user grants permission.
- Show simple local history such as completed sessions, total minutes, and recent workouts.
- Keep the app private: no account, no ads, no backend, and no third-party tracking.

## Default Workout

The default workout follows a classic 4x4 structure:

- Warmup: 10 minutes
- Hard interval: 4 minutes
- Active recovery: 3 minutes
- Repeats: 4
- Cooldown: optional

Users can customize the default session or create their own profiles.

## Cue System

VO2Cue is designed for workouts where looking at the screen is inconvenient or impossible.

- Haptics are the primary cue on Apple Watch.
- Tones distinguish countdown, start, sprint, recovery, halfway, and finish states.
- Voice cues can announce phrases such as "3, 2, 1", "Sprint", "Recover", and "Workout complete".
- Cue labels are customizable so users can choose words like Start, Sprint, Hard, Rest, Recover, Easy, or Jog.
- Cue settings can be customized per workout profile.

## Accessibility

The core accessibility promise is eyes-free completion: a user should be able to start a workout and finish it without reading the screen.

V1 accessibility support includes:

- VoiceOver-friendly controls and labels.
- Voice Control-friendly buttons and navigation.
- Large text and Dynamic Type support.
- High contrast layouts.
- Reduced motion support.
- Phase states that are not communicated by color alone.
- Clear haptic, audio, and visual alternatives for key workout events.

## Apple Watch And Health

The independent Apple Watch app can serve as the main workout runtime.

- Start, pause, resume, skip, and end workouts from the watch.
- Use Watch haptics for interval transitions and countdowns.
- Request HealthKit permissions only when needed.
- Save completed workouts to Apple Health.
- Handle permission denial gracefully.

## Pricing

VO2Cue is planned as a $1.99 paid app on the iOS App Store.

The paid launch version should feel complete without requiring additional purchases. Optional future monetization may include voice packs, tone packs, and advanced workout templates, but the base timer, Apple Watch support, accessibility features, and HealthKit integration should remain part of the core product.

## Roadmap

### V1

- iOS setup and profile editor.
- Independent Apple Watch workout runtime.
- Haptics, tones, and optional voice cues.
- Custom 4x4 profiles.
- HealthKit workout saving.
- Simple local workout history.
- Accessibility-first UI.

### V1.1

- Additional tone packs.
- More cue customization.
- More polished workout summary screens.

### V1.2

- Optional voice packs.
- Shareable workout summaries.
- More preset workouts.

### Later

- Siri and Shortcuts support.
- Lock Screen and widget surfaces.
- iCloud sync for profiles and history.
- Deeper heart-rate summaries.
- Additional interval protocols such as 8x2, 3x6, 30/30, Tabata, and Zone 2 plus 4x4 templates.

## Privacy

VO2Cue is private by default. The complete [Privacy Policy](https://greggroll.github.io/vo2cue/) explains the app's data handling and HealthKit use.

- No account required.
- No ads.
- No third-party analytics.
- No backend required for V1.
- Workout profiles and history stay in the app's local storage.
- Health data is accessed only with permission and stays on the user's devices and in Apple Health.
- iPhone and Apple Watch exchange profiles and completed workout records directly through Apple's WatchConnectivity framework.
- Users can revoke Health access in Apple settings and delete local history from the app.

## Development Status

V1 is implemented as a native SwiftUI project for iOS 17+ and watchOS 10+. Version 1.0, build 1 was uploaded to TestFlight and reached Apple's `VALID` processing state on August 24, 2026.

The current build includes:

- The classic 35-minute Norwegian 4x4 profile, plus create, edit, duplicate, and delete support for custom profiles.
- Custom warmup, work, recovery, repeat count, optional cooldown, countdown length, activity type, cue labels, haptics, tones, voice, and halfway cues.
- A wall-clock-based workout engine with start, pause, resume, skip, early end, phase transitions, countdowns, and completion handling.
- An independent Apple Watch app with haptic-first cues, live controls, HealthKit workout sessions, and live heart rate when permission is available.
- WatchConnectivity profile sync from iPhone and completed-session transfer back to iPhone.
- Optional HealthKit workout saving with graceful denial and failure handling.
- Private on-device JSON persistence for profiles and workout history.
- Accessible SwiftUI controls, Dynamic Type, VoiceOver descriptions, high-contrast phase labels and icons, reduced-motion behavior, and non-color phase communication.
- A privacy manifest declaring no tracking or collected data, plus no account, analytics SDK, ads, or backend.
- Eight unit tests and two UI integration tests covering schedule boundaries, timer state, cue events, profile creation, live workout controls, and history.

## Project Structure

- `VO2Cue/Shared`: workout profiles, phase timeline, runtime, cues, and persistence shared by iOS and watchOS.
- `VO2Cue/VO2CueApp`: iPhone setup, profile editor, live runtime, history, settings, HealthKit, and WatchConnectivity.
- `VO2Cue/VO2CueWatch`: independent Watch UI, live HealthKit workout session, heart rate, haptics, and sync.
- `VO2Cue/VO2CueTests`: deterministic unit tests for the workout engine.
- `VO2Cue/VO2CueUITests`: end-to-end iPhone UI tests.

## Build And Test

Requirements:

- Xcode 26 or newer.
- iOS 17+ and watchOS 10+ deployment targets.
- A development team with HealthKit capability enabled for signed device builds.

Open `VO2Cue.xcodeproj` and run the shared `VO2Cue` scheme. The iPhone app embeds the independent `VO2CueWatch` app.

Command-line checks:

```sh
xcodebuild \
  -project VO2Cue.xcodeproj \
  -scheme VO2Cue \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild \
  -project VO2Cue.xcodeproj \
  -scheme VO2Cue \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO
```

HealthKit cannot be fully exercised without granting permission on a simulator or signed Apple device. Denial is intentionally non-blocking: VO2Cue continues to time workouts and store local history.
