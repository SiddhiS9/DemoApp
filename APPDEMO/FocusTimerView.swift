
import SwiftUI

struct FocusTimerView: View {

    @StateObject private var manager = FocusTimerManager.shared
    @State private var selectedMinutes = 25

    private let durations = [5, 10, 15, 25, 30, 45, 60]

    var body: some View {

        NavigationStack {
            VStack(spacing: 30) {

                Spacer()

                Text(
                    manager.needsExercise
                    ? "Time to Move!"
                    : manager.isRunning
                    ? "Stay Focused"
                    : "Ready to Focus?"
                )
                .font(.largeTitle.bold())

                Text(manager.formattedTime)
                    .font(
                        .system(
                            size: 76,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(Color.movoGreen)

                if manager.needsExercise {

                    Image(systemName: "figure.run")
                        .font(.system(size: 55))
                        .foregroundStyle(Color.movoGreen)

                    Text("Your focus session is over.")
                        .font(.headline)

                    Text("Choose an exercise from the Challenges tab to earn more time.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                } else if manager.isRunning {

                    Text("Keep going. You've got this!")
                        .foregroundStyle(.secondary)

                    Button("End Session") {
                        manager.pause()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                } else {

                    Text("Choose your focus duration")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {

                        ForEach(durations, id: \.self) { minutes in

                            Button {
                                selectedMinutes = minutes
                            } label: {

                                Text("\(minutes)")
                                    .font(.headline)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selectedMinutes == minutes
                                        ? Color.movoGreen
                                        : Color.gray.opacity(0.15)
                                    )
                                    .foregroundStyle(
                                        selectedMinutes == minutes
                                        ? .white
                                        : .primary
                                    )
                                    .clipShape(Circle())
                            }
                        }
                    }

                    Button("Test: 5 Seconds") {
                        manager.startTest(seconds: 5)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.movoGreen)

                    Button("Start Focus Session") {
                        manager.start(minutes: selectedMinutes)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.movoGreen)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Movo")
            .background(Color(.systemGroupedBackground))
        }
    }
}
