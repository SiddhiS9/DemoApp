//
//  RepCounter.swift
//  APPDEMO
//
//  Created by Samuel Devassy on 11/15/26.
//



import SwiftUI
import Combine

final class RepCounter: ObservableObject {

    // MARK: - Published Properties

    @Published var reps = 0
    @Published var movementStatus = "Ready"

    // MARK: - Movement Tracking

    private var hasReachedDownPosition = false

    // MARK: - Process Body Positions

    func processPose(
        points: [String: CGPoint],
        exercise: String
    ) {

        let angle: CGFloat?

        switch exercise.lowercased() {

        case "push-ups", "push-ups".lowercased(), "pushups":

            angle = jointAngle(
                points: points,
                first: "rightShoulder",
                middle: "rightElbow",
                last: "rightWrist"
            ) ?? jointAngle(
                points: points,
                first: "leftShoulder",
                middle: "leftElbow",
                last: "leftWrist"
            )

        case "squats", "squat":

            angle = jointAngle(
                points: points,
                first: "rightHip",
                middle: "rightKnee",
                last: "rightAnkle"
            ) ?? jointAngle(
                points: points,
                first: "leftHip",
                middle: "leftKnee",
                last: "leftAnkle"
            )

        case "abs", "crunches", "crunch":

            angle = jointAngle(
                points: points,
                first: "rightShoulder",
                middle: "rightHip",
                last: "rightKnee"
            ) ?? jointAngle(
                points: points,
                first: "leftShoulder",
                middle: "leftHip",
                last: "leftKnee"
            )

        default:
            movementStatus = "Waiting for exercise..."
            return
        }

        guard let angle = angle else {
            movementStatus = "Position your body in view"
            return
        }

        // Detect the lowered position.
        if angle < 100 {
            hasReachedDownPosition = true
            movementStatus = "Lower position detected"
        }

        // Detect return to starting position.
        else if angle > 150 && hasReachedDownPosition {

            reps += 1
            hasReachedDownPosition = false

            movementStatus = "Rep completed!"
        }

        else if angle > 150 {
            movementStatus = "Ready"
        }
    }

    // MARK: - Calculate Joint Angle

    private func jointAngle(
        points: [String: CGPoint],
        first: String,
        middle: String,
        last: String
    ) -> CGFloat? {

        guard
            let a = points[first],
            let b = points[middle],
            let c = points[last]
        else {
            return nil
        }

        let vector1 = CGVector(
            dx: a.x - b.x,
            dy: a.y - b.y
        )

        let vector2 = CGVector(
            dx: c.x - b.x,
            dy: c.y - b.y
        )

        let dotProduct =
            vector1.dx * vector2.dx +
            vector1.dy * vector2.dy

        let magnitude1 = sqrt(
            vector1.dx * vector1.dx +
            vector1.dy * vector1.dy
        )

        let magnitude2 = sqrt(
            vector2.dx * vector2.dx +
            vector2.dy * vector2.dy
        )

        guard magnitude1 > 0, magnitude2 > 0 else {
            return nil
        }

        let cosine = max(
            -1,
            min(1, dotProduct / (magnitude1 * magnitude2))
        )

        return acos(cosine) * 180 / .pi
    }

    // MARK: - Simulator Testing

    func simulateRep() {
        reps += 1
        movementStatus = "Rep completed!"
    }

    // MARK: - Reset

    func reset() {
        reps = 0
        hasReachedDownPosition = false
        movementStatus = "Ready"
    }
}
