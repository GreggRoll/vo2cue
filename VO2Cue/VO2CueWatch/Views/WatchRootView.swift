import SwiftUI

struct WatchRootView: View {
    @Environment(WatchAppModel.self) private var model

    var body: some View {
        if let runtime = model.runtime {
            WatchRuntimeView(runtime: runtime)
        } else {
            NavigationStack {
                List {
                    ForEach(model.profiles) { profile in
                        NavigationLink(value: profile.id) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.name)
                                    .font(.headline)
                                Text("\(profile.repeatCount) × \(profile.workSeconds.timerText)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .navigationTitle("VO2Cue")
                .navigationDestination(for: UUID.self) { id in
                    if let profile = model.profiles.first(where: { $0.id == id }) {
                        WatchProfileView(profile: profile)
                    }
                }
            }
        }
    }
}

private struct WatchProfileView: View {
    @Environment(WatchAppModel.self) private var model
    let profile: WorkoutProfile

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "waveform.path.ecg")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(profile.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(profile.estimatedDuration.timerText)
                    .font(.title2.bold().monospacedDigit())
                Text("\(profile.repeatCount) rounds • \(profile.workSeconds.timerText) hard • \(profile.recoverySeconds.timerText) recover")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Start", systemImage: "play.fill") {
                    model.start(profile)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .navigationTitle("Workout")
    }
}
