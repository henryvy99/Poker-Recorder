//
//  CameraPreviewView.swift
//  Poker Recorder
//
//  Created by Henry Vy on 10/9/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.updateVideoOrientation()
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
        uiView.updateVideoOrientation()
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateVideoOrientation()
    }

    func updateVideoOrientation() {
        guard let connection = previewLayer.connection else { return }

        let orientation = currentInterfaceOrientation()

        if #available(iOS 17.0, *) {
            let angle = Self.videoRotationAngle(for: orientation)
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = Self.videoOrientation(for: orientation)
        }
    }

    private func currentInterfaceOrientation() -> UIInterfaceOrientation {
        if let scene = window?.windowScene {
            return scene.interfaceOrientation
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation ?? .landscapeRight
    }

    private static func videoOrientation(
        for interfaceOrientation: UIInterfaceOrientation
    ) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .landscapeRight
        }
    }

    @available(iOS 17.0, *)
    private static func videoRotationAngle(
        for interfaceOrientation: UIInterfaceOrientation
    ) -> CGFloat {
        switch interfaceOrientation {
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        default:
            return 0
        }
    }
}
