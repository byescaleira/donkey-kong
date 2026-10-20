import ArcadeUI
import SwiftUI

@main
struct ScrapSpireApp: App {
    @State private var session = GameSession()

    var body: some Scene {
        WindowGroup {
            GameShellView(session: session)
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 760, height: 900)
            .windowResizability(.contentSize)
        #endif
    }
}
