import SwiftUI
import UIKit

enum BuddyTheme {
    static let field = Color(hex: 0x0B0B0C)
    static let canvas = Color(hex: 0x0A0A0B)
    static let bone = Color(hex: 0xE6E2DA)
    static let dim = Color(hex: 0x8A8580)
    static let needle = Color(hex: 0xE2452B)
    static let carrot = Color(hex: 0xE07A3A)
    static let carrotLeaf = Color(hex: 0x6B8F5A)

    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 22

    static let pressScale: CGFloat = 0.96
    static let pressDuration: Double = 0.1
    static let easeOut = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.2)
    static let morph = Animation.spring(response: 0.35, dampingFraction: 1.0)
    /// Sheet-ghost idle periods (seconds) — offset so float/sway/breathe/hem never lock in phase.
    static let idleBobPeriod: Double = 2.9
    static let idleDriftPeriod: Double = 4.6
    static let idleSwayPeriod: Double = 5.4
    static let idleBreathePeriod: Double = 3.5
    /// Hem cloth wave period (seconds) — L→R then back.
    static let idleHemPeriod: Double = 2.4
    static let blinkClose = Animation.easeOut(duration: 0.08)
    static let blinkOpen = Animation.easeOut(duration: 0.12)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Lock-model Buddy — transparent PNGs only (no overlays, no stroke box).
struct BuddyMark: View {
    var size: CGFloat = 56
    var mood: BuddyMood = .curious
    var reflection: BuddyReflection = .neutral
    var showsCarrot: Bool = true
    var animated: Bool = true
    /// Cloth hem Metal wave — off by default; can sample black on dark composites.
    var softCloth: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showBlink = false
    @State private var blinkTask: Task<Void, Never>?

    private var form: BuddyForm { reflection.form }
    private var melting: Bool { reflection.isSuperHungry }
    private var hungry: Bool { form == .hungry }
    private var idleMotionOn: Bool { animated && !reduceMotion }

    private var baseAsset: String {
        if melting { return "BuddyFormMelt" }
        switch form {
        case .balanced: return "BuddyFormBalanced"
        case .hungry: return "BuddyFormHungry"
        case .soft: return "BuddyFormSoft"
        case .strong: return "BuddyFormStrong"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !idleMotionOn)) { context in
            ghostBody(date: context.date)
                .frame(width: size, height: size)
                .modifier(GhostIdleMotion(
                    date: context.date,
                    size: size,
                    form: form,
                    melting: melting,
                    active: idleMotionOn
                ))
        }
        .animation(BuddyTheme.morph, value: baseAsset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Buddy, \(reflection.label), \(mood.label)")
        .onAppear { startBlinkLoop() }
        .onDisappear { blinkTask?.cancel(); blinkTask = nil }
        .onChange(of: form) { _, _ in startBlinkLoop() }
        .onChange(of: reflection.isSuperHungry) { _, _ in startBlinkLoop() }
        .onChange(of: animated) { _, on in
            if on { startBlinkLoop() } else {
                blinkTask?.cancel()
                showBlink = false
            }
        }
    }

    @ViewBuilder
    private func ghostBody(date: Date) -> some View {
        let hemOn = softCloth && idleMotionOn && !melting
        ZStack {
            BuddySheetImage(
                name: baseAsset,
                size: size,
                date: date,
                hemWave: hemOn
            )
            .opacity(showBlink ? 0 : 1)

            // Same lock silhouette, eyes closed — PNG swap only (no stroke / fake lids)
            BuddySheetImage(
                name: "BuddyFormBlink",
                size: size,
                date: date,
                hemWave: hemOn
            )
            .opacity(showBlink ? 1 : 0)
        }
    }

    private func startBlinkLoop() {
        blinkTask?.cancel()
        showBlink = false
        guard animated, !reduceMotion, !melting else { return }

        blinkTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            while !Task.isCancelled {
                await blinkOnce()
                // Hungry: sometimes a second blink soon after (weary)
                if hungry, Int.random(in: 0...3) == 0 {
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    await blinkOnce()
                }
                let wait = UInt64(Double.random(in: 2.6...4.8) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: wait)
            }
        }
    }

    @MainActor
    private func blinkOnce() async {
        withAnimation(BuddyTheme.blinkClose) { showBlink = true }
        try? await Task.sleep(nanoseconds: 95_000_000)
        withAnimation(BuddyTheme.blinkOpen) { showBlink = false }
    }
}

/// Lock PNG — hem-only cloth wave via Metal distortion (no strip compositing → no black flashes).
private struct BuddySheetImage: View {
    var name: String
    var size: CGFloat
    var date: Date
    var hemWave: Bool

    var body: some View {
        let image = Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)

        if hemWave {
            let t = Float(date.timeIntervalSinceReferenceDate)
            let amp = Float(max(2.2, size * 0.028))
            let pad = CGFloat(amp) + 2
            image
                .distortionEffect(
                    ShaderLibrary.buddyHemWave(
                        .float(t),
                        .float(Float(size)),
                        .float(amp)
                    ),
                    maxSampleOffset: CGSize(width: pad, height: pad)
                )
        } else {
            image
        }
    }
}

/// Ethereal sheet-ghost idle: bob + drift + sway + soft squash/stretch (transform only).
private struct GhostIdleMotion: ViewModifier {
    var date: Date
    var size: CGFloat
    var form: BuddyForm
    var melting: Bool
    var active: Bool

    func body(content: Content) -> some View {
        let pose = pose(at: date)
        content
            .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(pose.degrees))
            .offset(x: pose.x, y: pose.y)
    }

    private struct Pose {
        var x: CGFloat
        var y: CGFloat
        var degrees: Double
        var scaleX: CGFloat
        var scaleY: CGFloat
    }

    private func pose(at date: Date) -> Pose {
        guard active else {
            return Pose(x: 0, y: 0, degrees: 0, scaleX: 1, scaleY: 1)
        }

        let t = date.timeIntervalSinceReferenceDate
        let bob = sin(t * .pi * 2 / BuddyTheme.idleBobPeriod)
        let drift = sin(t * .pi * 2 / BuddyTheme.idleDriftPeriod + 0.9)
        let sway = sin(t * .pi * 2 / BuddyTheme.idleSwayPeriod + 1.7)
        let breath = sin(t * .pi * 2 / BuddyTheme.idleBreathePeriod + 0.4)

        // Melting barely lifts; otherwise size-scaled float so large Buddy feels airborne.
        let bobAmp: CGFloat = melting ? size * 0.012 : size * 0.07
        let driftAmp: CGFloat = melting ? size * 0.004 : size * 0.028
        let swayAmp: Double = melting ? 0.6 : 2.4
        var stretch: CGFloat = melting ? 0.008 : 0.022
        var flex: CGFloat = melting ? 0.004 : 0.012

        switch form {
        case .hungry:
            stretch *= 1.45 // hunger squash
            flex *= 0.7
        case .soft:
            stretch *= 1.25 // soft breathe
            flex *= 1.15
        case .strong:
            stretch *= 0.85
            flex *= 1.55 // strong flex
        case .balanced:
            break
        }

        return Pose(
            x: driftAmp * CGFloat(drift),
            y: -bobAmp * CGFloat((bob + 1) / 2), // hangs mid-air; never drops below rest
            degrees: swayAmp * sway,
            scaleX: 1 + flex * CGFloat(breath) - stretch * CGFloat(breath) * 0.35,
            scaleY: 1 + stretch * CGFloat(breath)
        )
    }
}

struct PressableButtonStyle: ButtonStyle {
    var staticMotion: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!staticMotion && configuration.isPressed ? BuddyTheme.pressScale : 1)
            .animation(
                .easeOut(duration: BuddyTheme.pressDuration),
                value: configuration.isPressed
            )
    }
}
