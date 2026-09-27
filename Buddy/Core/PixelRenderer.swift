import CoreGraphics
import UIKit

/// Buddy sprite palette (code-only pixel art).
/// Indices match sprite matrices in `BuddyGhostPixels`.
enum BuddyPalette {
    /// 0 transparent · 1 outline · 2 bone · 3 bone light · 4 dim · 5 needle · 6 carrot · 7 leaf · 8 eye
    static let colors: [UInt32?] = [
        nil,
        0x1A1A1C, // outline (near field)
        0xE6E2DA, // bone
        0xF2EFE8, // bone highlight
        0x8A8580, // dim
        0xE2452B, // needle
        0xE07A3A, // carrot
        0x6B8F5A, // leaf
        0x0B0B0C  // eye / deep
    ]
}

enum PixelRenderer {
    /// Renders a pixel matrix to a UIImage (nearest-neighbor / crisp pixels).
    static func render(
        _ pixels: [[Int]],
        palette: [UInt32?] = BuddyPalette.colors,
        scale: Int = 4
    ) -> UIImage {
        let rows = pixels.count
        guard rows > 0, let cols = pixels.first?.count, cols > 0 else {
            return UIImage()
        }
        let w = cols * scale
        let h = rows * scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIImage()
        }

        ctx.interpolationQuality = .none
        for y in 0..<rows {
            for x in 0..<cols {
                let idx = pixels[y][x]
                guard idx > 0, idx < palette.count, let hex = palette[idx] else { continue }
                let r = CGFloat((hex >> 16) & 0xFF) / 255
                let g = CGFloat((hex >> 8) & 0xFF) / 255
                let b = CGFloat(hex & 0xFF) / 255
                ctx.setFillColor(red: r, green: g, blue: b, alpha: 1)
                ctx.fill(CGRect(x: x * scale, y: y * scale, width: scale, height: scale))
            }
        }

        guard let cg = ctx.makeImage() else { return UIImage() }
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }

    static func renderSheet(
        _ frames: [[[Int]]],
        palette: [UInt32?] = BuddyPalette.colors,
        scale: Int = 4
    ) -> UIImage {
        guard let first = frames.first, !first.isEmpty else { return UIImage() }
        let rows = first.count
        let cols = first[0].count
        let frameW = cols * scale
        let frameH = rows * scale
        let w = frameW * frames.count
        let h = frameH
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIImage()
        }
        ctx.interpolationQuality = .none
        for (fi, pixels) in frames.enumerated() {
            let ox = fi * frameW
            for y in 0..<rows {
                for x in 0..<cols {
                    let idx = pixels[y][x]
                    guard idx > 0, idx < palette.count, let hex = palette[idx] else { continue }
                    let r = CGFloat((hex >> 16) & 0xFF) / 255
                    let g = CGFloat((hex >> 8) & 0xFF) / 255
                    let b = CGFloat(hex & 0xFF) / 255
                    ctx.setFillColor(red: r, green: g, blue: b, alpha: 1)
                    ctx.fill(CGRect(x: ox + x * scale, y: y * scale, width: scale, height: scale))
                }
            }
        }
        guard let cg = ctx.makeImage() else { return UIImage() }
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }
}
