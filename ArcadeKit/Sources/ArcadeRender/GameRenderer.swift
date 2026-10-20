import ArcadeCore
import ArcadeScene
import Foundation
import Metal
import MetalKit
import SpriteKit

@MainActor
public protocol FrameDriver: AnyObject {
    var scene: SKScene { get }
    var renderSettings: RenderSettings { get }
    func advance(to time: Double, viewport: VirtualViewport)
    func reportFrame(renderSize: Vector2Int, outputSize: Vector2Int, usedMetalFX: Bool)
}

@MainActor
public final class GameRenderer: NSObject {
    public static let colorFormat: MTLPixelFormat = .bgra8Unorm

    private let context: MetalContext
    private let composer: FrameComposer
    private weak var driver: (any FrameDriver)?
    private var startTime: CFTimeInterval?

    public init(context: MetalContext, driver: any FrameDriver) {
        self.context = context
        composer = FrameComposer(context: context)
        self.driver = driver
        super.init()
        composer.attach(scene: driver.scene)
    }

    public var isMetalFXAvailable: Bool { composer.isMetalFXAvailable }

    public func configure(view: MTKView) {
        view.device = context.device
        view.colorPixelFormat = Self.colorFormat
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = driver?.renderSettings.framesPerSecond ?? 60
        view.delegate = self
    }

    fileprivate func renderFrame(in view: MTKView) {
        guard let driver,
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor
        else { return }

        let drawableSize = Vector2Int(
            x: Int(view.drawableSize.width.rounded()), y: Int(view.drawableSize.height.rounded()))
        guard !drawableSize.isEmpty else { return }

        let viewport = VirtualViewport(
            pointSize: Vector2(x: view.bounds.width, y: view.bounds.height),
            safeArea: view.arcadeSafeArea)
        let time = elapsed()
        driver.advance(to: time, viewport: viewport)

        guard let commandBuffer = context.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "ArcadeFrame"

        let report = composer.compose(
            scene: driver.scene, time: time, viewport: viewport,
            settings: driver.renderSettings, drawableSize: drawableSize,
            passDescriptor: passDescriptor, pixelFormat: view.colorPixelFormat,
            commandBuffer: commandBuffer)

        commandBuffer.present(drawable)
        commandBuffer.commit()

        if let report {
            driver.reportFrame(
                renderSize: report.renderSize, outputSize: report.outputSize,
                usedMetalFX: report.usedMetalFX)
        }
    }

    private func elapsed() -> CFTimeInterval {
        let now = CACurrentMediaTime()
        if let startTime { return now - startTime }
        startTime = now
        return 0
    }
}

extension GameRenderer: MTKViewDelegate {
    public nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated { renderFrame(in: view) }
    }

    public nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension MTKView {
    var arcadeSafeArea: EdgeInsets2 {
        #if canImport(UIKit)
            let insets = safeAreaInsets
            return EdgeInsets2(
                top: insets.top, leading: insets.left, bottom: insets.bottom,
                trailing: insets.right)
        #else
            return .zero
        #endif
    }
}
