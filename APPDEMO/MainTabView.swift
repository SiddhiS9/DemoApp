
import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    @StateObject private var timeManager = EarnedTimeManager.shared
    @StateObject private var focusManager = FocusTimerManager.shared

    @State private var isWorkoutPresented = false

    @State private var activeWorkoutTarget: (
        title: String,
        reps: Int,
        rewardMinutes: Int
    ) = ("Squats", 20, 10)

    var body: some View {

        TabView(selection: $selectedTab) {

            // TIMER TAB
            FocusTimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(0)

            // CHALLENGES TAB
            EarnTimeView(
                balanceMinutes: timeManager.remainingMinutes,
                earnedToday: timeManager.earnedTodayMinutes,
                onSelectChallenge: { title, reps, reward in
                    activeWorkoutTarget = (title, reps, reward)
                    isWorkoutPresented = true
                }
            )
            .tabItem {
                Label("Challenges", systemImage: "figure.cross.training")
            }
            .tag(1)

            // ACTIVITY TAB
            ActivityView(
                usedMinutes: timeManager.focusedTodayMinutes,
                earnedMinutes: timeManager.earnedTodayMinutes
            )
            .tabItem {
                Label("Activity", systemImage: "flame")
            }
            .tag(2)

            // SETTINGS TAB
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.movoGreen)

        .onAppear {
            focusManager.requestNotificationPermission()

            if focusManager.needsExercise {
                selectedTab = 1
            }
        }

        // Automatically navigate to Challenges when time expires.
        .onChange(of: focusManager.needsExercise) { _, needsExercise in
            if needsExercise {
                selectedTab = 1
            }
        }

        // Show the selected exercise camera.
        .fullScreenCover(isPresented: $isWorkoutPresented) {

            WorkoutCameraSheet(
                exerciseTitle: activeWorkoutTarget.title,
                targetReps: activeWorkoutTarget.reps,
                rewardMinutes: activeWorkoutTarget.rewardMinutes,
                onComplete: { earned in
                    focusManager.exerciseCompleted(minutes: earned)
                    selectedTab = 0
                }
            )
        }
    }
}


// MARK: - Settings

struct SettingsView: View {

    var body: some View {

        NavigationStack {
            List {

                Section("About") {
                    Text("Movo helps you take advantage of your break: Focus, Exercise, then Focus Up Again!")
                        .font(.subheadline)
                }

                Section {
                    Button("Reset focus timer", role: .destructive) {
                        FocusTimerManager.shared.reset()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
