import ArcadeCore
import ArcadeRender
import MetalKit
import SwiftUI

public struct MetalGameView: View {
    private let session: GameSession

    public init(session: GameSession) {
        self.session = session
    }

    public var body: some View {
        MetalGameSurface(session: session)
            .ignoresSafeArea()
    }
}

@MainActor
final class MetalGameCoordinator {
    private(set) var renderer: GameRenderer?
    private var context: MetalContext?

    func makeView(session: GameSession) -> MTKView {
        let view = MTKView()
        do {
            let context = try MetalContext()
            let renderer = GameRenderer(context: context, driver: session)
            renderer.configure(view: view)
            self.context = context
            self.renderer = renderer
        } catch {
            view.isPaused = true
        }
        return view
    }

    func update(view: MTKView, session: GameSession) {
        view.preferredFramesPerSecond = session.settings.framesPerSecond
    }
}

#if canImport(UIKit)
    struct MetalGameSurface: UIViewRepresentable {
        let session: GameSession

        func makeCoordinator() -> MetalGameCoordinator {
            MetalGameCoordinator()
        }

        func makeUIView(context: Context) -> MTKView {
            context.coordinator.makeView(session: session)
        }

        func updateUIView(_ view: MTKView, context: Context) {
            context.coordinator.update(view: view, session: session)
        }
    }
#else
    struct MetalGameSurface: NSViewRepresentable {
        let session: GameSession

        func makeCoordinator() -> MetalGameCoordinator {
            MetalGameCoordinator()
        }

        func makeNSView(context: Context) -> MTKView {
            context.coordinator.makeView(session: session)
        }

        func updateNSView(_ view: MTKView, context: Context) {
            context.coordinator.update(view: view, session: session)
        }
    }
#endif
