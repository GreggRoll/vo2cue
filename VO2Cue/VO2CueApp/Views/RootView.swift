import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Group {
            if #available(iOS 18.0, *) {
                TabView {
                    Tab("Workouts", systemImage: "figure.run") {
                        WorkoutsView()
                    }
                    Tab("History", systemImage: "clock.arrow.circlepath") {
                        HistoryView()
                    }
                    Tab("Settings", systemImage: "gearshape") {
                        SettingsView()
                    }
                }
            } else {
                TabView {
                    WorkoutsView()
                        .tabItem { Label("Workouts", systemImage: "figure.run") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
            }
        }
        .fullScreenCover(item: $model.activeRuntime) { runtime in
            WorkoutRuntimeView(runtime: runtime)
                .environment(model)
        }
    }
}
