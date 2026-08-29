import SwiftUI

@main
struct VO2CueWatchApp: App {
    @State private var model = WatchAppModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(model)
                .tint(.orange)
        }
    }
}
