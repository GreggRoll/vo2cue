import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HistoryStats(
                        completedSessions: model.completedSessions,
                        totalSeconds: model.totalActiveSeconds
                    )
                }

                Section("Recent workouts") {
                    if model.history.isEmpty {
                        ContentUnavailableView(
                            "No workouts yet",
                            systemImage: "figure.run.circle",
                            description: Text("Finished workouts will appear here.")
                        )
                    } else {
                        ForEach(model.history) { record in
                            HistoryRow(record: record)
                        }
                        .onDelete(perform: model.deleteHistory)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !model.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) { confirmClear = true }
                    }
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $confirmClear) {
                Button("Clear history", role: .destructive) { model.clearHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes local VO2Cue history. Workouts already saved in Apple Health are not removed.")
            }
        }
    }
}

private struct HistoryStats: View {
    let completedSessions: Int
    let totalSeconds: Int

    var body: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(completedSessions)", label: "Completed")
            StatTile(value: "\(totalSeconds / 60)", label: "Total minutes")
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryRow: View {
    let record: WorkoutRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.completed ? "checkmark.circle.fill" : "stop.circle")
                .foregroundStyle(record.completed ? .green : .orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.profileName)
                    .font(.headline)
                Text(record.startedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.activeSeconds.timerText)
                .font(.body.monospacedDigit())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.profileName), \(record.completed ? "completed" : "ended early"), \(record.activeSeconds.timerText), \(record.startedAt.formatted(date: .abbreviated, time: .shortened))")
    }
}
