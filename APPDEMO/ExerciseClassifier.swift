//
//  ExerciseClassifier.swift
//  APPDEMO
//
//  Created by Samuel Devassy on 11/15/26.
//


import Foundation
import CoreML

final class ExerciseClassifier {

    private let model: MLModel

    init() throws {
        guard let modelURL = Bundle.main.url(
            forResource: "WorkoutDetect 1",
            withExtension: "mlmodelc"
        ) else {
            throw NSError(
                domain: "ExerciseClassifier",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not find WorkoutDetect 1 model."
                ]
            )
        }

        model = try MLModel(contentsOf: modelURL)
    }

    func classify(
        poses: [[[Float]]]
    ) throws -> (label: String, probabilities: [String: Double]) {

        guard poses.count == 60 else {
            throw NSError(
                domain: "ExerciseClassifier",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The model requires exactly 60 frames."
                ]
            )
        }

        let multiArray = try MLMultiArray(
            shape: [60, 3, 18],
            dataType: .float32
        )

        for frame in 0..<60 {
            for coordinate in 0..<3 {
                for joint in 0..<18 {

                    multiArray[
                        [frame as NSNumber,
                         coordinate as NSNumber,
                         joint as NSNumber]
                    ] = NSNumber(
                        value: poses[frame][coordinate][joint]
                    )
                }
            }
        }

        let input = try MLDictionaryFeatureProvider(
            dictionary: [
                "poses": MLFeatureValue(multiArray: multiArray)
            ]
        )

        let prediction = try model.prediction(from: input)

        let label = prediction
            .featureValue(for: "label")?
            .stringValue ?? "Unknown"

        var probabilities: [String: Double] = [:]

        if let dictionary = prediction
            .featureValue(for: "labelProbabilities")?
            .dictionaryValue {

            for (key, value) in dictionary {
                if let exercise = key as? String,
                   let probability = value as? Double {
                    probabilities[exercise] = probability
                }
            }
        }

        return (label, probabilities)
    }
}