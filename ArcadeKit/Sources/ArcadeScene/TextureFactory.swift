import ArcadeCore
import CoreGraphics
import SpriteKit

public final class TextureFactory: @unchecked Sendable {
    public static let shared = TextureFactory()

    private var cache: [String: SKTexture] = [:]
    private let lock = NSLock()

    private init() {}

    public func texture(_ name: SpriteName, flipped: Bool = false) -> SKTexture {
        let key = "\(name.rawValue)\(flipped ? ".flipped" : "")"
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[key] { return cached }
        var sprite = ArcadeSprites.sprite(name)
        if flipped { sprite = sprite.flippedHorizontally() }
        let texture = Self.makeTexture(from: sprite)
        cache[key] = texture
        return texture
    }

    public func verticalGradient(from start: PixelColor, to end: PixelColor, height: Int = 64)
        -> SKTexture
    {
        let key = "gradient-\(start)-\(end)-\(height)"
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[key] { return cached }

        var bytes = [UInt8](repeating: 0, count: height * 4)
        for row in 0..<height {
            let t = height <= 1 ? 0 : Double(row) / Double(height - 1)
            let red = start.red + (end.red - start.red) * t
            let green = start.green + (end.green - start.green) * t
            let blue = start.blue + (end.blue - start.blue) * t
            let offset = row * 4
            bytes[offset] = UInt8((red * 255).rounded())
            bytes[offset + 1] = UInt8((green * 255).rounded())
            bytes[offset + 2] = UInt8((blue * 255).rounded())
            bytes[offset + 3] = 255
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let image = bytes.withUnsafeMutableBytes { buffer -> CGImage? in
            guard let base = buffer.baseAddress,
                let context = CGContext(
                    data: base, width: 1, height: height, bitsPerComponent: 8, bytesPerRow: 4,
                    space: colorSpace, bitmapInfo: info.rawValue)
            else { return nil }
            return context.makeImage()
        }
        guard let image else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        cache[key] = texture
        return texture
    }

    static func makeTexture(from sprite: PixelSprite) -> SKTexture {
        guard !sprite.isEmpty else { return SKTexture() }
        var bytes = sprite.rgbaBytes()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let image = bytes.withUnsafeMutableBytes { buffer -> CGImage? in
            guard let base = buffer.baseAddress,
                let context = CGContext(
                    data: base, width: sprite.width, height: sprite.height,
                    bitsPerComponent: 8, bytesPerRow: sprite.width * 4, space: colorSpace,
                    bitmapInfo: info.rawValue)
            else { return nil }
            return context.makeImage()
        }
        guard let image else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .nearest
        return texture
    }
}

extension PixelColor {
    public var skColor: SKColor {
        SKColor(
            red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}

extension Vector2 {
    public var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    public var cgSize: CGSize { CGSize(width: x, height: y) }
}
