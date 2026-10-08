import ARKit
import AVFoundation
import SceneKit
import SwiftUI
import UIKit
import Vision

/// Live plate log — AR / camera feed with Buddy floating beside the frame.
struct ARPlateScanView: View {
    var reflection: BuddyReflection = .neutral
    var onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var session = PlateLiveScanSession()

    var body: some View {
        ZStack {
            PlateLiveCameraRepresentable(session: session)
                .ignoresSafeArea()

            scanChrome

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear { session.start() }
        .onDisappear { session.stop() }
        .alert("Camera needed", isPresented: Binding(
            get: { session.permissionDenied },
            set: { if !$0 { session.permissionDenied = false } }
        )) {
            Button("Close") { dismiss() }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Buddy needs the camera to float over your plate.")
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BuddyTheme.bone)
                    .frame(width: 40, height: 40)
                    .background(BuddyTheme.field.opacity(0.55), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())

            HStack(alignment: .center, spacing: 12) {
                BuddyMark(
                    size: 52,
                    mood: .curious,
                    reflection: reflection,
                    animated: !reduceMotion
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.buddyLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BuddyTheme.bone)
                        .lineLimit(2)
                    if !session.liveHint.isEmpty {
                        Text(session.liveHint)
                            .font(.caption)
                            .foregroundStyle(BuddyTheme.dim)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(BuddyTheme.field.opacity(0.55), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
        }
    }

    private var scanChrome: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.72
            ZStack {
                RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous)
                    .strokeBorder(BuddyTheme.bone.opacity(0.35), lineWidth: 1.5)
                    .frame(width: side, height: side)
                    .overlay {
                        RoundedRectangle(cornerRadius: BuddyTheme.radiusLG, style: .continuous)
                            .strokeBorder(BuddyTheme.needle.opacity(session.isScanning ? 0.55 : 0), lineWidth: 2)
                            .animation(
                                reduceMotion
                                    ? nil
                                    : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                                value: session.isScanning
                            )
                    }
                    .overlay(alignment: .topLeading) { cornerBracket }
                    .overlay(alignment: .topTrailing) {
                        cornerBracket.rotationEffect(.degrees(90))
                    }
                    .overlay(alignment: .bottomLeading) {
                        cornerBracket.rotationEffect(.degrees(-90))
                    }
                    .overlay(alignment: .bottomTrailing) {
                        cornerBracket.rotationEffect(.degrees(180))
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }

    private var cornerBracket: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 22))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 22, y: 0))
        }
        .stroke(BuddyTheme.bone, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        .frame(width: 22, height: 22)
        .padding(10)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Text(session.modeLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(BuddyTheme.bone.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BuddyTheme.field.opacity(0.45), in: Capsule())

            Button {
                if let image = session.captureStill() {
                    onCapture(image)
                    dismiss()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(BuddyTheme.bone.opacity(0.2))
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(BuddyTheme.needle)
                        .frame(width: 64, height: 64)
                    Image("iconLogPlate")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(BuddyTheme.bone)
                }
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!session.isReady)
            .accessibilityLabel("Log plate")
        }
    }
}

// MARK: - Session

@MainActor
final class PlateLiveScanSession: NSObject, ObservableObject {
    @Published var liveHint = ""
    @Published var buddyLine = "Point me at the plate…"
    @Published var isScanning = false
    @Published var isReady = false
    @Published var permissionDenied = false
    @Published private(set) var mode: Mode = .unavailable

    enum Mode {
        case ar
        case camera
        case unavailable
    }

    var modeLabel: String {
        switch mode {
        case .ar: return "Live with Buddy · AR"
        case .camera: return "Live with Buddy · Camera"
        case .unavailable: return "Camera unavailable"
        }
    }

    let arSession = ARSession()
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.mrkrphl.buddy.plate-live")
    private var lastVisionAt: Date = .distantPast
    private var visionBusy = false
    private var lastPixelBuffer: CVPixelBuffer?

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            bootCapture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                Task { @MainActor in
                    guard let self else { return }
                    if ok { self.bootCapture() } else { self.permissionDenied = true }
                }
            }
        default:
            permissionDenied = true
        }
    }

    func stop() {
        arSession.pause()
        sessionQueue.async { [captureSession] in
            if captureSession.isRunning { captureSession.stopRunning() }
        }
        isReady = false
        isScanning = false
        lastPixelBuffer = nil
    }

    private func bootCapture() {
        #if targetEnvironment(simulator)
        mode = .camera
        configureAVCapture()
        #else
        if ARWorldTrackingConfiguration.isSupported {
            mode = .ar
            let config = ARWorldTrackingConfiguration()
            arSession.delegate = self
            arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
            isReady = true
            isScanning = true
            buddyLine = "I’m floating with you. Fill the frame."
        } else {
            mode = .camera
            configureAVCapture()
        }
        #endif
    }

    private func configureAVCapture() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.captureSession.canAddInput(input)
            else {
                Task { @MainActor in
                    self.mode = .unavailable
                    self.buddyLine = "No camera on this device."
                }
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.addInput(input)

            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            Task { @MainActor in
                self.isReady = true
                self.isScanning = true
                self.buddyLine = "I’m floating with you. Fill the frame."
            }
        }
    }

    func captureStill() -> UIImage? {
        switch mode {
        case .ar:
            if let frame = arSession.currentFrame {
                return Self.image(from: frame.capturedImage, orientation: .right)
            }
            return nil
        case .camera:
            guard let buffer = lastPixelBuffer else { return nil }
            return Self.image(from: buffer, orientation: .right)
        case .unavailable:
            return nil
        }
    }

    private func considerVision(pixelBuffer: CVPixelBuffer) {
        lastPixelBuffer = pixelBuffer
        let now = Date()
        guard now.timeIntervalSince(lastVisionAt) >= 1.2, !visionBusy else { return }
        lastVisionAt = now
        visionBusy = true

        let request = VNClassifyImageRequest { [weak self] request, _ in
            defer {
                Task { @MainActor in self?.visionBusy = false }
            }
            let results = (request.results as? [VNClassificationObservation]) ?? []
            let labels = results
                .prefix(4)
                .filter { $0.confidence >= 0.2 }
                .map(\.identifier)
                .map { $0.replacingOccurrences(of: "_", with: " ") }

            Task { @MainActor in
                guard let self else { return }
                if labels.isEmpty {
                    self.liveHint = "Looking for food…"
                    self.buddyLine = "A little closer — I want the whole plate."
                } else {
                    self.liveHint = "Seeing: " + labels.joined(separator: ", ")
                    self.buddyLine = "Looks tasty. Tap when you’re ready."
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    static func image(from buffer: CVPixelBuffer, orientation: UIImage.Orientation) -> UIImage? {
        let ci = CIImage(cvPixelBuffer: buffer)
        let context = CIContext(options: nil)
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg, scale: 1, orientation: orientation)
    }
}

extension PlateLiveScanSession: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let buffer = frame.capturedImage
        Task { @MainActor in
            considerVision(pixelBuffer: buffer)
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            buddyLine = "AR hiccup — still with you on camera."
            if mode == .ar {
                mode = .camera
                arSession.pause()
                configureAVCapture()
            }
        }
    }
}

extension PlateLiveScanSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor in
            considerVision(pixelBuffer: buffer)
        }
    }
}

// MARK: - Camera representable

struct PlateLiveCameraRepresentable: UIViewRepresentable {
    @ObservedObject var session: PlateLiveScanSession

    func makeUIView(context: Context) -> PlateLiveCameraHostView {
        PlateLiveCameraHostView()
    }

    func updateUIView(_ uiView: PlateLiveCameraHostView, context: Context) {
        uiView.apply(session: session)
    }
}

final class PlateLiveCameraHostView: UIView {
    private var arView: ARSCNView?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var appliedMode: PlateLiveScanSession.Mode?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func apply(session: PlateLiveScanSession) {
        guard appliedMode != session.mode else {
            previewLayer?.session = session.captureSession
            return
        }
        appliedMode = session.mode

        switch session.mode {
        case .ar:
            previewLayer?.removeFromSuperlayer()
            previewLayer = nil
            let view = arView ?? ARSCNView(frame: bounds)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.session = session.arSession
            view.scene = SCNScene()
            view.automaticallyUpdatesLighting = true
            if arView == nil {
                insertSubview(view, at: 0)
                arView = view
            }
            arView?.isHidden = false
            arView?.frame = bounds
        case .camera, .unavailable:
            arView?.removeFromSuperview()
            arView = nil
            let layer = previewLayer ?? AVCaptureVideoPreviewLayer(session: session.captureSession)
            layer.videoGravity = .resizeAspectFill
            layer.frame = bounds
            if previewLayer == nil {
                self.layer.insertSublayer(layer, at: 0)
                previewLayer = layer
            } else {
                layer.session = session.captureSession
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        arView?.frame = bounds
        previewLayer?.frame = bounds
    }
}
