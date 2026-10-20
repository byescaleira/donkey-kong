import ArcadeCore
import SwiftUI

struct KeyboardControls: ViewModifier {
    let input: InputBuffer
    let onPause: () -> Void

    @State private var pressed: Set<GameKey> = []

    func body(content: Content) -> some View {
        #if os(tvOS)
            content
        #else
            keyboardAware(content)
        #endif
    }

    #if !os(tvOS)
    private func keyboardAware(_ content: Content) -> some View {
        content
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(phases: [.down, .repeat]) { press in
                handle(press, isDown: true)
            }
            .onKeyPress(phases: .up) { press in
                handle(press, isDown: false)
            }
    }
    #endif

    private func handle(_ press: KeyPress, isDown: Bool) -> KeyPress.Result {
        guard let key = GameKey(press: press) else { return .ignored }
        if isDown {
            if key == .pause {
                onPause()
                return .handled
            }
            pressed.insert(key)
            if key == .jump { input.pressJump() }
        } else {
            pressed.remove(key)
            if key == .jump { input.releaseJump() }
        }
        apply()
        return .handled
    }

    private func apply() {
        var horizontal: Double = 0
        var vertical: Double = 0
        if pressed.contains(.left) { horizontal -= 1 }
        if pressed.contains(.right) { horizontal += 1 }
        if pressed.contains(.up) { vertical += 1 }
        if pressed.contains(.down) { vertical -= 1 }
        input.setAxes(horizontal: horizontal, vertical: vertical)
        if pressed.contains(.start) { input.pressStart() }
    }
}

private enum GameKey: Hashable {
    case left
    case right
    case up
    case down
    case jump
    case start
    case pause

    init?(press: KeyPress) {
        switch press.key {
        case .leftArrow: self = .left
        case .rightArrow: self = .right
        case .upArrow: self = .up
        case .downArrow: self = .down
        case .space: self = .jump
        case .return: self = .start
        case .escape: self = .pause
        default:
            switch press.characters.lowercased() {
            case "a": self = .left
            case "d": self = .right
            case "w": self = .up
            case "s": self = .down
            case "p": self = .pause
            default: return nil
            }
        }
    }
}

extension View {
    func keyboardControls(input: InputBuffer, onPause: @escaping () -> Void) -> some View {
        modifier(KeyboardControls(input: input, onPause: onPause))
    }
}
