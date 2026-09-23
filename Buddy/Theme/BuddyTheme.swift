import SwiftUI

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

    static let pressScale: CGFloat = 0.97
    static let pressDuration: Double = 0.1
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Flat marshmallow-ghost Buddy — sheet silhouette + carrot. Not 3D clay.
struct BuddyMark: View {
    var size: CGFloat = 56
    var mood: BuddyMood = .curious
    var showsCarrot: Bool = true

    var body: some View {
        ZStack {
            // Soft float shadow (flat, light)
            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(width: size * 0.5, height: size * 0.1)
                .offset(y: size * 0.48)

            ghostBody
                .frame(width: size * 0.78, height: size)
                .foregroundStyle(BuddyTheme.bone)

            if showsCarrot {
                flatCarrot
                    .offset(x: size * 0.02, y: size * 0.12)
            }

            // Eyes
            HStack(spacing: size * 0.16) {
                Capsule().fill(BuddyTheme.field).frame(width: size * 0.1, height: size * 0.14)
                Capsule().fill(BuddyTheme.field).frame(width: size * 0.1, height: size * 0.14)
            }
            .offset(y: -size * 0.12)

            // Smile
            Capsule()
                .fill(BuddyTheme.field.opacity(mood == .sleepy ? 0.2 : 0.45))
                .frame(width: size * 0.14, height: size * 0.035)
                .offset(y: size * 0.02)

            // Needle cheek
            Circle()
                .fill(BuddyTheme.needle)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.24, y: -size * 0.02)
                .opacity(mood == .sleepy ? 0.35 : 1)

            if mood == .proud || mood == .hyped {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(BuddyTheme.needle)
                    .offset(x: -size * 0.34, y: -size * 0.36)
            }
        }
        .frame(width: size * 1.1, height: size * 1.15)
        .accessibilityLabel("Buddy, \(mood.label)")
    }

    /// Sheet ghost: rounded top + scalloped hem (flat path).
    private var ghostBody: some View {
        GhostSheetShape()
            .fill(BuddyTheme.bone)
    }

    private var flatCarrot: some View {
        ZStack {
            // Leaf (flat triangles-ish via capsules)
            Capsule()
                .fill(BuddyTheme.carrotLeaf)
                .frame(width: size * 0.05, height: size * 0.14)
                .offset(y: -size * 0.2)
            Capsule()
                .fill(BuddyTheme.carrotLeaf)
                .frame(width: size * 0.05, height: size * 0.12)
                .rotationEffect(.degrees(-25))
                .offset(x: -size * 0.05, y: -size * 0.18)
            Capsule()
                .fill(BuddyTheme.carrotLeaf)
                .frame(width: size * 0.05, height: size * 0.12)
                .rotationEffect(.degrees(25))
                .offset(x: size * 0.05, y: -size * 0.18)

            // Carrot body — flat tapered capsule
            Capsule()
                .fill(BuddyTheme.carrot)
                .frame(width: size * 0.13, height: size * 0.34)
        }
    }
}

/// Classic marshmallow-ghost outline: dome + three scallops at the hem.
struct GhostSheetShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let midY = h * 0.42
        let hemY = h * 0.72

        p.move(to: CGPoint(x: 0, y: midY))
        p.addQuadCurve(
            to: CGPoint(x: w, y: midY),
            control: CGPoint(x: w * 0.5, y: -h * 0.08)
        )
        p.addLine(to: CGPoint(x: w, y: hemY))
        // Scallops R → L
        p.addQuadCurve(
            to: CGPoint(x: w * 2 / 3, y: hemY),
            control: CGPoint(x: w * 5 / 6, y: h)
        )
        p.addQuadCurve(
            to: CGPoint(x: w / 3, y: hemY),
            control: CGPoint(x: w * 0.5, y: h)
        )
        p.addQuadCurve(
            to: CGPoint(x: 0, y: hemY),
            control: CGPoint(x: w / 6, y: h)
        )
        p.closeSubpath()
        return p
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
