import ArcadeCore
import SwiftUI

struct TouchControlsView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        HStack(alignment: .bottom) {
            DirectionPad(input: session.input)
            Spacer()
            JumpButton(input: session.input)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

private struct DirectionPad: View {
    let input: InputBuffer
    @State private var offset: CGSize = .zero

    private let radius: CGFloat = 58

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
            Circle()
                .fill(ArcadePalette.shell.color.opacity(0.75))
                .frame(width: 44, height: 44)
                .offset(offset)
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(.circle)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let limit = radius - 22
                    let length = (value.translation.width * value.translation.width
                        + value.translation.height * value.translation.height).squareRoot()
                    let clamp = length > limit && length > 0 ? limit / length : 1
                    offset = CGSize(
                        width: value.translation.width * clamp,
                        height: value.translation.height * clamp)
                    input.setAxes(
                        horizontal: Double(offset.width / limit),
                        vertical: Double(-offset.height / limit))
                }
                .onEnded { _ in
                    offset = .zero
                    input.setAxes(horizontal: 0, vertical: 0)
                }
        )
        .animation(.interactiveSpring(duration: 0.15), value: offset)
    }
}

private struct JumpButton: View {
    let input: InputBuffer
    @State private var isPressed = false

    var body: some View {
        Circle()
            .fill(isPressed ? ArcadePalette.accent.color : ArcadePalette.accent.color.opacity(0.78))
            .overlay(
                Image(systemName: "arrow.up")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.black.opacity(0.75))
            )
            .frame(width: 84, height: 84)
            .scaleEffect(isPressed ? 0.92 : 1)
            .contentShape(.circle)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        input.pressJump()
                    }
                    .onEnded { _ in
                        isPressed = false
                        input.releaseJump()
                    }
            )
            .animation(.interactiveSpring(duration: 0.12), value: isPressed)
    }
}
