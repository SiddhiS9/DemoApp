//
//  CameraPreview.swift
//  APPDEMO
//
//  Created by Samuel Devassy on 11/15/26.
//


import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {

        let view = PreviewUIView()

        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        return view
    }

    func updateUIView(
        _ uiView: PreviewUIView,
        context: Context
    ) {

        uiView.previewLayer.session = session
    }
}

final class PreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}