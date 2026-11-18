import SwiftUI

@main
struct movoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var screenTime = ScreenTimeManager()
    @State private var showWorkoutSheet: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView(isWorkoutPresented: $showWorkoutSheet)
                .environmentObject(appState)
                .environmentObject(screenTime)
                .onOpenURL { url in
                    if url.scheme == "movo" {
                        showWorkoutSheet = true
                    }
                }
                // Every time Movo opens, pull in usage the monitor extension counted
                // while we were in the background, and handle the midnight reset.
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active { appState.refresh() }
                }
                // Tapped the shield's "earn minutes" notification → go straight to the workout.
                .onChange(of: appDelegate.openWorkoutRequested, initial: true) { _, requested in
                    guard requested else { return }
                    appDelegate.openWorkoutRequested = false
                    showWorkoutSheet = true
                }
        }
    }
}
