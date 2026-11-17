import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    @StateObject private var timeManager = EarnedTimeManager.shared

    @State private var isWorkoutPresented = false

    @State private var activeWorkoutTarget: (
        title: String,
        reps: Int,
        rewardMinutes: Int
    ) = ("Squats", 20, 0)

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
                usedMinutes: timeManager.usedTodayMinutes,
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
            FocusTimerManager.shared.requestNotificationPermission()
        }

        // Open exercise when timer finishes.
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("StartMovoExercise")
            )
        ) { _ in
            activeWorkoutTarget = ("Squats", 20, 10)
            isWorkoutPresented = true
        }

        // Exercise camera.
        .fullScreenCover(isPresented: $isWorkoutPresented) {

            WorkoutCameraSheet(
                exerciseTitle: activeWorkoutTarget.title,
                targetReps: activeWorkoutTarget.reps,
                rewardMinutes: activeWorkoutTarget.rewardMinutes,
                onComplete: { earned in
                    FocusTimerManager.shared.exerciseCompleted(minutes: earned)
                }
            )
        }
    }
}


// Simple prototype settings screen (no Screen Time / Family Controls).
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("Movo helps you break doomscrolling: when your focus time runs out, do an exercise to earn more.")
                        .font(.subheadline)
                }

                Section("Daily allowance") {
                    Text("30 minutes + time earned from challenges")
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
