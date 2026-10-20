import Foundation
import Metal
import MetalKit

public struct PostUniforms {
    public var outputWidth: Float = 0
    public var outputHeight: Float = 0
    public var sourceWidth: Float = 0
    public var sourceHeight: Float = 0
    public var scanlineStrength: Float = 0
    public var scanlineCount: Float = 0
    public var vignette: Float = 0
    public var aberration: Float = 0
    public var curvature: Float = 0
    public var bloom: Float = 0
    public var sharpen: Float = 0
    public var padding: Float = 0
}

public enum MetalContextError: Error {
    case noDevice
    case noQueue
    case noFunction(String)
}

public final class MetalContext {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let library: MTLLibrary
    public let sampler: MTLSamplerState

    private var pipelines: [UInt: MTLRenderPipelineState] = [:]

    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw MetalContextError.noDevice }
        guard let queue = device.makeCommandQueue() else { throw MetalContextError.noQueue }
        self.device = device
        commandQueue = queue
        library = try device.makeLibrary(source: ShaderSource.metal, options: nil)

        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        guard let sampler = device.makeSamplerState(descriptor: descriptor) else {
            throw MetalContextError.noFunction("sampler")
        }
        self.sampler = sampler
    }

    public func postPipeline(pixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineState {
        if let cached = pipelines[pixelFormat.rawValue] { return cached }
        guard let vertexFunction = library.makeFunction(name: "fullscreen_vertex") else {
            throw MetalContextError.noFunction("fullscreen_vertex")
        }
        guard let fragmentFunction = library.makeFunction(name: "crt_fragment") else {
            throw MetalContextError.noFunction("crt_fragment")
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "ArcadePostProcess"
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        pipelines[pixelFormat.rawValue] = pipeline
        return pipeline
    }

    public func makeReadableTarget(size: Vector2Int, format: MTLPixelFormat, label: String)
        -> (any MTLTexture)?
    {
        guard !size.isEmpty else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: size.x, height: size.y, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = label
        return texture
    }

    public func makeRenderTarget(size: Vector2Int, format: MTLPixelFormat, label: String)
        -> MTLTexture?
    {
        guard !size.isEmpty else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: size.x, height: size.y, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.label = label
        return texture
    }
}
