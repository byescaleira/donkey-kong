import Testing

@testable import ArcadeRender

@Suite("Render resolution policy")
struct RenderSettingsTests {
    @Test("a 1080p display renders at its own resolution, uncapped")
    func belowCapIsUntouched() {
        let settings = RenderSettings(upscaling: .off)
        let output = settings.outputSize(forDrawable: Vector2Int(x: 1920, y: 1080))
        #expect(output == Vector2Int(x: 1920, y: 1080))
    }

    @Test("a 5K display is capped to 4K while keeping its aspect ratio")
    func aboveCapIsClampedToFourK() {
        let settings = RenderSettings()
        let output = settings.outputSize(forDrawable: Vector2Int(x: 5120, y: 2880))
        #expect(output.y == RenderSettings.fourKHeight)
        let sourceAspect = 5120.0 / 2880.0
        let cappedAspect = Double(output.x) / Double(output.y)
        #expect(abs(sourceAspect - cappedAspect) < 0.01)
    }

    @Test("quality upscaling renders below the output resolution")
    func qualityRendersLower() {
        let settings = RenderSettings(upscaling: .quality)
        let output = Vector2Int(x: 3840, y: 2160)
        let render = settings.renderSize(forOutput: output)
        #expect(render.y < output.y)
        #expect(render.y > output.y / 2)
    }

    @Test("performance upscaling renders at half resolution")
    func performanceRendersHalf() {
        let settings = RenderSettings(upscaling: .performance)
        let render = settings.renderSize(forOutput: Vector2Int(x: 3840, y: 2160))
        #expect(render == Vector2Int(x: 1920, y: 1080))
    }

    @Test("native mode renders exactly at the output resolution")
    func nativeMatchesOutput() {
        let settings = RenderSettings(upscaling: .off)
        let output = Vector2Int(x: 2560, y: 1440)
        #expect(settings.renderSize(forOutput: output) == output)
        #expect(!settings.upscaling.usesMetalFX)
    }

    @Test("every upscaling mode keeps the render target at least one pixel")
    func renderSizeNeverCollapses() {
        for mode in UpscalingMode.allCases {
            let settings = RenderSettings(upscaling: mode)
            let render = settings.renderSize(forOutput: Vector2Int(x: 1, y: 1))
            #expect(render.x >= 1)
            #expect(render.y >= 1)
            #expect(!render.isEmpty)
        }
    }

    @Test("a zero drawable is reported as empty instead of crashing")
    func zeroDrawableIsEmpty() {
        #expect(Vector2Int(x: 0, y: 0).isEmpty)
        let settings = RenderSettings()
        #expect(settings.outputSize(forDrawable: Vector2Int(x: 0, y: 0)).isEmpty)
    }

    @Test("the default target is a locked 60 fps")
    func defaultsToSixtyFps() {
        #expect(RenderSettings().framesPerSecond == 60)
    }

    @Test("turning the cabinet look off zeroes every effect")
    func crtOffIsNeutral() {
        let off = CRTSettings.off
        #expect(!off.isEnabled)
        #expect(off.scanlineStrength == 0)
        #expect(off.bloom == 0)
        #expect(off.curvature == 0)
    }
}

@Suite("Shader library")
struct ShaderLibraryTests {
    @Test("the shader source compiles and exposes the post-process functions")
    @MainActor
    func shaderCompiles() throws {
        let context = try MetalContext()
        #expect(context.library.makeFunction(name: "fullscreen_vertex") != nil)
        #expect(context.library.makeFunction(name: "crt_fragment") != nil)
    }

    @Test("the post-process pipeline builds for the drawable format")
    @MainActor
    func pipelineBuilds() throws {
        let context = try MetalContext()
        _ = try context.postPipeline(pixelFormat: GameRenderer.colorFormat)
    }
}
