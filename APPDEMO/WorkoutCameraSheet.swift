import SwiftUI
import UIKit

struct WorkoutCameraSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exerciseTitle: String
    let targetReps: Int
    let rewardMinutes: Int
    let onComplete: (Int) -> Void

    @StateObject private var currentReps = RepCounter()
    @State private var isGoalReached = false

    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // TOP BAR
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("\(exerciseTitle) in Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding()

                Spacer()

                // CAMERA AREA
                #if targetEnvironment(simulator)

                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 65))
                        .foregroundStyle(Color.movoGreen)

                    Text("Workout Simulator")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Use the button below to simulate completed reps.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)

                #else

                ZStack(alignment: .bottom) {

                    CameraPreview(session: cameraManager.session)

                    GeometryReader { geometry in
                        ForEach(CameraManager.jointNames, id: \.self) { name in

                            if let point = cameraManager.posePoints[name] {
                                Circle()
                                    .fill(Color.movoGreen)
                                    .frame(width: 10, height: 10)
                                    .position(
                                        x: point.x * geometry.size.width,
                                        y: (1 - point.y) * geometry.size.height
                                    )
                            }
                        }
                    }

                    VStack(spacing: 5) {
                        Text(cameraManager.cameraStatus)
                            .font(.caption.bold())

                        Text("Exercise: \(cameraManager.predictedExercise)")
                            .font(.caption)

                        Text("Confidence: \(Int(cameraManager.predictionConfidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(12)
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)

                #endif

                Spacer()

                // REP COUNTER AND COMPLETION
                VStack(spacing: 18) {

                    if isGoalReached {

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.movoGreen)

                        Text("Challenge Complete!")
                            .font(.title2.bold())
                            .foregroundStyle(Color.movoDark)

                        Text("+\(rewardMinutes) minutes earned!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                    } else {

                        Text("\(currentReps.reps) / \(targetReps)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.movoDark)
                            // Demo backup: long-press to add a rep if the camera misses one.
                            .onLongPressGesture(minimumDuration: 1) {
                                currentReps.simulateRep()
                            }

                        Text("REPS COMPLETED")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(currentReps.movementStatus)
                            .font(.caption)
                            .foregroundStyle(Color.movoGreen)

                        ProgressView(
                            value: Double(currentReps.reps),
                            total: Double(max(targetReps, 1))
                        )
                        .tint(Color.movoGreen)
                        .padding(.horizontal, 20)
                    }

                    #if targetEnvironment(simulator)

                    if !isGoalReached {
                        Button {
                            currentReps.simulateRep();
                        } label: {
                            Label("Simulate 1 Rep", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.movoGreen)
                                .clipShape(Capsule())
                        }
                    }

                    #endif
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(20)
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
        .onReceive(cameraManager.$posePoints) { points in
            guard !points.isEmpty else { return }

            currentReps.processPose(
                points: points,
                exercise: exerciseTitle
            )
        }
        .onChange(of: currentReps.reps) { _, newReps in
            if newReps >= targetReps && !isGoalReached {
                completeGoal()
            }
        }
    }

    // MARK: - REP COMPLETION

    private func completeGoal() {
        guard !isGoalReached else { return }

        isGoalReached = true

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)

        // Send the earned minutes to MainTabView.
        onComplete(rewardMinutes)

        // Close the challenge after showing the success message.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }
}
