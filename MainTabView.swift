import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var availableMinutes: Int = 45
    @State private var earnedToday: Int = 40
    @State private var usedToday: Int = 25
    @State private var isWorkoutPresented: Bool = false
    @State private var activeWorkoutTarget: (title: String, reps: Int, rewardMinutes: Int) = ("Squats", 20, 10)

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                availableMinutes: $availableMinutes,
                usedMinutes: usedToday,
                earnedMinutes: earnedToday,
                onStartChallenge: {
                    activeWorkoutTarget = ("Squats", 20, 10)
                    isWorkoutPresented = true
                }
            )
            .tabItem {
                Label("Today", systemImage: "house")
            }
            .tag(0)

            EarnTimeView(
                balanceMinutes: availableMinutes,
                earnedToday: earnedToday,
                onSelectChallenge: { title, reps, reward in
                    activeWorkoutTarget = (title, reps, reward)
                    isWorkoutPresented = true
                }
            )
            .tabItem {
                Label("Earn time", systemImage: "figure.cross.training")
            }
            .tag(1)

            ActivityView(
                usedMinutes: usedToday,
                earnedMinutes: earnedToday
            )
            .tabItem {
                Label("Activity", systemImage: "flame")
            }
            .tag(2)

            Text("Profile & Settings")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .tint(.movoGreen)
        .fullScreenCover(isPresented: $isWorkoutPresented) {
            WorkoutCameraSheet(
                exerciseTitle: activeWorkoutTarget.title,
                targetReps: activeWorkoutTarget.reps,
                rewardMinutes: activeWorkoutTarget.rewardMinutes,
                onComplete: { earned in
                    availableMinutes += earned
                    earnedToday += earned
                }
            )
        }
    }
}
