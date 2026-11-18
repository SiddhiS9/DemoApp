import SwiftUI
import AVFoundation
import Vision
import ImageIO

import Combine

final class CameraManager: NSObject, ObservableObject {

    let session = AVCaptureSession()

    @Published var posePoints: [String: CGPoint] = [:]
    @Published var isPersonDetected = false
    @Published var cameraStatus = "Camera not started"

    private let sessionQueue = DispatchQueue(
        label: "movo.camera.session"
    )

    private let videoOutput = AVCaptureVideoDataOutput()

    private let poseRequest = VNDetectHumanBodyPoseRequest()

    private var isConfigured = false

    // Names must match the ordering used by the Create ML model.
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

    private func configureCamera() {

        guard !isConfigured else {
            if !session.isRunning {
                session.startRunning()
            }
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        // Use the front-facing camera.
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
                queue: DispatchQueue(
                    label: "movo.camera.frames"
                )
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
                self.cameraStatus = "Camera running. Looking for your body..."
            }

        } catch {

            session.commitConfiguration()

            DispatchQueue.main.async {
                self.cameraStatus =
                    "Camera error: \(error.localizedDescription)"
            }
        }
    }

    func stop() {

        #if !targetEnvironment(simulator)

        sessionQueue.async {

            if self.session.isRunning {
                self.session.stopRunning()
            }
        }

        #endif
    }

    private func detectPose(in sampleBuffer: CMSampleBuffer) {

        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {

            try handler.perform([poseRequest])

            guard let observation = poseRequest.results?.first else {

                DispatchQueue.main.async {
                    self.isPersonDetected = false
                    self.posePoints = [:]
                    self.cameraStatus = "No person detected."
                }

                return
            }

            let recognizedPoints = try observation.recognizedPoints(.all)

            let jointMapping: [String: VNHumanBodyPoseObservation.JointName] = [
                "nose": .nose,
                "neck": .neck,
                "rightShoulder": .rightShoulder,
                "rightElbow": .rightElbow,
                "rightWrist": .rightWrist,
                "leftShoulder": .leftShoulder,
                "leftElbow": .leftElbow,
                "leftWrist": .leftWrist,
                "rightHip": .rightHip,
                "rightKnee": .rightKnee,
                "rightAnkle": .rightAnkle,
                "leftHip": .leftHip,
                "leftKnee": .leftKnee,
                "leftAnkle": .leftAnkle,
                "rightEye": .rightEye,
                "leftEye": .leftEye,
                "rightEar": .rightEar,
                "leftEar": .leftEar
            ]

            var detectedPoints: [String: CGPoint] = [:]

            for (name, joint) in jointMapping {

                guard let point = recognizedPoints[joint],
                      point.confidence > 0.2 else {
                    continue
                }

                detectedPoints[name] = CGPoint(
                    x: point.location.x,
                    y: point.location.y
                )
            }

            DispatchQueue.main.async {

                self.posePoints = detectedPoints
                self.isPersonDetected = !detectedPoints.isEmpty

                self.cameraStatus = self.isPersonDetected
                    ? "Body detected!"
                    : "Looking for your body..."
            }

        } catch {

            DispatchQueue.main.async {
                self.cameraStatus = "Pose detection failed."
            }
        }
    }
}

// MARK: - Camera frame processing

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        detectPose(in: sampleBuffer)
    }
}
