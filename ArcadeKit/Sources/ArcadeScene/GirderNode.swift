import ArcadeCore
import SpriteKit

public final class GirderNode: SKNode {
    public init(girder: Girder) {
        super.init()
        let delta = girder.end - girder.start
        let length = delta.length
        guard length > 0 else { return }
        let angle = atan2(delta.y, delta.x)

        position = CGPoint(
            x: (girder.start.x + girder.end.x) / 2, y: (girder.start.y + girder.end.y) / 2)
        zRotation = CGFloat(angle)
        zPosition = 5

        let beam = SKSpriteNode(
            color: ArcadePalette.girder.skColor,
            size: CGSize(width: length, height: girder.thickness))
        beam.position = CGPoint(x: 0, y: -girder.thickness / 2)
        addChild(beam)

        let shade = SKSpriteNode(
            color: ArcadePalette.girderShade.skColor, size: CGSize(width: length, height: 2))
        shade.position = CGPoint(x: 0, y: -girder.thickness + 1)
        addChild(shade)

        let rivetSpacing: Double = 10
        let count = max(Int(length / rivetSpacing), 1)
        for index in 0...count {
            let rivet = SKSpriteNode(
                color: ArcadePalette.girderShade.skColor, size: CGSize(width: 2, height: 2))
            rivet.position = CGPoint(
                x: -length / 2 + Double(index) * (length / Double(count)),
                y: -girder.thickness / 2)
            addChild(rivet)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("GirderNode is created in code")
    }
}
