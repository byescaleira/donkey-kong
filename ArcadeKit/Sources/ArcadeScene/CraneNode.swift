import ArcadeCore
import SpriteKit

public final class CraneNode: SKNode {
    private let claw = SKNode()
    private let jib = SKNode()
    private var lamp: SKSpriteNode?

    public override init() {
        super.init()

        let mast = SKSpriteNode(
            color: ArcadePalette.metal.skColor, size: CGSize(width: 8, height: 30))
        mast.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(mast)

        for index in 0..<4 {
            let brace = SKSpriteNode(
                color: ArcadePalette.outline.skColor, size: CGSize(width: 8, height: 1))
            brace.position = CGPoint(x: 0, y: 6 + Double(index) * 7)
            addChild(brace)
        }

        let arm = SKSpriteNode(
            color: ArcadePalette.metal.skColor, size: CGSize(width: 40, height: 6))
        arm.position = CGPoint(x: 12, y: 0)
        jib.position = CGPoint(x: 0, y: 30)
        jib.addChild(arm)

        let counterweight = SKSpriteNode(
            color: ArcadePalette.rust.skColor, size: CGSize(width: 10, height: 12))
        counterweight.position = CGPoint(x: -12, y: -2)
        jib.addChild(counterweight)

        let housing = SKSpriteNode(
            color: ArcadePalette.girder.skColor, size: CGSize(width: 16, height: 14))
        housing.position = CGPoint(x: 0, y: 4)
        jib.addChild(housing)

        let signal = SKSpriteNode(
            color: ArcadePalette.signal.skColor, size: CGSize(width: 4, height: 4))
        signal.position = CGPoint(x: 0, y: 12)
        jib.addChild(signal)
        lamp = signal

        let cable = SKSpriteNode(
            color: ArcadePalette.outline.skColor, size: CGSize(width: 1, height: 10))
        cable.anchorPoint = CGPoint(x: 0.5, y: 1)
        claw.addChild(cable)

        for side in [-1.0, 1.0] {
            let finger = SKSpriteNode(
                color: ArcadePalette.metal.skColor, size: CGSize(width: 2, height: 7))
            finger.anchorPoint = CGPoint(x: 0.5, y: 1)
            finger.position = CGPoint(x: side * 3, y: -10)
            finger.zRotation = CGFloat(side * 0.3)
            claw.addChild(finger)
        }

        claw.position = CGPoint(x: 30, y: 0)
        jib.addChild(claw)
        addChild(jib)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("CraneNode is created in code")
    }

    public func update(time: Double, isActive: Bool) {
        guard isActive else { return }
        jib.zRotation = CGFloat(sin(time * 0.8) * 0.05)
        claw.position = CGPoint(x: 30, y: sin(time * 2.1) * 3)
        lamp?.alpha = sin(time * 6) > 0 ? 1 : 0.25
    }
}
