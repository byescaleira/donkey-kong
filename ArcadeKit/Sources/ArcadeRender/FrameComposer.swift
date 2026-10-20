import ArcadeCore
import ArcadeScene
import Foundation
import Metal
import SpriteKit

public struct FrameReport: Hashable, Sendable {
    public var renderSize: Vector2Int
    public var outputSize: Vector2Int
    public var usedMetalFX: Bool
}

@MainActor
public final class FrameComposer {
    private let context: MetalContext
    private let upscaler: SpatialUpscaler
    private let renderer: SKRenderer

    private var sceneTexture: (any MTLTexture)?
    private var upscaledTexture: (any MTLTexture)?
    private var sceneTextureSize = Vector2Int(x: 0, y: 0)
    private var upscaledTextureSize = Vector2Int(x: 0, y: 0)

    public init(context: MetalContext) {
        self.context = context
        upscaler = SpatialUpscaler(device: context.device)
        renderer = SKRenderer(device: context.device)
        renderer.ignoresSiblingOrder = false
        renderer.shouldCullNonVisibleNodes = true
    }

    public var isMetalFXAvailable: Bool { upscaler.isAvailable }

    public func attach(scene: SKScene) {
        if renderer.scene !== scene { renderer.scene = scene }
    }

    public func compose(
        scene: SKScene, time: Double, viewport: VirtualViewport, settings: RenderSettings,
        drawableSize: Vector2Int, passDescriptor: MTLRenderPassDescriptor,
        pixelFormat: MTLPixelFormat, commandBuffer: any MTLCommandBuffer
    ) -> FrameReport? {
        guard !drawableSize.isEmpty else { return nil }
        attach(scene: scene)

        let outputSize = settings.outputSize(forDrawable: drawableSize)
        let wantsMetalFX = settings.upscaling.usesMetalFX && upscaler.isAvailable
        let renderSize = wantsMetalFX ? settings.renderSize(forOutput: outputSize) : outputSize
        guard let sceneTarget = sceneTexture(size: renderSize) else { return nil }

        let scenePass = MTLRenderPassDescriptor()
        scenePass.colorAttachments[0].texture = sceneTarget
        scenePass.colorAttachments[0].loadAction = .clear
        scenePass.colorAttachments[0].storeAction = .store
        scenePass.colorAttachments[0].clearColor = MTLClearColor(
            red: ArcadePalette.background.red, green: ArcadePalette.background.green,
            blue: ArcadePalette.background.blue, alpha: 1)

        renderer.update(atTime: time)
        renderer.render(
            withViewport: CGRect(x: 0, y: 0, width: renderSize.x, height: renderSize.y),
            commandBuffer: commandBuffer, renderPassDescriptor: scenePass)

        var source = sceneTarget
        var usedMetalFX = false
        if wantsMetalFX, renderSize != outputSize, let target = upscaledTexture(size: outputSize) {
            usedMetalFX = upscaler.encode(
                commandBuffer: commandBuffer, device: context.device, input: sceneTarget,
                output: target)
            if usedMetalFX { source = target }
        }

        encodePost(
            commandBuffer: commandBuffer, passDescriptor: passDescriptor, source: source,
            drawableSize: drawableSize, settings: settings, viewport: viewport,
            pixelFormat: pixelFormat)

        return FrameReport(
            renderSize: renderSize, outputSize: outputSize, usedMetalFX: usedMetalFX)
    }

    private func encodePost(
        commandBuffer: any MTLCommandBuffer, passDescriptor: MTLRenderPassDescriptor,
        source: any MTLTexture, drawableSize: Vector2Int, settings: RenderSettings,
        viewport: VirtualViewport, pixelFormat: MTLPixelFormat
    ) {
        guard let pipeline = try? context.postPipeline(pixelFormat: pixelFormat),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        let crt = settings.crt
        var uniforms = PostUniforms()
        uniforms.outputWidth = Float(drawableSize.x)
        uniforms.outputHeight = Float(drawableSize.y)
        uniforms.sourceWidth = Float(source.width)
        uniforms.sourceHeight = Float(source.height)
        uniforms.scanlineCount = Float(viewport.visibleSize.y)
        if crt.isEnabled {
            uniforms.scanlineStrength = Float(crt.scanlineStrength)
            uniforms.vignette = Float(crt.vignette)
            uniforms.aberration = Float(crt.aberration)
            uniforms.curvature = Float(crt.curvature)
            uniforms.bloom = Float(crt.bloom)
        }
        uniforms.sharpen = Float(crt.sharpen)

        encoder.label = "ArcadePostPass"
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(source, index: 0)
        encoder.setFragmentSamplerState(context.sampler, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<PostUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    private func sceneTexture(size: Vector2Int) -> (any MTLTexture)? {
        if sceneTextureSize == size, let sceneTexture { return sceneTexture }
        let texture = context.makeRenderTarget(
            size: size, format: GameRenderer.colorFormat, label: "ArcadeSceneTarget")
        sceneTexture = texture
        sceneTextureSize = texture == nil ? Vector2Int(x: 0, y: 0) : size
        return texture
    }

    private func upscaledTexture(size: Vector2Int) -> (any MTLTexture)? {
        if upscaledTextureSize == size, let upscaledTexture { return upscaledTexture }
        let texture = context.makeRenderTarget(
            size: size, format: GameRenderer.colorFormat, label: "ArcadeUpscaledTarget")
        upscaledTexture = texture
        upscaledTextureSize = texture == nil ? Vector2Int(x: 0, y: 0) : size
        return texture
    }
}
