import ArcadeCore
import ArcadeRender
import ArcadeScene
import SpriteKit
import CoreGraphics
import Foundation

@main
struct ArcadeShot {
    @MainActor
    static func main() {
        let arguments = Arguments(CommandLine.arguments)
        do {
            let context = try MetalContext()
            let grabber = FrameGrabber(context: context)
            let scene: SKScene
            if arguments.selfTest {
                let test = SKScene(size: CGSize(width: 224, height: 256))
                test.anchorPoint = .zero
                test.scaleMode = .fill
                test.backgroundColor = .blue
                let box = SKSpriteNode(color: .red, size: CGSize(width: 120, height: 120))
                box.position = CGPoint(x: 112, y: 128)
                test.addChild(box)
                scene = test
            } else {
                scene = SpireScene(size: VirtualViewport.coreSize.cgSize)
            }

            var world = GameWorld(seed: arguments.seed)
            world.startGame()
            let ticks = Int(arguments.seconds / GameClock.tickDuration)
            for _ in 0..<ticks {
                world.step(dt: GameClock.tickDuration, input: arguments.input)
            }
            _ = world.drainEvents()

            let viewport = VirtualViewport(
                pointSize: Vector2(x: Double(arguments.size.x), y: Double(arguments.size.y)))
            if let spire = scene as? SpireScene {
                spire.apply(viewport: viewport)
                spire.sync(world: world)
            }

            let settings = RenderSettings(
                upscaling: arguments.upscaling, crt: arguments.crt,
                maxOutputHeight: arguments.maxHeight)
            let result = try grabber.grab(
                scene: scene, time: arguments.seconds, size: arguments.size, settings: settings)
            try grabber.write(image: result.image, to: arguments.output)

            print("wrote \(arguments.output.path)")
            print("  drawable  \(arguments.size.x)×\(arguments.size.y)")
            print("  scene     \(result.report.renderSize.x)×\(result.report.renderSize.y)")
            print("  output    \(result.report.outputSize.x)×\(result.report.outputSize.y)")
            print("  metalfx   \(result.report.usedMetalFX ? "active" : "bypassed")")
            print("  available \(grabber.isMetalFXAvailable)")
            print("  phase     \(world.phase)")
            print("  hazards   \(world.hazards.count)")
            printStats(result.image)
        } catch {
            FileHandle.standardError.write(Data("arcadeshot failed: \(error)\n".utf8))
            exit(1)
        }
    }
}

@MainActor
private func printStats(_ image: CGImage) {
    guard let data = image.dataProvider?.data as Data? else { return }
    var maximum: UInt8 = 0
    var total = 0
    var lit = 0
    let count = data.count
    for offset in stride(from: 0, to: count, by: 4) {
        let blue = data[offset]
        let green = data[offset + 1]
        let red = data[offset + 2]
        let peak = max(red, max(green, blue))
        maximum = max(maximum, peak)
        total += Int(peak)
        if peak > 24 { lit += 1 }
    }
    let pixels = max(count / 4, 1)
    let mean = Double(total) / Double(pixels)
    let litShare = Double(lit) / Double(pixels) * 100
    print("  pixels    max=\(maximum) mean=\(String(format: "%.2f", mean)) lit=\(String(format: "%.2f", litShare))%")
}

private struct Arguments {
    var size = Vector2Int(x: 1179, y: 2556)
    var seconds: Double = 6
    var seed: UInt64 = 2024
    var upscaling: UpscalingMode = .quality
    var crt = CRTSettings()
    var maxHeight = RenderSettings.fourKHeight
    var output = URL(fileURLWithPath: "frame.png")
    var input = InputState(horizontal: 1)
    var selfTest = false

    init(_ arguments: [String]) {
        var index = 1
        while index < arguments.count {
            let key = arguments[index]
            let value = index + 1 < arguments.count ? arguments[index + 1] : ""
            switch key {
            case "--size":
                let parts = value.split(separator: "x").compactMap { Int($0) }
                if parts.count == 2 { size = Vector2Int(x: parts[0], y: parts[1]) }
                index += 2
            case "--seconds":
                seconds = Double(value) ?? seconds
                index += 2
            case "--seed":
                seed = UInt64(value) ?? seed
                index += 2
            case "--upscaling":
                upscaling = UpscalingMode(rawValue: value) ?? upscaling
                index += 2
            case "--max-height":
                maxHeight = Int(value) ?? maxHeight
                index += 2
            case "--out":
                output = URL(fileURLWithPath: value)
                index += 2
            case "--no-crt":
                crt = .off
                index += 1
            case "--selftest":
                selfTest = true
                index += 1
            case "--idle":
                input = .neutral
                index += 1
            default:
                index += 1
            }
        }
    }
}
