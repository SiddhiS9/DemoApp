import SwiftUI

struct MainTabView: View {
    @Binding var isWorkoutPresented: Bool
    @EnvironmentObject private var state: AppState

    @State private var selectedTab = 0
    @State private var activeExercise: Exercise = .squats
    @State private var showManageApps = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                availableMinutes: state.availableMinutes,
                usedMinutes: state.usedToday,
                earnedMinutes: state.earnedToday,
                onStartChallenge: { startWorkout(.squats) },
                onManageApps: { showManageApps = true }
            )
            .tabItem { Label("Today", systemImage: "house") }
            .tag(0)

            EarnTimeView(
                balanceMinutes: state.availableMinutes,
                earnedToday: state.earnedToday,
                onSelectChallenge: { exercise in startWorkout(exercise) }
            )
            .tabItem { Label("Earn time", systemImage: "figure.cross.training") }
            .tag(1)

            ActivityView(
                usedMinutes: state.usedToday,
                earnedMinutes: state.earnedToday
            )
            .tabItem { Label("Activity", systemImage: "flame") }
            .tag(2)

            ProfileView(onManageApps: { showManageApps = true })
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(3)
        }
        .tint(.movoGreen)
        .sheet(isPresented: $showManageApps) {
            ManageAppsView()
        }
        .fullScreenCover(isPresented: $isWorkoutPresented) {
            WorkoutCameraSheet(
                exerciseTitle: activeExercise.displayName,
                targetReps: activeExercise.targetReps,
                rewardMinutes: activeExercise.rewardMinutes,
                onComplete: { _ in state.logWorkout(activeExercise) }
            )
        }
    }

    private func startWorkout(_ exercise: Exercise) {
        activeExercise = exercise
        isWorkoutPresented = true
    }
}
