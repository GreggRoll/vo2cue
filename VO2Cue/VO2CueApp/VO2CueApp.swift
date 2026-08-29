import SwiftUI

@main
struct VO2CueApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(.orange)
        }
    }
}
