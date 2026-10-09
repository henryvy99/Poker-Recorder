//
//  CameraManager.swift
//  Poker Recorder
//
//  Created by Henry Vy on 10/9/26.
//

import AVFoundation
import Combine
import Foundation

final class CameraManager: ObservableObject {
    enum Status: Equatable {
        case idle
        case requestingPermission
        case running
        case denied
        case failed(String)
    }

    /// Shared with the preview layer. Start/stop this session only on `sessionQueue`.
    nonisolated let session = AVCaptureSession()

    @Published private(set) var status: Status = .idle

    private let sessionQueue = DispatchQueue(label: "com.pokerrecorder.camera")
    /// Touched only on `sessionQueue`.
    private nonisolated(unsafe) var isConfigured = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSessionIfNeeded()
        case .notDetermined:
            status = .requestingPermission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.startSessionIfNeeded()
                    } else {
                        self.status = .denied
                    }
                }
            }
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .denied
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func startSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                do {
                    try self.configureSession()
                    self.isConfigured = true
                } catch {
                    DispatchQueue.main.async {
                        self.status = .failed(error.localizedDescription)
                    }
                    return
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.status = .running
            }
        }
    }

    private nonisolated func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)
    }
}

private enum CameraError: LocalizedError {
    case noCamera
    case cannotAddInput

    var errorDescription: String? {
        switch self {
        case .noCamera:
            return "No rear camera is available on this device."
        case .cannotAddInput:
            return "Could not connect to the camera."
        }
    }
}
