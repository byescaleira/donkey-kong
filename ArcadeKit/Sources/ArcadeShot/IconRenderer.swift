import ArcadeCore
import ArcadeRender
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconLayer: String {
    case back
    case middle
    case front
    case full
}

enum IconRenderer {
    static func render(width: Int, height: Int, layer: IconLayer) -> CGImage? {
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard
            let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space, bitmapInfo: info)
        else { return nil }

        let size = CGSize(width: Double(width), height: Double(height))
        context.interpolationQuality = .none

        if layer == .back || layer == .full { drawBack(context, size) }
        if layer == .middle || layer == .full { drawMiddle(context, size) }
        if layer == .front || layer == .full { drawFront(context, size) }

        return context.makeImage()
    }

    private static func fill(_ context: CGContext, _ rect: CGRect, _ color: PixelColor, alpha: Double = 1) {
        context.setFillColor(
            red: color.red, green: color.green, blue: color.blue, alpha: color.alpha * alpha)
        context.fill(rect)
    }

    private static func drawBack(_ context: CGContext, _ size: CGSize) {
        let space = CGColorSpaceCreateDeviceRGB()
        let top = ArcadePalette.backgroundFar
        let bottom = ArcadePalette.background
        if let gradient = CGGradient(
            colorsSpace: space,
            colors: [
                CGColor(red: top.red, green: top.green, blue: top.blue, alpha: 1),
                CGColor(red: bottom.red, green: bottom.green, blue: bottom.blue, alpha: 1),
            ] as CFArray, locations: [0, 1])
        {
            context.drawLinearGradient(
                gradient, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])
        }

        let lineStep = max(size.height / 46, 3)
        var y = 0.0
        while y < size.height {
            fill(
                context, CGRect(x: 0, y: y, width: size.width, height: max(lineStep * 0.28, 1)),
                ArcadePalette.ladder, alpha: 0.05)
            y += lineStep
        }

        let postWidth = max(size.width * 0.012, 2)
        for fraction in [0.12, 0.88] {
            fill(
                context,
                CGRect(
                    x: size.width * fraction - postWidth / 2, y: size.height * 0.08,
                    width: postWidth, height: size.height * 0.84),
                ArcadePalette.metal, alpha: 0.16)
        }
        for fraction in stride(from: 0.2, through: 0.92, by: 0.18) {
            fill(
                context,
                CGRect(
                    x: size.width * 0.12, y: size.height * fraction,
                    width: size.width * 0.76, height: max(size.height * 0.008, 1)),
                ArcadePalette.metal, alpha: 0.14)
        }
    }

    private static func bar(_ context: CGContext, _ size: CGSize, y: Double, from: Double, to: Double, tilt: Double) {
        let height = max(size.height * 0.062, 3)
        context.saveGState()
        context.translateBy(x: size.width * (from + to) / 2, y: size.height * y)
        context.rotate(by: tilt)
        let width = size.width * (to - from)
        fill(
            context, CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
            ArcadePalette.girder)
        fill(
            context,
            CGRect(x: -width / 2, y: -height / 2, width: width, height: max(height * 0.22, 1)),
            ArcadePalette.girderShade)
        context.restoreGState()
    }

    private static func drawMiddle(_ context: CGContext, _ size: CGSize) {
        bar(context, size, y: 0.84, from: 0.07, to: 0.93, tilt: 0.055)
        bar(context, size, y: 0.52, from: 0.56, to: 0.95, tilt: -0.055)
        bar(context, size, y: 0.16, from: 0.07, to: 0.93, tilt: 0.055)

        let railWidth = max(size.width * 0.01, 2)
        let left = size.width * 0.68
        let right = size.width * 0.78
        let bottom = size.height * 0.19
        let height = size.height * 0.31
        for x in [left, right] {
            fill(
                context, CGRect(x: x, y: bottom, width: railWidth, height: height),
                ArcadePalette.ladder, alpha: 0.9)
        }
        var rung = bottom + height * 0.08
        while rung < bottom + height {
            fill(
                context,
                CGRect(
                    x: left, y: rung, width: right - left + railWidth,
                    height: max(size.height * 0.012, 1)), ArcadePalette.ladder, alpha: 0.9)
            rung += height * 0.2
        }
    }

    private static func drawFront(_ context: CGContext, _ size: CGSize) {
        let pip = ArcadeSprites.sprite(.pipStand)
        let pipHeight = size.height * 0.52
        let pipWidth = pipHeight * Double(pip.width) / Double(pip.height)
        draw(
            pip, context,
            CGRect(
                x: size.width * 0.3 - pipWidth / 2, y: size.height * 0.185, width: pipWidth,
                height: pipHeight))

        let can = ArcadeSprites.sprite(.canister)
        let canSize = size.height * 0.2
        draw(
            can, context,
            CGRect(
                x: size.width * 0.66, y: size.height * 0.555, width: canSize, height: canSize))
    }

    private static func draw(_ sprite: PixelSprite, _ context: CGContext, _ rect: CGRect) {
        guard sprite.width > 0, sprite.height > 0 else { return }
        let px = rect.width / Double(sprite.width)
        let py = rect.height / Double(sprite.height)
        for row in 0..<sprite.height {
            for column in 0..<sprite.width {
                let color = sprite.color(x: column, y: row)
                guard color.alpha > 0 else { continue }
                let cell = CGRect(
                    x: rect.minX + Double(column) * px,
                    y: rect.minY + rect.height - Double(row + 1) * py,
                    width: px + 0.6, height: py + 0.6)
                fill(context, cell, color)
            }
        }
    }

    static func write(_ image: CGImage, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw FrameGrabberError.writeFailed }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw FrameGrabberError.writeFailed }
    }
}
