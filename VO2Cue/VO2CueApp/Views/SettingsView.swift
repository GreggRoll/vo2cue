import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var healthAlertTitle = ""
    @State private var healthAlertMessage = ""
    @State private var healthAlertOffersSettings = false
    @State private var isShowingHealthAlert = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    Toggle("Save completed workouts", isOn: $model.healthSavingEnabled)
                    LabeledContent("Permission", value: model.healthStore.authorizationState.title)
                    Button {
                        requestHealthAccess()
                    } label: {
                        HStack(spacing: 10) {
                            if model.healthStore.isRequestingAuthorization {
                                ProgressView()
                            }
                            Text(model.healthStore.isRequestingAuthorization ? "Requesting Health access…" : "Request Health access")
                        }
                    }
                    .disabled(model.healthStore.isRequestingAuthorization)
                    if let error = model.healthStore.lastErrorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Apple Health")
                } footer: {
                    Text("VO2Cue asks only for workout permission. If access is denied, the timer and local history still work.")
                }

                Section("Privacy") {
                    Label("No account", systemImage: "person.crop.circle.badge.xmark")
                    Label("No ads or tracking", systemImage: "hand.raised")
                    Label("No backend", systemImage: "externaldrive")
                    Text("Your profiles and VO2Cue history stay on your devices. Health data is managed by Apple Health according to your permissions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    Text("VO2Cue is an eyes-free 4×4 interval coach for Apple Watch, swimming, running, cycling, rowing, and gym cardio.")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.healthStore.refreshAuthorizationState()
                }
            }
            .alert(healthAlertTitle, isPresented: $isShowingHealthAlert) {
                if healthAlertOffersSettings {
                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsURL)
                        }
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(healthAlertMessage)
            }
        }
    }

    private func requestHealthAccess() {
        Task {
            let allowed = await model.healthStore.requestAuthorization()
            healthAlertOffersSettings = false

            if let error = model.healthStore.lastErrorMessage {
                healthAlertTitle = "Couldn’t Request Health Access"
                healthAlertMessage = error
            } else if allowed {
                healthAlertTitle = "Health Access Ready"
                healthAlertMessage = "Completed workouts can now be saved to Apple Health."
            } else {
                switch model.healthStore.authorizationState {
                case .denied:
                    healthAlertTitle = "Health Access Is Off"
                    healthAlertMessage = "Allow VO2Cue to write workouts in Settings to save completed sessions to Apple Health."
                    healthAlertOffersSettings = true
                case .unavailable:
                    healthAlertTitle = "Apple Health Unavailable"
                    healthAlertMessage = "Apple Health isn’t available on this device."
                case .notDetermined, .available:
                    healthAlertTitle = "Health Access Not Changed"
                    healthAlertMessage = "No Health permissions were changed. You can try again or review VO2Cue in Settings."
                    healthAlertOffersSettings = true
                }
            }

            isShowingHealthAlert = true
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
