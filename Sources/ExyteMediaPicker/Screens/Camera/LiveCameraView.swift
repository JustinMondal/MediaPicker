//
//  LiveCameraView.swift
//
//
//  Created by Alexandra Afonasova on 18.10.2022.
//

import SwiftUI
import AVFoundation

@MainActor
public struct LiveCameraView: UIViewRepresentable {

    let session: AVCaptureSession
    let videoGravity: AVLayerVideoGravity
    let orientation: UIDeviceOrientation

    public func makeUIView(context: Context) -> LiveVideoCaptureView {
        LiveVideoCaptureView(
            session: session,
            videoGravity: videoGravity,
            orientation: orientation
        )
    }

    public func updateUIView(_ uiView: LiveVideoCaptureView, context: Context) {
        uiView.setOrientation(orientation)
    }
}

// MARK: - AVCaptureVideoOrientation from UIDeviceOrientation
private func captureVideoOrientation(from deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
    switch deviceOrientation {
    case .portrait: return .portrait
    case .portraitUpsideDown: return .portraitUpsideDown
    case .landscapeLeft: return .landscapeRight
    case .landscapeRight: return .landscapeLeft
    default: return .portrait
    }
}

public final class LiveVideoCaptureView: UIView {

    var session: AVCaptureSession? {
        get {
            return videoLayer.session
        }
        set (session) {
            videoLayer.session = session
        }
    }

    public override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var videoLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private var currentOrientation: UIDeviceOrientation

    required init?(coder: NSCoder) {
        self.currentOrientation = .portrait
        super.init(coder: coder)
    }

    init(
        frame: CGRect = .zero,
        session: AVCaptureSession? = nil,
        videoGravity: AVLayerVideoGravity = .resizeAspect,
        orientation: UIDeviceOrientation
    ) {
        self.currentOrientation = orientation
        super.init(frame: frame)
        self.session = session
        videoLayer.videoGravity = videoGravity
        applyPreviewOrientation()
    }

    func setOrientation(_ orientation: UIDeviceOrientation) {
        guard orientation != currentOrientation else { return }
        currentOrientation = orientation
        applyPreviewOrientation()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        videoLayer.frame = bounds
        applyPreviewOrientation()
    }

    private func applyPreviewOrientation() {
        guard let connection = videoLayer.connection, connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = captureVideoOrientation(from: currentOrientation)
    }
}
