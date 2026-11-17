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

        case "push-ups", "pushups", "push-up":
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

            guard let angle = angle else {
                movementStatus = "Show arms & shoulders in view"
                return
            }

            if angle < 115 {
                hasReachedDownPosition = true
                movementStatus = "Down position detected"
            } else if angle > 145 && hasReachedDownPosition {
                reps += 1
                hasReachedDownPosition = false
                movementStatus = "Rep completed!"
            } else if angle > 145 {
                movementStatus = "Ready"
            }

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

            guard let angle = angle else {
                movementStatus = "Position full body in view"
                return
            }

            if angle < 105 {
                hasReachedDownPosition = true
                movementStatus = "Lower position detected"
            } else if angle > 150 && hasReachedDownPosition {
                reps += 1
                hasReachedDownPosition = false
                movementStatus = "Rep completed!"
            } else if angle > 150 {
                movementStatus = "Ready"
            }

        case "walking", "walk", "steps":
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

            guard let angle = angle else {
                movementStatus = "Position legs in view"
                return
            }

            if angle < 135 {
                hasReachedDownPosition = true
                movementStatus = "Step lifted"
            } else if angle > 155 && hasReachedDownPosition {
                reps += 1
                hasReachedDownPosition = false
                movementStatus = "Step counted!"
            }

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

            guard let angle = angle else {
                movementStatus = "Position torso & knees in view"
                return
            }

            if angle < 110 {
                hasReachedDownPosition = true
                movementStatus = "Crunch up detected"
            } else if angle > 140 && hasReachedDownPosition {
                reps += 1
                hasReachedDownPosition = false
                movementStatus = "Rep completed!"
            }

        default:
            movementStatus = "Unsupported exercise: \(exercise)"
            return
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

        let vector1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let vector2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)

        let dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)

        guard magnitude1 > 0, magnitude2 > 0 else {
            return nil
        }

        let cosine = max(-1, min(1, dotProduct / (magnitude1 * magnitude2)))
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
