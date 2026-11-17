
import SwiftUI
import AVFoundation
import Vision
import ImageIO
import Combine
import CoreML

final class CameraManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    let session = AVCaptureSession()

    @Published var posePoints: [String: CGPoint] = [:]
    @Published var isPersonDetected = false
    @Published var cameraStatus = "Camera not started"

    @Published var predictedExercise = "Waiting for exercise..."
    @Published var predictionConfidence = 0.0

    // MARK: - Camera Properties

    private let sessionQueue = DispatchQueue(
        label: "movo.camera.session"
    )

    private let videoOutput = AVCaptureVideoDataOutput()
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    private var isConfigured = false

    // MARK: - Exercise Recognition Properties

    private var classifier: ExerciseClassifier? = try? ExerciseClassifier()

    private var poseHistory: [[[Float]]] = []

    // Joint order must match the Create ML model.
    static let jointNames: [String] = [
        "nose",
        "neck",
        "rightShoulder",
        "rightElbow",
        "rightWrist",
        "leftShoulder",
        "leftElbow",
        "leftWrist",
        "rightHip",
        "rightKnee",
        "rightAnkle",
        "leftHip",
        "leftKnee",
        "leftAnkle",
        "rightEye",
        "leftEye",
        "rightEar",
        "leftEar"
    ]

    // MARK: - Start Camera

    func start() {

        #if targetEnvironment(simulator)

        DispatchQueue.main.async {
            self.cameraStatus =
                "Live camera testing requires a physical iPhone."
        }

        #else

        AVCaptureDevice.requestAccess(for: .video) { granted in

            guard granted else {
                DispatchQueue.main.async {
                    self.cameraStatus = "Camera permission denied."
                }
                return
            }

            self.sessionQueue.async {
                self.configureCamera()
            }
        }

        #endif
    }

    // MARK: - Configure Camera

    private func configureCamera() {

        guard !isConfigured else {
            if !session.isRunning {
                session.startRunning()
            }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {

            session.commitConfiguration()

            DispatchQueue.main.async {
                self.cameraStatus = "Front camera unavailable."
            }

            return
        }

        do {

            let input = try AVCaptureDeviceInput(device: camera)

            guard session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }

            session.addInput(input)

            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_32BGRA
            ]

            videoOutput.alwaysDiscardsLateVideoFrames = true

            videoOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "movo.camera.frames")
            )

            guard session.canAddOutput(videoOutput) else {
                session.commitConfiguration()
                return
            }

            session.addOutput(videoOutput)

            session.commitConfiguration()

            isConfigured = true

            session.startRunning()

            DispatchQueue.main.async {
                self.cameraStatus =
                    "Camera running. Looking for your body..."
            }

        } catch {

            session.commitConfiguration()

            DispatchQueue.main.async {
                self.cameraStatus =
                    "Camera error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Stop Camera

    func stop() {

        #if !targetEnvironment(simulator)

        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }

        #endif
    }

    // MARK: - Detect Body Pose

    private func detectPose(in sampleBuffer: CMSampleBuffer) {

        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {

            try handler.perform([poseRequest])

            guard let observation = poseRequest.results?.first else {

                poseHistory.removeAll()

                DispatchQueue.main.async {
                    self.isPersonDetected = false
                    self.posePoints = [:]
                    self.cameraStatus = "No person detected."
                    self.predictedExercise =
                        "Waiting for exercise..."
                    self.predictionConfidence = 0
                }

                return
            }

            let recognizedPoints =
                try observation.recognizedPoints(.all)

            // MARK: Joint Mapping

            let jointMapping:
                [(String, VNHumanBodyPoseObservation.JointName)] = [

                ("nose", .nose),
                ("neck", .neck),
                ("rightShoulder", .rightShoulder),
                ("rightElbow", .rightElbow),
                ("rightWrist", .rightWrist),
                ("leftShoulder", .leftShoulder),
                ("leftElbow", .leftElbow),
                ("leftWrist", .leftWrist),
                ("rightHip", .rightHip),
                ("rightKnee", .rightKnee),
                ("rightAnkle", .rightAnkle),
                ("leftHip", .leftHip),
                ("leftKnee", .leftKnee),
                ("leftAnkle", .leftAnkle),
                ("rightEye", .rightEye),
                ("leftEye", .leftEye),
                ("rightEar", .rightEar),
                ("leftEar", .leftEar)
            ]

            var xValues: [Float] = []
            var yValues: [Float] = []
            var confidenceValues: [Float] = []

            var detectedPoints: [String: CGPoint] = [:]

            // MARK: Collect Joint Coordinates

            for (name, joint) in jointMapping {

                let point = recognizedPoints[joint]

                let confidence = point?.confidence ?? 0

                let x = point?.location.x ?? 0
                let y = point?.location.y ?? 0

                xValues.append(Float(x))
                yValues.append(Float(y))
                confidenceValues.append(Float(confidence))

                if confidence > 0.2 {

                    detectedPoints[name] = CGPoint(
                        x: x,
                        y: y
                    )
                }
            }

            // One frame = 3 arrays of 18 values.
            let currentFrame: [[Float]] = [
                xValues,
                yValues,
                confidenceValues
            ]

            // MARK: Store Frames

            poseHistory.append(currentFrame)

            if poseHistory.count > 60 {
                poseHistory.removeFirst()
            }

            DispatchQueue.main.async {
                self.posePoints = detectedPoints
                self.isPersonDetected = !detectedPoints.isEmpty
                self.cameraStatus = "Body detected!"
            }

            // MARK: Classify Exercise

            if poseHistory.count == 60 {

                guard let classifier = classifier else {

                    DispatchQueue.main.async {
                        self.cameraStatus =
                            "Could not load exercise model."
                    }

                    return
                }

                let sequence = Array(poseHistory.suffix(60))

                do {

                    let result = try classifier.classify(
                        poses: sequence
                    )

                    let confidence =
                        result.probabilities[result.label] ?? 0

                    DispatchQueue.main.async {

                        self.predictedExercise = result.label

                        self.predictionConfidence = confidence
                    }

                } catch {

                    DispatchQueue.main.async {
                        self.cameraStatus =
                            "Prediction error: \(error.localizedDescription)"
                    }
                }

                // Keep 30 frames for the next prediction.
                poseHistory.removeFirst(30)
            }

        } catch {

            DispatchQueue.main.async {
                self.cameraStatus = "Pose detection failed."
            }
        }
    }
}

// MARK: - Camera Frame Delegate
// IMPORTANT: This extension is OUTSIDE the CameraManager class.

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        detectPose(in: sampleBuffer)
    }
}
