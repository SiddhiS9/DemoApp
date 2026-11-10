import SwiftUI

struct WorkoutCameraSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseTitle: String
    let targetReps: Int
    let rewardMinutes: Int
    let onComplete: (Int) -> Void

    @State private var currentReps: Int = 0
    @State private var isGoalReached: Bool = false

    var body: some View {
        ZStack {
            // Camera Feed Placeholder (Member 1 embeds CameraPreviewView here)
            Color.black.ignoresSafeArea()

            VStack {
                // Top control bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("\(exerciseTitle) in Progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding()

                Spacer()

                // movo-styled white counter card
                VStack(spacing: 14) {
                    if isGoalReached {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(Color.movoGreen)
                            Text("Challenge Complete!")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Text("+\(rewardMinutes) minutes added to your balance.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text("\(currentReps) / \(targetReps)")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.movoDark)
                            Text("REPS COMPLETED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                        }

                        ProgressView(value: Double(currentReps), total: Double(targetReps))
                            .tint(Color.movoGreen)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(20)
            }
        }
        // Tap on screen to simulate rep counts until Member 1 wires in Vision
        .onTapGesture {
            guard !isGoalReached else { return }
            currentReps += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            if currentReps >= targetReps {
                isGoalReached = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete(rewardMinutes)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            }
        }
    }
}
