import ArcadeCore
import SpriteKit

public final class LadderNode: SKNode {
    public init(ladder: Ladder) {
        super.init()
        position = CGPoint(x: ladder.centerX, y: ladder.bottomY)
        zPosition = 2

        let height = ladder.usableTopY - ladder.bottomY
        guard height > 0 else { return }
        let color = ladder.isBroken ? ArcadePalette.ladderBroken : ArcadePalette.ladder

        for side in [-1.0, 1.0] {
            let rail = SKSpriteNode(color: color.skColor, size: CGSize(width: 2, height: height))
            rail.anchorPoint = CGPoint(x: 0.5, y: 0)
            rail.position = CGPoint(x: side * (Ladder.width / 2 - 1), y: 0)
            addChild(rail)
        }

        let rungSpacing: Double = 7
        let rungs = max(Int(height / rungSpacing), 1)
        for index in 0...rungs {
            let rung = SKSpriteNode(
                color: color.skColor, size: CGSize(width: Ladder.width - 2, height: 2))
            rung.position = CGPoint(x: 0, y: Double(index) * (height / Double(rungs)))
            addChild(rung)
        }

        if ladder.isBroken {
            let gap = SKSpriteNode(
                color: ArcadePalette.rust.skColor, size: CGSize(width: Ladder.width, height: 2))
            gap.position = CGPoint(x: 0, y: height)
            gap.alpha = 0.8
            addChild(gap)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("LadderNode is created in code")
    }
}
