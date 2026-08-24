# VO2Cue: 4x4 Timer

VO2Cue is a VO2-focused 4x4 interval coach for Apple Watch, swimming, and eyes-free training.

## Product Positioning

VO2Cue helps athletes complete Norwegian-style 4x4 sessions without staring at a clock. The app is designed around Apple Watch haptics first, with optional tones and voice cues for people who train in the pool, on a treadmill, on a bike, or anywhere a visual timer gets in the way.

The launch version is planned as a $1.99 paid iOS app with an independent Apple Watch companion.

## V1 Goals

- Run a default 4x4 VO2 session: warmup, four hard intervals, active recovery periods, and optional cooldown.
- Let users customize work duration, rest duration, loop count, countdown length, cue labels, warmup, and cooldown.
- Provide eyes-free guidance with Watch haptics, tones, and optional spoken cues.
- Support swimming as a primary use case while keeping the app useful for running, cycling, rowing, and gym cardio.
- Save completed workouts to Apple Health when the user grants permission.
- Show simple local history such as completed sessions, total minutes, and recent workouts.
- Keep the app private: no account, no ads, no backend, and no third-party tracking.

## Default Workout

The planned default workout follows a classic 4x4 structure:

- Warmup: 10 minutes
- Hard interval: 4 minutes
- Active recovery: 3 minutes
- Repeats: 4
- Cooldown: optional

Users will be able to customize the default session or create their own profiles.

## Cue System

VO2Cue is designed for workouts where looking at the screen is inconvenient or impossible.

- Haptics are the primary cue on Apple Watch.
- Tones distinguish countdown, start, sprint, recovery, halfway, and finish states.
- Voice cues can announce phrases such as "3, 2, 1", "Sprint", "Recover", and "Workout complete".
- Cue labels are customizable so users can choose words like Start, Sprint, Hard, Rest, Recover, Easy, or Jog.
- Future releases may add premium voice packs and tone packs.

## Accessibility

The core accessibility promise is eyes-free completion: a user should be able to start a workout and finish it without reading the screen.

Planned accessibility support includes:

- VoiceOver-friendly controls and labels.
- Voice Control-friendly buttons and navigation.
- Large text and Dynamic Type support.
- High contrast layouts.
- Reduced motion support.
- Phase states that are not communicated by color alone.
- Clear haptic, audio, and visual alternatives for key workout events.

## Apple Watch And Health

The Apple Watch app is planned as the main workout runtime.

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

VO2Cue is planned to be private by default.

- No account required.
- No ads.
- No third-party analytics.
- No backend required for V1.
- Health data stays on device and in Apple Health according to the user's permissions.

## Development Status

This repository currently contains the public product plan only. App code, project structure, design assets, and implementation details will be added in later commits.

