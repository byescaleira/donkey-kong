import ArcadeCore
import Foundation

#if os(iOS)
    import UIKit
#endif

@MainActor
public final class HapticsDirector {
    public var isEnabled = true

    #if os(iOS)
        private let impact = UIImpactFeedbackGenerator(style: .medium)
        private let sharp = UIImpactFeedbackGenerator(style: .rigid)
        private let notice = UINotificationFeedbackGenerator()
    #endif

    public init() {}

    public func prepare() {
        #if os(iOS)
            guard isEnabled else { return }
            impact.prepare()
            sharp.prepare()
            notice.prepare()
        #endif
    }

    public func handle(_ events: [GameEvent]) {
        guard isEnabled else { return }
        #if os(iOS)
            for event in events {
                switch event {
                case .jumped: impact.impactOccurred(intensity: 0.4)
                case .smashedHazard: sharp.impactOccurred(intensity: 0.9)
                case .overclockCollected: notice.notificationOccurred(.success)
                case .clearedHazard: impact.impactOccurred(intensity: 0.3)
                case .extraLife: notice.notificationOccurred(.success)
                case .stageCleared: notice.notificationOccurred(.success)
                case .climberDied, .gameOver: notice.notificationOccurred(.error)
                case .bonusExpiring: notice.notificationOccurred(.warning)
                case .scored, .hazardSpawned, .stageStarted: break
                }
            }
        #endif
    }
}
