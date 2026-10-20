import ArcadeCore
import GameController

@MainActor
public final class GamepadInput {
    public private(set) var controllerName: String?

    private var mapping = GamepadMapping()
    private var configured: ObjectIdentifier?

    public init() {
        GCController.startWirelessControllerDiscovery()
    }

    public var isConnected: Bool { controllerName != nil }

    @discardableResult
    public func poll(into buffer: InputBuffer) -> Bool {
        guard let controller = GCController.current ?? GCController.controllers().first else {
            controllerName = nil
            mapping.disconnect()
            return false
        }
        controllerName = controller.vendorName ?? "Controller"

        var horizontal = 0.0
        var vertical = 0.0
        var jump = false

        if let pad = controller.extendedGamepad {
            horizontal = Double(pad.leftThumbstick.xAxis.value) + Double(pad.dpad.xAxis.value)
            vertical = Double(pad.leftThumbstick.yAxis.value) + Double(pad.dpad.yAxis.value)
            jump =
                pad.buttonA.isPressed || pad.buttonB.isPressed
                || pad.rightShoulder.isPressed || pad.leftShoulder.isPressed
        } else if let micro = controller.microGamepad {
            configure(micro, for: controller)
            horizontal = Double(micro.dpad.xAxis.value)
            vertical = Double(micro.dpad.yAxis.value)
            jump = micro.buttonA.isPressed || micro.buttonX.isPressed
        } else {
            return false
        }

        buffer.apply(
            mapping.apply(
                GamepadReading(horizontal: horizontal, vertical: vertical, isJumpPressed: jump)))
        return true
    }

    private func configure(_ micro: GCMicroGamepad, for controller: GCController) {
        let identifier = ObjectIdentifier(controller)
        guard configured != identifier else { return }
        configured = identifier
        micro.reportsAbsoluteDpadValues = true
        micro.allowsRotation = false
    }
}
