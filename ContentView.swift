//
//  ContentView.swift
//  Poker Recorder
//
//  Created by Henry Vy on 10/9/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.status {
            case .running:
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            case .denied:
                messageView(
                    title: "Camera access is off",
                    detail: "Turn on Camera in Settings to see the live preview."
                ) {
                    Button("Open Settings") {
                        openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .failed(let message):
                messageView(
                    title: "Camera unavailable",
                    detail: message
                )
            case .idle, .requestingPermission:
                messageView(
                    title: "Starting camera…",
                    detail: "Allow camera access if you are asked."
                )
            }
        }
        .onAppear {
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                camera.start()
            case .inactive, .background:
                camera.stop()
            @unknown default:
                break
            }
        }
    }

    private func messageView<Footer: View>(
        title: String,
        detail: String,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            footer()
        }
        .padding()
        .frame(maxWidth: 480)
        .foregroundStyle(.white)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
