import ArcadeCore
import CoreGraphics
import Foundation
import ImageIO
import Metal
import SpriteKit
import UniformTypeIdentifiers

public enum FrameGrabberError: Error {
    case noTarget
    case noCommandBuffer
    case composeFailed
    case noImage
    case writeFailed
}

@MainActor
public final class FrameGrabber {
    private let context: MetalContext
    private let composer: FrameComposer

    public init(context: MetalContext) {
        self.context = context
        composer = FrameComposer(context: context)
    }

    public var isMetalFXAvailable: Bool { composer.isMetalFXAvailable }

    public func grab(
        scene: SKScene, time: Double, size: Vector2Int, settings: RenderSettings,
        safeArea: EdgeInsets2 = .zero
    ) throws -> (image: CGImage, report: FrameReport) {
        guard
            let target = context.makeReadableTarget(
                size: size, format: GameRenderer.colorFormat, label: "ArcadeGrabTarget")
        else { throw FrameGrabberError.noTarget }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = target
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0, green: 0, blue: 0, alpha: 1)

        guard let commandBuffer = context.commandQueue.makeCommandBuffer() else {
            throw FrameGrabberError.noCommandBuffer
        }
        commandBuffer.label = "ArcadeGrab"

        let viewport = VirtualViewport(
            pointSize: Vector2(x: Double(size.x), y: Double(size.y)), safeArea: safeArea)
        guard
            let report = composer.compose(
                scene: scene, time: time, viewport: viewport, settings: settings,
                drawableSize: size, passDescriptor: passDescriptor,
                pixelFormat: GameRenderer.colorFormat, commandBuffer: commandBuffer)
        else { throw FrameGrabberError.composeFailed }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard let image = Self.makeImage(from: target) else { throw FrameGrabberError.noImage }
        return (image, report)
    }

    public func write(image: CGImage, to url: URL) throws {
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw FrameGrabberError.writeFailed }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw FrameGrabberError.writeFailed }
    }

    private static func makeImage(from texture: any MTLTexture) -> CGImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        bytes.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            texture.getBytes(
                base, bytesPerRow: bytesPerRow,
                from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        }

        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
            .union(.byteOrder32Little)
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info,
            provider: provider, decode: nil, shouldInterpolate: false,
            intent: .defaultIntent)
    }
}
